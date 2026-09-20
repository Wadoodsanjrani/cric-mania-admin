import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMatchScreen extends StatefulWidget {
  final String? matchId;
  const AddMatchScreen({super.key, this.matchId});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _tournamentCtrl = TextEditingController();
  final _team1Ctrl = TextEditingController();
  final _team2Ctrl = TextEditingController();
  final _score1Ctrl = TextEditingController();
  final _score2Ctrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  String _status = 'LIVE';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) _loadMatch();
  }

  Future<void> _loadMatch() async {
    var doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .get();
    var data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      setState(() {
        _tournamentCtrl.text = data['tournament'] ?? '';
        _team1Ctrl.text = data['team1'] ?? '';
        _team2Ctrl.text = data['team2'] ?? '';
        _score1Ctrl.text = data['score1'] ?? '';
        _score2Ctrl.text = data['score2'] ?? '';
        _resultCtrl.text = data['result'] ?? '';
        _status = data['status'] ?? 'LIVE';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    var data = {
      'tournament': _tournamentCtrl.text.trim(),
      'team1': _team1Ctrl.text.trim(),
      'team2': _team2Ctrl.text.trim(),
      'score1': _score1Ctrl.text.trim(),
      'score2': _score2Ctrl.text.trim(),
      'result': _resultCtrl.text.trim(),
      'status': _status,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      if (widget.matchId != null) {
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('matches').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: Text(
          widget.matchId == null ? 'Add Match' : 'Edit Match',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Tournament', _tournamentCtrl),
          _field('Team 1', _team1Ctrl),
          _field('Team 2', _team2Ctrl),
          _field('Score 1', _score1Ctrl),
          _field('Score 2', _score2Ctrl),
          _field('Result', _resultCtrl),
          const SizedBox(height: 12),
          const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['LIVE', 'UPCOMING', 'RESULT']
                .map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1931),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.matchId == null ? 'ADD MATCH' : 'UPDATE MATCH',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}