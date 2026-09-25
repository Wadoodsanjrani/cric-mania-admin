import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cricket_api_service.dart';
import 'update_match_screen.dart';

class ApiTrackerScreen extends StatefulWidget {
  const ApiTrackerScreen({super.key});

  @override
  State<ApiTrackerScreen> createState() => _ApiTrackerScreenState();
}

class _ApiTrackerScreenState extends State<ApiTrackerScreen> {
  final CricketApiService _apiService = CricketApiService();
  List<Map<String, dynamic>> _liveMatches = [];
  bool _loading = false;
  String _errorMsg = '';

  // ─── TRACKED MATCHES ───
  List<String> _trackedMatchIds = [];

  @override
  void initState() {
    super.initState();
    _loadTrackedMatches();
  }

  // ─── LOAD TRACKED FROM FIREBASE ───
  Future<void> _loadTrackedMatches() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('apiTracked', isEqualTo: true)
        .get();
    setState(() {
      _trackedMatchIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // ─── FETCH LIVE MATCHES FROM API ───
  Future<void> _fetchLiveMatches() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    try {
      final matches = await _apiService.getCurrentMatches();
      setState(() {
        _liveMatches = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _loading = false;
      });
    }
  }

  // ─── TRACK MATCH ───
  Future<void> _trackMatch(String matchId, String matchName) async {
    setState(() => _loading = true);

    try {
      final success = await _apiService.syncMatchToFirebase(matchId);
      if (success) {
        setState(() {
          _trackedMatchIds.add(matchId);
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$matchName track ho gaya!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match track nahi hua'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ─── UNTRACK MATCH ───
  Future<void> _untrackMatch(String matchId) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update({'apiTracked': false});
    setState(() => _trackedMatchIds.remove(matchId));
  }

  // ─── MANUAL SYNC ───
  Future<void> _syncMatch(String matchId) async {
    setState(() => _loading = true);
    await _apiService.syncMatchToFirebase(matchId);
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Match synced!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ─── ADD BY MATCH ID ───
  void _addByMatchId() {
    final idCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Match by ID'),
        content: TextField(
          controller: idCtrl,
          decoration: const InputDecoration(
            labelText: 'Match ID (e.g. abc123)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1931),
            ),
            onPressed: () async {
              if (idCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _trackMatch(idCtrl.text.trim(), 'Match ID: ${idCtrl.text.trim()}');
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text(
          'API Match Tracker',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── TAREEQA 3: MANUAL MATCH ID ───
          Card(
            color: Colors.blue[50],
            child: ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.blue),
              title: const Text(
                'Add Match by ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('CricAPI se Match ID daalein'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _addByMatchId,
            ),
          ),

          const SizedBox(height: 12),

          // ─── TAREEQA 1 & 2: LIVE MATCHES ───
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1931),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Live Matches',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _loading ? null : _fetchLiveMatches,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Auto Track All',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_liveMatches.isEmpty) {
                            await _fetchLiveMatches();
                          }
                          for (var match in _liveMatches) {
                            final id = match['id']?.toString() ?? '';
                            if (id.isNotEmpty && !_trackedMatchIds.contains(id)) {
                              await _apiService.syncMatchToFirebase(id);
                              _trackedMatchIds.add(id);
                            }
                          }
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All live matches tracked!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),

          if (_errorMsg.isNotEmpty)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _errorMsg,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),

          // ─── LIVE MATCHES LIST ───
          if (_liveMatches.isNotEmpty) ...[
            const Text(
              'LIVE MATCHES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1931),
              ),
            ),
            const SizedBox(height: 8),
            ..._liveMatches.map((match) {
              final id = match['id']?.toString() ?? '';
              final name = match['name']?.toString() ?? 'Unknown Match';
              final status = match['status']?.toString() ?? 'LIVE';
              final isTracked = _trackedMatchIds.contains(id);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $id',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTracked
                                    ? Colors.grey
                                    : Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: Icon(
                                isTracked ? Icons.check : Icons.track_changes,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                isTracked ? 'TRACKED' : 'TRACK',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: isTracked
                                  ? null
                                  : () => _trackMatch(id, name),
                            ),
                          ),
                          if (isTracked) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(
                                  Icons.sync,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'SYNC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => _syncMatch(id),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 24),

          // ─── TRACKED MATCHES ───
          if (_trackedMatchIds.isNotEmpty) ...[
            const Text(
              'TRACKED MATCHES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1931),
              ),
            ),
            const SizedBox(height: 8),
            ..._trackedMatchIds.map((id) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Match ID: $id'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync, color: Colors.blue),
                        onPressed: () => _syncMatch(id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _untrackMatch(id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}