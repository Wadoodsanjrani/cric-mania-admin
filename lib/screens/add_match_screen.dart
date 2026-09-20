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

  // Team 1 Batting
  List<Map<String, TextEditingController>> _team1Batting = [];

  // Team 2 Bowling
  List<Map<String, TextEditingController>> _team2Bowling = [];

  // Team 2 Batting
  List<Map<String, TextEditingController>> _team2Batting = [];

  // Team 1 Bowling
  List<Map<String, TextEditingController>> _team1Bowling = [];

  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) _loadMatch();
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
      'tournament': _tournamentCtrl.text.trim(),
      'team1': _team1Ctrl.text.trim(),
      'team2': _team2Ctrl.text.trim(),
      'score1': _score1Ctrl.text.trim(),
      'score2': _score2Ctrl.text.trim(),
      'result': _resultCtrl.text.trim(),
      'status': _status,
      'team1Batting': team1BattingData,
      'team2Bowling': team2BowlingData,
      'team2Batting': team2BattingData,
      'team1Bowling': team1BowlingData,
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
          _sectionTitle('Match Info'),
          _field('Tournament', _tournamentCtrl),
          _field('Team 1', _team1Ctrl),
          _field('Team 2', _team2Ctrl),
          _field('Score 1', _score1Ctrl),
          _field('Score 2', _score2Ctrl),
          _field('Result', _resultCtrl),

          const SizedBox(height: 12),
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
          _sectionTitle('${_team1Ctrl.text.isEmpty ? "Team 1" : _team1Ctrl.text} - Batting'),
          _battingHeader(),
          ..._team1Batting.asMap().entries.map((e) => _battingRow(e.key, e.value, _team1Batting)),
          _addButton('Add Batter', () {
            setState(() => _team1Batting.add(_batterCtrl()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('${_team2Ctrl.text.isEmpty ? "Team 2" : _team2Ctrl.text} - Bowling'),
          _bowlingHeader(),
          ..._team2Bowling.asMap().entries.map((e) => _bowlingRow(e.key, e.value, _team2Bowling)),
          _addButton('Add Bowler', () {
            setState(() => _team2Bowling.add(_bowlerCtrl()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('${_team2Ctrl.text.isEmpty ? "Team 2" : _team2Ctrl.text} - Batting'),
          _battingHeader(),
          ..._team2Batting.asMap().entries.map((e) => _battingRow(e.key, e.value, _team2Batting)),
          _addButton('Add Batter', () {
            setState(() => _team2Batting.add(_batterCtrl()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('${_team1Ctrl.text.isEmpty ? "Team 1" : _team1Ctrl.text} - Bowling'),
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
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.matchId == null ? 'ADD MATCH' : 'UPDATE MATCH',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _battingHeader() {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text('How Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _battingRow(int index, Map<String, TextEditingController> c, List list) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: TextField(controller: c['name'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(flex: 3, child: TextField(controller: c['howOut'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['r'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['b'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['fours'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['sixes'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['sr'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
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
          Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _bowlingRow(int index, Map<String, TextEditingController> c, List list) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: TextField(controller: c['name'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['o'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['m'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['r'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
          const SizedBox(width: 2),
          Expanded(child: TextField(controller: c['w'], decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()))),
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
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0A1931)),
      ),
    );
  }
}