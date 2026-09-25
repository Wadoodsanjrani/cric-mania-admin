import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cricket_api_service.dart';

class ApiTrackerScreen extends StatefulWidget {
  const ApiTrackerScreen({super.key});

  @override
  State<ApiTrackerScreen> createState() => _ApiTrackerScreenState();
}

class _ApiTrackerScreenState extends State<ApiTrackerScreen> {
  final CricketApiService _apiService = CricketApiService();
  List<Map<String, dynamic>> _matches = [];
  bool _loading = false;
  String _errorMsg = '';
  String _filter = 'all'; // 'live' ya 'all'

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

  // ─── FETCH LIVE MATCHES ───
  Future<void> _fetchLiveMatches() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
      _filter = 'live';
    });

    try {
      final matches = await _apiService.getCurrentMatches();
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _loading = false;
      });
    }
  }

  // ─── FETCH ALL MATCHES ───
  Future<void> _fetchAllMatches() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
      _filter = 'all';
    });

    try {
      final matches = await _apiService.getAllMatches();
      setState(() {
        _matches = matches;
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
            content: Text('Match track nahi hua (live nahi hai shayad)'),
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
            labelText: 'Match ID',
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
              await _trackMatch(idCtrl.text.trim(), 'Match');
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── MATCH STATUS BADGE ───
  Widget _statusBadge(Map<String, dynamic> match) {
    bool matchStarted = match['matchStarted'] ?? false;
    bool matchEnded = match['matchEnded'] ?? false;

    Color color;
    String label;

    if (matchEnded) {
      color = Colors.grey;
      label = 'ENDED';
    } else if (matchStarted) {
      color = Colors.redAccent;
      label = 'LIVE';
    } else {
      color = Colors.orange;
      label = 'UPCOMING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
          // ─── ADD BY MATCH ID ───
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

          // ─── 3 BUTTONS ───
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _filter == 'live'
                        ? const Color(0xFF0A1931)
                        : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  label: const Text(
                    'Live',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: _loading ? null : _fetchLiveMatches,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _filter == 'all' ? Colors.blue : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.list, color: Colors.white, size: 18),
                  label: const Text(
                    'All Matches',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: _loading ? null : _fetchAllMatches,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Auto All',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_matches.isEmpty) {
                            await _fetchLiveMatches();
                          }
                          for (var match in _matches) {
                            final id = match['id']?.toString() ?? '';
                            if (id.isNotEmpty &&
                                !_trackedMatchIds.contains(id)) {
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

          // ─── LOADING ───
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),

          // ─── ERROR ───
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

          // ─── FILTER INFO ───
          if (_matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _filter == 'live'
                    ? 'LIVE MATCHES (${_matches.length})'
                    : 'ALL MATCHES (${_matches.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
            ),

          // ─── MATCHES LIST ───
          ..._matches.map((match) {
            final id = match['id']?.toString() ?? '';
            final name = match['name']?.toString() ?? 'Unknown Match';
            final status = match['status']?.toString() ?? '';
            final venue = match['venue']?.toString() ?? '';
            final dateTimeGMT = match['dateTimeGMT']?.toString() ?? '';
            final isTracked = _trackedMatchIds.contains(id);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── NAME + BADGE ───
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _statusBadge(match),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ─── VENUE ───
                    if (venue.isNotEmpty)
                      Text(
                        '📍 $venue',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),

                    // ─── DATE ───
                    if (dateTimeGMT.isNotEmpty)
                      Text(
                        '📅 ${dateTimeGMT.substring(0, 10)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),

                    // ─── STATUS ───
                    if (status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // ─── MATCH ID ───
                    Text(
                      'ID: $id',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[400],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ─── TRACK BUTTON ───
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTracked
                                  ? Colors.grey
                                  : Colors.redAccent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: Icon(
                              isTracked ? Icons.check : Icons.track_changes,
                              color: Colors.white,
                              size: 16,
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
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.sync,
                                  color: Colors.white, size: 16),
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