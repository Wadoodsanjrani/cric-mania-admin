import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/points_rules.dart';

/// Points Rules Screen — Editable rules
/// Firestore path: settings/rules
class PointsRulesScreen extends StatefulWidget {
  const PointsRulesScreen({super.key});

  @override
  State<PointsRulesScreen> createState() => _PointsRulesScreenState();
}

class _PointsRulesScreenState extends State<PointsRulesScreen> {
  final _fs = FirebaseFirestore.instance;
  bool _saving = false;

  // ─── Controllers for T20 Batting ───
  final _t20Bat1 = TextEditingController();
  final _t20Bat2 = TextEditingController();
  final _t20Bat3 = TextEditingController();
  final _t20Bat4 = TextEditingController();

  // ─── Controllers for T20 Bowling ───
  final _t20Bowl1 = TextEditingController();
  final _t20Bowl2 = TextEditingController();
  final _t20Bowl3 = TextEditingController();
  final _t20Bowl4 = TextEditingController();

  // ─── Controllers for ODI Batting ───
  final _odiBat1 = TextEditingController();
  final _odiBat2 = TextEditingController();
  final _odiBat3 = TextEditingController();
  final _odiBat4 = TextEditingController();
  final _odiBat5 = TextEditingController();

  // ─── Controllers for ODI Bowling ───
  final _odiBowl1 = TextEditingController();
  final _odiBowl2 = TextEditingController();
  final _odiBowl3 = TextEditingController();
  final _odiBowl4 = TextEditingController();
  final _odiBowl5 = TextEditingController();

  // ─── Controllers for Special Awards ───
  final _momCtrl = TextEditingController();
  final _mosCtrl = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _t20Bat1.dispose();
    _t20Bat2.dispose();
    _t20Bat3.dispose();
    _t20Bat4.dispose();
    _t20Bowl1.dispose();
    _t20Bowl2.dispose();
    _t20Bowl3.dispose();
    _t20Bowl4.dispose();
    _odiBat1.dispose();
    _odiBat2.dispose();
    _odiBat3.dispose();
    _odiBat4.dispose();
    _odiBat5.dispose();
    _odiBowl1.dispose();
    _odiBowl2.dispose();
    _odiBowl3.dispose();
    _odiBowl4.dispose();
    _odiBowl5.dispose();
    _momCtrl.dispose();
    _mosCtrl.dispose();
    super.dispose();
  }

  void _loadRules(PointsRules rules) {
    if (_initialized) return;

    _t20Bat1.text = rules.t20BattingPoints[0].toString();
    _t20Bat2.text = rules.t20BattingPoints[1].toString();
    _t20Bat3.text = rules.t20BattingPoints[2].toString();
    _t20Bat4.text = rules.t20BattingPoints[3].toString();

    _t20Bowl1.text = rules.t20BowlingPoints[0].toString();
    _t20Bowl2.text = rules.t20BowlingPoints[1].toString();
    _t20Bowl3.text = rules.t20BowlingPoints[2].toString();
    _t20Bowl4.text = rules.t20BowlingPoints[3].toString();

    _odiBat1.text = rules.odiBattingPoints[0].toString();
    _odiBat2.text = rules.odiBattingPoints[1].toString();
    _odiBat3.text = rules.odiBattingPoints[2].toString();
    _odiBat4.text = rules.odiBattingPoints[3].toString();
    _odiBat5.text = rules.odiBattingPoints[4].toString();

    _odiBowl1.text = rules.odiBowlingPoints[0].toString();
    _odiBowl2.text = rules.odiBowlingPoints[1].toString();
    _odiBowl3.text = rules.odiBowlingPoints[2].toString();
    _odiBowl4.text = rules.odiBowlingPoints[3].toString();
    _odiBowl5.text = rules.odiBowlingPoints[4].toString();

    _momCtrl.text = rules.momPoints.toString();
    _mosCtrl.text = rules.mosPoints.toString();

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text(
          'Points Rules',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _fs.collection('settings').doc('rules').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rules = (snapshot.hasData && snapshot.data!.exists)
              ? PointsRules.fromMap(snapshot.data!.data()!)
              : PointsRules.defaults();

          // Load rules into controllers (only once)
          _loadRules(rules);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Info Banner ───
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade800, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Edit the points below and tap Save. '
                        'New points will apply to all future matches.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── T20 Batting ───
              _header('T20 Batting (runs → points)'),
              _editRow('25–40', _t20Bat1),
              _editRow('41–59', _t20Bat2),
              _editRow('60–74', _t20Bat3),
              _editRow('75+', _t20Bat4),

              // ─── T20 Bowling ───
              _header('T20 Bowling (wickets → points)'),
              _editRow('1', _t20Bowl1),
              _editRow('2–3', _t20Bowl2),
              _editRow('4', _t20Bowl3),
              _editRow('5+', _t20Bowl4),

              // ─── ODI Batting ───
              _header('ODI Batting (runs → points)'),
              _editRow('30–45', _odiBat1),
              _editRow('46–60', _odiBat2),
              _editRow('61–79', _odiBat3),
              _editRow('80–99', _odiBat4),
              _editRow('100+', _odiBat5),

              // ─── ODI Bowling ───
              _header('ODI Bowling (wickets → points)'),
              _editRow('1–2', _odiBowl1),
              _editRow('3', _odiBowl2),
              _editRow('4', _odiBowl3),
              _editRow('5', _odiBowl4),
              _editRow('6+', _odiBowl5),

              // ─── Special Awards ───
              _header('Special Awards'),
              _editRow('Man of the Match (MOTM)', _momCtrl),
              _editRow('Man of the Series (MOTS)', _mosCtrl),

              const SizedBox(height: 24),

              // ─── Save Button ───
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1931),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _saveRules,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Rules'),
              ),

              const SizedBox(height: 12),

              // ─── Reset to Defaults ───
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: _saving ? null : _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
              ),

              const SizedBox(height: 8),
              const Text(
                'Note: Rules are saved in Firestore (settings/rules).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Section header ───
  Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1931),
          ),
        ),
      );

  // ─── Editable row ───
  Widget _editRow(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A1931),
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    vertical: 8, horizontal: 8),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Save Rules ───
  Future<void> _saveRules() async {
    // Validate all fields
    final values = [
      _t20Bat1, _t20Bat2, _t20Bat3, _t20Bat4,
      _t20Bowl1, _t20Bowl2, _t20Bowl3, _t20Bowl4,
      _odiBat1, _odiBat2, _odiBat3, _odiBat4, _odiBat5,
      _odiBowl1, _odiBowl2, _odiBowl3, _odiBowl4, _odiBowl5,
      _momCtrl, _mosCtrl,
    ];

    for (final ctrl in values) {
      if (ctrl.text.trim().isEmpty || int.tryParse(ctrl.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid numbers in all fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final updatedRules = PointsRules(
        // T20 Batting
        t20Batting: [25, 41, 60, 75],
        t20BattingPoints: [
          int.parse(_t20Bat1.text.trim()),
          int.parse(_t20Bat2.text.trim()),
          int.parse(_t20Bat3.text.trim()),
          int.parse(_t20Bat4.text.trim()),
        ],
        // T20 Bowling
        t20Bowling: [1, 2, 4, 5],
        t20BowlingPoints: [
          int.parse(_t20Bowl1.text.trim()),
          int.parse(_t20Bowl2.text.trim()),
          int.parse(_t20Bowl3.text.trim()),
          int.parse(_t20Bowl4.text.trim()),
        ],
        // ODI Batting
        odiBatting: [30, 46, 61, 80, 100],
        odiBattingPoints: [
          int.parse(_odiBat1.text.trim()),
          int.parse(_odiBat2.text.trim()),
          int.parse(_odiBat3.text.trim()),
          int.parse(_odiBat4.text.trim()),
          int.parse(_odiBat5.text.trim()),
        ],
        // ODI Bowling
        odiBowling: [1, 3, 4, 5, 6],
        odiBowlingPoints: [
          int.parse(_odiBowl1.text.trim()),
          int.parse(_odiBowl2.text.trim()),
          int.parse(_odiBowl3.text.trim()),
          int.parse(_odiBowl4.text.trim()),
          int.parse(_odiBowl5.text.trim()),
        ],
        // Special Awards
        momPoints: int.parse(_momCtrl.text.trim()),
        mosPoints: int.parse(_mosCtrl.text.trim()),
      );

      await _fs
          .collection('settings')
          .doc('rules')
          .set(updatedRules.toMap(), SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rules saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Reset to Defaults ───
  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all points rules to their default values.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final defaults = PointsRules.defaults();

    // Load defaults into controllers
    _t20Bat1.text = defaults.t20BattingPoints[0].toString();
    _t20Bat2.text = defaults.t20BattingPoints[1].toString();
    _t20Bat3.text = defaults.t20BattingPoints[2].toString();
    _t20Bat4.text = defaults.t20BattingPoints[3].toString();

    _t20Bowl1.text = defaults.t20BowlingPoints[0].toString();
    _t20Bowl2.text = defaults.t20BowlingPoints[1].toString();
    _t20Bowl3.text = defaults.t20BowlingPoints[2].toString();
    _t20Bowl4.text = defaults.t20BowlingPoints[3].toString();

    _odiBat1.text = defaults.odiBattingPoints[0].toString();
    _odiBat2.text = defaults.odiBattingPoints[1].toString();
    _odiBat3.text = defaults.odiBattingPoints[2].toString();
    _odiBat4.text = defaults.odiBattingPoints[3].toString();
    _odiBat5.text = defaults.odiBattingPoints[4].toString();

    _odiBowl1.text = defaults.odiBowlingPoints[0].toString();
    _odiBowl2.text = defaults.odiBowlingPoints[1].toString();
    _odiBowl3.text = defaults.odiBowlingPoints[2].toString();
    _odiBowl4.text = defaults.odiBowlingPoints[3].toString();
    _odiBowl5.text = defaults.odiBowlingPoints[4].toString();

    _momCtrl.text = defaults.momPoints.toString();
    _mosCtrl.text = defaults.mosPoints.toString();

    setState(() {});
  }
}