import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/points_rules.dart';

/// Points Rules Screen — view + save default rules
/// Firestore path: settings/rules
class PointsRulesScreen extends StatefulWidget {
  const PointsRulesScreen({super.key});

  @override
  State<PointsRulesScreen> createState() => _PointsRulesScreenState();
}

class _PointsRulesScreenState extends State<PointsRulesScreen> {
  final _fs = FirebaseFirestore.instance;
  bool _saving = false;

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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header('T20 Batting (runs → points)'),
              _row('25–40', rules.t20BattingPoints[0].toString()),
              _row('41–59', rules.t20BattingPoints[1].toString()),
              _row('60–74', rules.t20BattingPoints[2].toString()),
              _row('75+', rules.t20BattingPoints[3].toString()),

              _header('T20 Bowling (wickets → points)'),
              _row('1', rules.t20BowlingPoints[0].toString()),
              _row('2–3', rules.t20BowlingPoints[1].toString()),
              _row('4', rules.t20BowlingPoints[2].toString()),
              _row('5+', rules.t20BowlingPoints[3].toString()),

              _header('ODI Batting (runs → points)'),
              _row('30–45', rules.odiBattingPoints[0].toString()),
              _row('46–60', rules.odiBattingPoints[1].toString()),
              _row('61–79', rules.odiBattingPoints[2].toString()),
              _row('80–99', rules.odiBattingPoints[3].toString()),
              _row('100+', rules.odiBattingPoints[4].toString()),

              _header('ODI Bowling (wickets → points)'),
              _row('1–2', rules.odiBowlingPoints[0].toString()),
              _row('3', rules.odiBowlingPoints[1].toString()),
              _row('4', rules.odiBowlingPoints[2].toString()),
              _row('5', rules.odiBowlingPoints[3].toString()),
              _row('6+', rules.odiBowlingPoints[4].toString()),

              _header('Special Awards'),
              _row('Man of the Match (MOTM)', '+${rules.momPoints}'),
              _row('Man of the Series (MOTS)', '+${rules.mosPoints}'),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1931),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : () => _saveDefaults(rules),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Default Rules'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Rules Firestore ke settings/rules mein save hote hain.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }

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

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A1931),
              ),
            ),
          ],
        ),
      );

  Future<void> _saveDefaults(PointsRules rules) async {
    setState(() => _saving = true);
    try {
      await _fs
          .collection('settings')
          .doc('rules')
          .set(rules.toMap(), SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rules saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}