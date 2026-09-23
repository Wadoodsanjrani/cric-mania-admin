import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateMatchScreen extends StatefulWidget {
  final String matchId;
  const UpdateMatchScreen({super.key, required this.matchId});

  @override
  State<UpdateMatchScreen> createState() => _UpdateMatchScreenState();
}

class _UpdateMatchScreenState extends State<UpdateMatchScreen> {
  final _tournamentCtrl = TextEditingController();
  final _team1Ctrl = TextEditingController();
  final _team2Ctrl = TextEditingController();
  final _score1Ctrl = TextEditingController();
  final _score2Ctrl = TextEditingController();
  final _resultCtrl = TextEditingController();

  String _matchStatus = 'live';

  List<Map<String, dynamic>> _team1Batting = [];
  List<Map<String, dynamic>> _team2Bowling = [];
  List<Map<String, dynamic>> _team2Batting = [];
  List<Map<String, dynamic>> _team1Bowling = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  @override
  void dispose() {
    _tournamentCtrl.dispose();
    _team1Ctrl.dispose();
    _team2Ctrl.dispose();
    _score1Ctrl.dispose();
    _score2Ctrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMatch() async {
    final doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _tournamentCtrl.text = data['tournament'] ?? '';
        _team1Ctrl.text = data['team1'] ?? '';
        _team2Ctrl.text = data['team2'] ?? '';
        _score1Ctrl.text = data['score1'] ?? '';
        _score2Ctrl.text = data['score2'] ?? '';
        _resultCtrl.text = data['result'] ?? '';
        _matchStatus = (data['status'] ?? 'LIVE').toString().toUpperCase() == 'LIVE' ? 'live' : 'result';
        _team1Batting = List<Map<String, dynamic>>.from((data['team1Batting'] ?? []).map((e) => Map<String, dynamic>.from(e)));
        _team2Bowling = List<Map<String, dynamic>>.from((data['team2Bowling'] ?? []).map((e) => Map<String, dynamic>.from(e)));
        _team2Batting = List<Map<String, dynamic>>.from((data['team2Batting'] ?? []).map((e) => Map<String, dynamic>.from(e)));
        _team1Bowling = List<Map<String, dynamic>>.from((data['team1Bowling'] ?? []).map((e) => Map<String, dynamic>.from(e)));
        _loading = false;
      });
    }
  }

  Future<void> _updateMatch() async {
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'tournament': _tournamentCtrl.text.trim(),
        'team1': _team1Ctrl.text.trim(),
        'team2': _team2Ctrl.text.trim(),
        'score1': _score1Ctrl.text.trim(),
        'score2': _score2Ctrl.text.trim(),
        'status': _matchStatus == 'live' ? 'LIVE' : 'RESULT',
        'result': _resultCtrl.text.trim(),
        'team1Batting': _team1Batting,
        'team2Bowling': _team2Bowling,
        'team2Batting': _team2Batting,
        'team1Bowling': _team1Bowling,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1931),
          title: const Text('Update Match', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text('Update Match', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Match Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('🔴 LIVE'),
                  value: 'live',
                  groupValue: _matchStatus,
                  onChanged: (val) => setState(() => _matchStatus = val!),
                  activeColor: Colors.redAccent,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('✅ RESULT'),
                  value: 'result',
                  groupValue: _matchStatus,
                  onChanged: (val) => setState(() => _matchStatus = val!),
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const Divider(),

          _textField(_tournamentCtrl, 'Tournament'),
          const SizedBox(height: 12),
          _textField(_team1Ctrl, 'Team 1 Name'),
          const SizedBox(height: 12),
          _textField(_team2Ctrl, 'Team 2 Name'),
          const SizedBox(height: 12),
          _textField(_score1Ctrl, 'Team 1 Score'),
          const SizedBox(height: 12),
          _textField(_score2Ctrl, 'Team 2 Score'),

          const SizedBox(height: 24),

          _sectionHeader('🏏 ${_team1Ctrl.text} BATTING'),
          _addButton('+ ADD BATTER', () => _addBatter(1)),
          ..._team1Batting.asMap().entries.map((e) => _batterCard(e.value, e.key, 1)).toList(),

          const SizedBox(height: 20),

          _sectionHeader('🎯 ${_team2Ctrl.text} BOWLING'),
          _addButton('+ ADD BOWLER', () => _addBowler(2)),
          ..._team2Bowling.asMap().entries.map((e) => _bowlerCard(e.value, e.key, 2)).toList(),

          const SizedBox(height: 24),

          _sectionHeader('🏏 ${_team2Ctrl.text} BATTING'),
          _addButton('+ ADD BATTER', () => _addBatter(2)),
          ..._team2Batting.asMap().entries.map((e) => _batterCard(e.value, e.key, 2)).toList(),

          const SizedBox(height: 20),

          _sectionHeader('🎯 ${_team1Ctrl.text} BOWLING'),
          _addButton('+ ADD BOWLER', () => _addBowler(1)),
          ..._team1Bowling.asMap().entries.map((e) => _bowlerCard(e.value, e.key, 1)).toList(),

          const SizedBox(height: 24),

          _textField(_resultCtrl, 'Result'),

          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1931),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _updateMatch,
            child: const Text('UPDATE MATCH', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add),
        label: Text(label),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0A1931)),
      ),
    );
  }

  Widget _batterCard(Map<String, dynamic> batter, int index, int team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(batter['name'] ?? 'Batter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editBatter(batter, index, team),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      if (team == 1) {
                        _team1Batting.removeAt(index);
                      } else {
                        _team2Batting.removeAt(index);
                      }
                    });
                  },
                ),
              ],
            ),
            if ((batter['howOut'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(batter['howOut'], style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                ),
              ),
            Row(
              children: [
                _statBox('R', batter['r'] ?? '0'),
                _statBox('B', batter['b'] ?? '0'),
                _statBox('4s', batter['4s'] ?? '0'),
                _statBox('6s', batter['6s'] ?? '0'),
                _statBox('SR', batter['sr'] ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bowlerCard(Map<String, dynamic> bowler, int index, int team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(bowler['name'] ?? 'Bowler', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editBowler(bowler, index, team),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      if (team == 2) {
                        _team2Bowling.removeAt(index);
                      } else {
                        _team1Bowling.removeAt(index);
                      }
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                _statBox('O', bowler['o'] ?? '0'),
                _statBox('M', bowler['m'] ?? '0'),
                _statBox('R', bowler['r'] ?? '0'),
                _statBox('W', bowler['w'] ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _addBatter(int team) {
    final nameCtrl = TextEditingController();
    final howOutCtrl = TextEditingController();
    final rCtrl = TextEditingController();
    final bCtrl = TextEditingController();
    final foursCtrl = TextEditingController();
    final sixesCtrl = TextEditingController();
    final srCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Batter (Team $team)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: howOutCtrl, decoration: const InputDecoration(labelText: 'How Out')),
              Row(children: [
                Expanded(child: TextField(controller: rCtrl, decoration: const InputDecoration(labelText: 'R'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'B'), keyboardType: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: foursCtrl, decoration: const InputDecoration(labelText: '4s'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: sixesCtrl, decoration: const InputDecoration(labelText: '6s'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: srCtrl, decoration: const InputDecoration(labelText: 'SR'), keyboardType: TextInputType.number)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1931)),
            onPressed: () {
              setState(() {
                final batter = {
                  'name': nameCtrl.text.trim(),
                  'howOut': howOutCtrl.text.trim(),
                  'r': rCtrl.text.trim(),
                  'b': bCtrl.text.trim(),
                  '4s': foursCtrl.text.trim(),
                  '6s': sixesCtrl.text.trim(),
                  'sr': srCtrl.text.trim(),
                };
                if (team == 1) {
                  _team1Batting.add(batter);
                } else {
                  _team2Batting.add(batter);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editBatter(Map<String, dynamic> batter, int index, int team) {
    final nameCtrl = TextEditingController(text: batter['name'] ?? '');
    final howOutCtrl = TextEditingController(text: batter['howOut'] ?? '');
    final rCtrl = TextEditingController(text: batter['r'] ?? '');
    final bCtrl = TextEditingController(text: batter['b'] ?? '');
    final foursCtrl = TextEditingController(text: batter['4s'] ?? '');
    final sixesCtrl = TextEditingController(text: batter['6s'] ?? '');
    final srCtrl = TextEditingController(text: batter['sr'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Batter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: howOutCtrl, decoration: const InputDecoration(labelText: 'How Out')),
              Row(children: [
                Expanded(child: TextField(controller: rCtrl, decoration: const InputDecoration(labelText: 'R'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'B'), keyboardType: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: foursCtrl, decoration: const InputDecoration(labelText: '4s'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: sixesCtrl, decoration: const InputDecoration(labelText: '6s'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: srCtrl, decoration: const InputDecoration(labelText: 'SR'), keyboardType: TextInputType.number)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1931)),
            onPressed: () {
              setState(() {
                final updated = {
                  'name': nameCtrl.text.trim(),
                  'howOut': howOutCtrl.text.trim(),
                  'r': rCtrl.text.trim(),
                  'b': bCtrl.text.trim(),
                  '4s': foursCtrl.text.trim(),
                  '6s': sixesCtrl.text.trim(),
                  'sr': srCtrl.text.trim(),
                };
                if (team == 1) {
                  _team1Batting[index] = updated;
                } else {
                  _team2Batting[index] = updated;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addBowler(int team) {
    final nameCtrl = TextEditingController();
    final oCtrl = TextEditingController();
    final mCtrl = TextEditingController();
    final rCtrl = TextEditingController();
    final wCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Bowler (Team $team)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              Row(children: [
                Expanded(child: TextField(controller: oCtrl, decoration: const InputDecoration(labelText: 'O'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: mCtrl, decoration: const InputDecoration(labelText: 'M'), keyboardType: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: rCtrl, decoration: const InputDecoration(labelText: 'R'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: wCtrl, decoration: const InputDecoration(labelText: 'W'), keyboardType: TextInputType.number)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1931)),
            onPressed: () {
              setState(() {
                final bowler = {
                  'name': nameCtrl.text.trim(),
                  'o': oCtrl.text.trim(),
                  'm': mCtrl.text.trim(),
                  'r': rCtrl.text.trim(),
                  'w': wCtrl.text.trim(),
                };
                if (team == 2) {
                  _team2Bowling.add(bowler);
                } else {
                  _team1Bowling.add(bowler);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editBowler(Map<String, dynamic> bowler, int index, int team) {
    final nameCtrl = TextEditingController(text: bowler['name'] ?? '');
    final oCtrl = TextEditingController(text: bowler['o'] ?? '');
    final mCtrl = TextEditingController(text: bowler['m'] ?? '');
    final rCtrl = TextEditingController(text: bowler['r'] ?? '');
    final wCtrl = TextEditingController(text: bowler['w'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Bowler'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              Row(children: [
                Expanded(child: TextField(controller: oCtrl, decoration: const InputDecoration(labelText: 'O'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: mCtrl, decoration: const InputDecoration(labelText: 'M'), keyboardType: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: rCtrl, decoration: const InputDecoration(labelText: 'R'), keyboardType: TextInputType.number)),
                Expanded(child: TextField(controller: wCtrl, decoration: const InputDecoration(labelText: 'W'), keyboardType: TextInputType.number)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1931)),
            onPressed: () {
              setState(() {
                final updated = {
                  'name': nameCtrl.text.trim(),
                  'o': oCtrl.text.trim(),
                  'm': mCtrl.text.trim(),
                  'r': rCtrl.text.trim(),
                  'w': wCtrl.text.trim(),
                };
                if (team == 2) {
                  _team2Bowling[index] = updated;
                } else {
                  _team1Bowling[index] = updated;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}