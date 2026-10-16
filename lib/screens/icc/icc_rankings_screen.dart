import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin — ICC Rankings Screen
/// Firestore path: icc_rankings/{gender}/{format}/{category}/list/{docId}
class IccRankingsScreen extends StatefulWidget {
  const IccRankingsScreen({super.key});

  @override
  State<IccRankingsScreen> createState() => _IccRankingsScreenState();
}

class _IccRankingsScreenState extends State<IccRankingsScreen> {
  final _firestore = FirebaseFirestore.instance;

  String _gender = 'men';
  String _format = 'test';
  int _tab = 0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Manage ICC Rankings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Gender',
                        value: _gender,
                        items: const ['men', 'women'],
                        display: (v) => v == 'men' ? '👨 Men' : '👩 Women',
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropdown(
                        label: 'Format',
                        value: _format,
                        items: const ['test', 'odi', 't20'],
                        display: (v) => v.toUpperCase(),
                        onChanged: (v) => setState(() => _format = v!),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(child: _tabBtn('Team Rankings', 0)),
                    Expanded(child: _tabBtn('Player Rankings', 1)),
                  ],
                ),
              ),
              Expanded(
                child: _tab == 0 ? _teamsSection() : _playersSection(),
              ),
            ],
          ),
          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────── TEAMS ───────────
  Widget _teamsSection() {
    final ref = _firestore
        .collection('icc_rankings')
        .doc(_gender)
        .collection(_format)
        .doc('teams')
        .collection('list');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1931),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                '+ ADD TEAM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showTeamDialog(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ref.orderBy('position').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No teams added yet'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _teamRow(docs[i].id, d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _teamRow(String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '#${data['position'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['team'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Matches: ${data['matches'] ?? 0} • Points: ${data['points'] ?? 0} • Rating: ${data['rating'] ?? 0}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showTeamDialog(docId: docId, data: data),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteTeam(docId),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamDialog({String? docId, Map<String, dynamic>? data}) {
    final teamCtrl =
        TextEditingController(text: data?['team']?.toString() ?? '');
    final posCtrl =
        TextEditingController(text: data?['position']?.toString() ?? '');
    final matchCtrl =
        TextEditingController(text: data?['matches']?.toString() ?? '');
    final ptsCtrl =
        TextEditingController(text: data?['points']?.toString() ?? '');
    final rateCtrl =
        TextEditingController(text: data?['rating']?.toString() ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(docId == null ? 'Add Team' : 'Edit Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teamCtrl,
                  decoration: const InputDecoration(labelText: 'Team Name'),
                ),
                TextField(
                  controller: posCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Position (rank)'),
                ),
                TextField(
                  controller: matchCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Matches'),
                ),
                TextField(
                  controller: ptsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points'),
                ),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rating'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1931)),
              onPressed: () async {
                if (teamCtrl.text.trim().isEmpty) {
                  _snack('Team name required', isError: true);
                  return;
                }
                setSt(() {});
                try {
                  final ref = _firestore
                      .collection('icc_rankings')
                      .doc(_gender)
                      .collection(_format)
                      .doc('teams')
                      .collection('list');

                  final payload = {
                    'team': teamCtrl.text.trim(),
                    'position': int.tryParse(posCtrl.text.trim()) ?? 0,
                    'matches': int.tryParse(matchCtrl.text.trim()) ?? 0,
                    'points': int.tryParse(ptsCtrl.text.trim()) ?? 0,
                    'rating': int.tryParse(rateCtrl.text.trim()) ?? 0,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  debugPrint('ICC SAVE path: icc_rankings/$_gender/$_format/teams/list');

                  if (docId == null) {
                    await ref.add(payload);
                  } else {
                    await ref.doc(docId).set(payload, SetOptions(merge: true));
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('✅ Team saved', isError: false);
                } catch (e) {
                  debugPrint('ICC SAVE ERROR: $e');
                  _snack('❌ $e', isError: true);
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTeam(String docId) async {
    final ok = await _confirmDelete('team');
    if (ok != true) return;
    try {
      await _firestore
          .collection('icc_rankings')
          .doc(_gender)
          .collection(_format)
          .doc('teams')
          .collection('list')
          .doc(docId)
          .delete();
      _snack('Team deleted', isError: false);
    } catch (e) {
      _snack('❌ $e', isError: true);
    }
  }

  // ─────────── PLAYERS ───────────
  Widget _playersSection() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _playerCategory('batters', '🏏 Batters'),
        const SizedBox(height: 16),
        _playerCategory('bowlers', '🎯 Bowlers'),
        const SizedBox(height: 16),
        _playerCategory('allrounders', '⚡ All Rounders'),
      ],
    );
  }

  Widget _playerCategory(String category, String title) {
    final ref = _firestore
        .collection('icc_rankings')
        .doc(_gender)
        .collection(_format)
        .doc(category)
        .collection('list');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1931),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text('+ ADD ${category.toUpperCase()}'),
            onPressed: () => _showPlayerDialog(category),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A1931),
              side: const BorderSide(color: Color(0xFF0A1931)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: ref.orderBy('rank').snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child:
                    Text('No entries yet', style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return _playerRow(category, doc.id, d);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _playerRow(String category, String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#${data['rank'] ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${data['country'] ?? ''} • Rating: ${data['rating'] ?? 0}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showPlayerDialog(category,
                  docId: docId, data: data),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deletePlayer(category, docId),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayerDialog(
    String category, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final nameCtrl =
        TextEditingController(text: data?['name']?.toString() ?? '');
    final countryCtrl =
        TextEditingController(text: data?['country']?.toString() ?? '');
    final rankCtrl =
        TextEditingController(text: data?['rank']?.toString() ?? '');
    final rateCtrl =
        TextEditingController(text: data?['rating']?.toString() ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(
              docId == null ? 'Add ${category.toUpperCase()}' : 'Edit Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Player Name'),
                ),
                TextField(
                  controller: countryCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Country (e.g. PAK, IND, ENG)'),
                ),
                TextField(
                  controller: rankCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Rank (position)'),
                ),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rating'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1931)),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  _snack('Player name required', isError: true);
                  return;
                }
                try {
                  final ref = _firestore
                      .collection('icc_rankings')
                      .doc(_gender)
                      .collection(_format)
                      .doc(category)
                      .collection('list');

                  final payload = {
                    'name': nameCtrl.text.trim(),
                    'country': countryCtrl.text.trim().toUpperCase(),
                    'rank': int.tryParse(rankCtrl.text.trim()) ?? 0,
                    'rating': int.tryParse(rateCtrl.text.trim()) ?? 0,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  debugPrint('ICC SAVE path: icc_rankings/$_gender/$_format/$category/list');

                  if (docId == null) {
                    await ref.add(payload);
                  } else {
                    await ref.doc(docId).set(payload, SetOptions(merge: true));
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('✅ Player saved', isError: false);
                } catch (e) {
                  debugPrint('ICC SAVE ERROR: $e');
                  _snack('❌ $e', isError: true);
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlayer(String category, String docId) async {
    final ok = await _confirmDelete('player');
    if (ok != true) return;
    try {
      await _firestore
          .collection('icc_rankings')
          .doc(_gender)
          .collection(_format)
          .doc(category)
          .collection('list')
          .doc(docId)
          .delete();
      _snack('Player deleted', isError: false);
    } catch (e) {
      _snack('❌ $e', isError: true);
    }
  }

  Future<bool?> _confirmDelete(String what) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $what?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 8 : 2),
      ),
    );
  }

  // ─────────── HELPERS ───────────
  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required String Function(String) display,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(display(e)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF0A1931) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF0A1931) : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}