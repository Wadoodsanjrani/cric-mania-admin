import 'package:flutter/material.dart';
import '../../models/fantasy/team_model.dart';
import '../../services/fantasy/team_service.dart';
import '../../services/fantasy/match_service.dart';

/// Add Match Screen — tournament ke andar naya match add karne ke liye
class AddMatchScreen extends StatefulWidget {
  final String tournamentId;
  const AddMatchScreen({super.key, required this.tournamentId});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamService = TeamService();
  final _matchService = MatchService();

  String? _team1Id;
  String? _team2Id;
  DateTime _matchDate = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Match',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: _teamService.streamTeams(widget.tournamentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final teams = snapshot.data ?? [];

          if (teams.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Match add karne ke liye kam se kam 2 teams chahiye.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Abhi ${teams.length} team(s) hain.',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Select Teams',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 12),

                // Team 1
                DropdownButtonFormField<String>(
                  initialValue: _team1Id,
                  decoration: const InputDecoration(
                    labelText: 'Team 1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.groups),
                  ),
                  items: teams
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(
                              '${t.flag.isNotEmpty ? "${t.flag} " : ""}${t.name}',
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _team1Id = v),
                  validator: (v) =>
                      v == null ? 'Team 1 select karein' : null,
                ),
                const SizedBox(height: 12),

                // VS separator
                const Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1931),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Team 2
                DropdownButtonFormField<String>(
                  initialValue: _team2Id,
                  decoration: const InputDecoration(
                    labelText: 'Team 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.groups),
                  ),
                  items: teams
                      .where((t) => t.id != _team1Id)
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(
                              '${t.flag.isNotEmpty ? "${t.flag} " : ""}${t.name}',
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _team2Id = v),
                  validator: (v) {
                    if (v == null) return 'Team 2 select karein';
                    if (v == _team1Id) {
                      return 'Team 1 se alag team select karein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Match Date
                const Text(
                  'Match Date',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_fmt(_matchDate)),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1931),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving...' : 'Add Match'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _matchDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _matchDate = date);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_team1Id == null || _team2Id == null) return;

    setState(() => _saving = true);
    try {
      // Get team names for denormalization
      final team1 = await _teamService.getTeam(widget.tournamentId, _team1Id!);
      final team2 = await _teamService.getTeam(widget.tournamentId, _team2Id!);

      if (team1 == null || team2 == null) {
        throw Exception('Team not found');
      }

      await _matchService.addMatch(
        tournamentId: widget.tournamentId,
        team1Id: _team1Id!,
        team2Id: _team2Id!,
        team1Name: team1.name,
        team2Name: team2.name,
        matchDate: _matchDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match add ho gaya!')),
        );
        Navigator.pop(context);
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