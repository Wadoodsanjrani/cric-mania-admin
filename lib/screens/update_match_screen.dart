import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateMatchScreen extends StatefulWidget {
  final String matchId;
  const UpdateMatchScreen({super.key, required this.matchId});

  @override
  State<UpdateMatchScreen> createState() => _UpdateMatchScreenState();
}

class _UpdateMatchScreenState extends State<UpdateMatchScreen> {
  bool _loading = true;
  bool _saving = false;

  String _team1 = '';
  String _team2 = '';
  String _format = 'T20I';
  String _status = 'LIVE';

  List<Map<String, TextEditingController>> _team1Batting = [];
  List<Map<String, TextEditingController>> _team2Bowling = [];
  List<Map<String, TextEditingController>> _team2Batting = [];
  List<Map<String, TextEditingController>> _team1Bowling = [];

  final _score1Ctrl = TextEditingController();
  final _score2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Map<String, TextEditingController> _batterCtrl() {
    return {
      'name': TextEditingController(),
      'howOut': TextEditingController(),
      'r': TextEditingController(),
      'b': TextEditingController(),
      'fours': TextEditingController(),
      'sixes': TextEditingController(),
      'sr': TextEditingController(),
    };
  }

  Map<String, TextEditingController> _bowlerCtrl() {
    return {
      'name': TextEditingController(),
      'o': TextEditingController(),
      'm': TextEditingController(),
      'r': TextEditingController(),
      'w': TextEditingController(),
    };
  }

  Future<void> _loadMatch() async {
    var doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .get();
    var data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      _team1 = data['team1'] ?? '';
      _team2 = data['team2'] ?? '';
      _format = data['format'] ?? 'T20I';
      _status = data['status'] ?? 'LIVE';
      _score1Ctrl.text = data['score1'] ?? '';
      _score2Ctrl.text = data['score2'] ?? '';

      // Load Team 1 Batting
      if (data['team1Batting'] != null) {
        for (var b in data['team1Batting']) {
          var c = _batterCtrl();
          c['name']!.text = b['name'] ?? '';
          c['howOut']!.text = b['howOut'] ?? '';
          c['r']!.text = b['r'] ?? '';
          c['b']!.text = b['b'] ?? '';
          c['fours']!.text = b['4s'] ?? '';
          c['sixes']!.text = b['6s'] ?? '';
          c['sr']!.text = b['sr'] ?? '';
          _team1Batting.add(c);
        }
      }

      // Load Team 2 Bowling
      if (data['team2Bowling'] != null) {
        for (var b in data['team2Bowling']) {
          var c = _bowlerCtrl();
          c['name']!.text = b['name'] ?? '';
          c['o']!.text = b['o'] ?? '';
          c['m']!.text = b['m'] ?? '';
          c['r']!.text = b['r'] ?? '';
          c['w']!.text = b['w'] ?? '';
          _team2Bowling.add(c);
        }
      }

      // Load Team 2 Batting
      if (data['team2Batting'] != null) {
        for (var b in data['team2Batting']) {
          var c = _batterCtrl();
          c['name']!.text = b['name'] ?? '';
          c['howOut']!.text = b['howOut'] ?? '';
          c['r']!.text = b['r'] ?? '';
          c['b']!.text = b['b'] ?? '';
          c['fours']!.text = b['4s'] ?? '';
          c['sixes']!.text = b['6s'] ?? '';
          c['sr']!.text = b['sr'] ?? '';
          _team2Batting.add(c);
        }
      }

      // Load Team 1 Bowling
      if (data['team1Bowling'] != null) {
        for (var b in data['team1Bowling']) {
          var c = _bowlerCtrl();
          c['name']!.text = b['name'] ?? '';
          c['o']!.text = b['o'] ?? '';
          c['m']!.text = b['m'] ?? '';
          c['r']!.text = b['r'] ?? '';
          c['w']!.text = b['w'] ?? '';
          _team1Bowling.add(c);
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    var team1BattingData = _team1Batting
        .where((b) => b['name']!.text.trim().isNotEmpty)
        .map((b) => {
              'name': b['name']!.text.trim(),
              'howOut': b['howOut']!.text.trim(),
              'r': b['r']!.text.trim(),
              'b': b['b']!.text.trim(),
              '4s': b['fours']!.text.trim(),
              '6s': b['sixes']!.text.trim(),
              'sr': b['sr']!.text.trim(),
            })
        .toList();

    var team2BowlingData = _team2Bowling
        .where((b) => b['name']!.text.trim().isNotEmpty)
        .map((b) => {
              'name': b['name']!.text.trim(),
              'o': b['o']!.text.trim(),
              'm': b['m']!.text.trim(),
              'r': b['r']!.text.trim(),
              'w': b['w']!.text.trim(),
            })
        .toList();

    var team2BattingData = _team2Batting
        .where((b) => b['name']!.text.trim().isNotEmpty)
        .map((b) => {
              'name': b['name']!.text.trim(),
              'howOut': b['howOut']!.text.trim(),
              'r': b['r']!.text.trim(),
              'b': b['b']!.text.trim(),
              '4s': b['fours']!.text.trim(),
              '6s': b['sixes']!.text.trim(),
              'sr': b['sr']!.text.trim(),
            })
        .toList();

    var team1BowlingData = _team1Bowling
        .where((b) => b['name']!.text.trim().isNotEmpty)
        .map((b) => {
              'name': b['name']!.text.trim(),
              'o': b['o']!.text.trim(),
              'm': b['m']!.text.trim(),
              'r': b['r']!.text.trim(),
              'w': b['w']!.text.trim(),
            })
        .toList();

    var data = {
      'score1': _score1Ctrl.text.trim(),
      'score2': _score2Ctrl.text.trim(),
      'status': _status,
      'team1Batting': team1BattingData,
      'team2Bowling': team2BowlingData,
      'team2Batting': team2BattingData,
      'team1Bowling': team1BowlingData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Match updated!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text('Live Update', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$_team1 vs $_team2',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Format: $_format', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),

          _sectionTitle('Current Score'),
          _field('Score 1', _score1Ctrl),
          _field('Score 2', _score2Ctrl),

          _sectionTitle('Status'),
          Wrap(
            spacing: 8,
            children: ['LIVE', 'RESULT']
                .map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),
          _sectionTitle('$_team1 - Batting'),
          _battingHeader(),
          ..._team1Batting.asMap().entries.map((e) => _battingRow(e.key, e.value, _team1Batting)),
          _addButton('Add Batter', () {
            setState(() => _team1Batting.add(_batterCtrl()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('$_team2 - Bowling'),
          _bowlingHeader(),
          ..._team2Bowling.asMap().entries.map((e) => _bowlingRow(e.key, e.value, _team2Bowling)),
          _addButton('Add Bowler', () {
            setState(() => _team2Bowling.add(_bowlerCtrl()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('$_team2 - Batting'),
          _battingHeader(),
          ..._team2Batting.asMap().entries.map((e) => _battingRow(e.key, e.value, _team2Batting)),
          _addButton('Add Batter', () {
            setState(() => _team2Batting.add(_batterCtrl()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('$_team1 - Bowling'),
          _bowlingHeader(),
          ..._team1Bowling.asMap().entries.map((e) => _bowlingRow(e.key, e.value, _team1Bowling)),
          _addButton('Add Bowler', () {
            setState(() => _team1Bowling.add(_bowlerCtrl()));
          }),

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1931),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SAVE UPDATES',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931))),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _battingHeader() {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: const Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('Name',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 3,
              child: Text('How Out',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('R',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('B',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('4s',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('6s',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('SR',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _battingRow(
      int index, Map<String, TextEditingController> c, List list) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: TextField(
                  controller: c['name'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              flex: 3,
              child: TextField(
                  controller: c['howOut'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['r'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['b'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['fours'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['sixes'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['sr'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => setState(() => list.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _bowlingHeader() {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: const Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('Name',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('O',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('M',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('R',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              child: Text('W',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _bowlingRow(
      int index, Map<String, TextEditingController> c, List list) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: TextField(
                  controller: c['name'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['o'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['m'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['r'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(
              child: TextField(
                  controller: c['w'],
                  decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder()))),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => setState(() => list.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0A1931)),
      ),
    );
  }
}