import 'package:flutter/material.dart';
import '../../models/fantasy/player_model.dart';
import '../../services/fantasy/player_service.dart';
import '../../services/fantasy/stats_service.dart';
import '../../services/fantasy/match_service.dart';
import '../../services/fantasy/points_engine.dart';

/// Match Stats Screen — innings-wise stats entry
/// 4 sections: Team1 Batting, Team2 Bowling, Team2 Batting, Team1 Bowling
/// + MOTM (MOTS optional)
class MatchStatsScreen extends StatefulWidget {
  final String tournamentId;
  final String matchId;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;

  const MatchStatsScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
  });

  @override
  State<MatchStatsScreen> createState() => _MatchStatsScreenState();
}

class _MatchStatsScreenState extends State<MatchStatsScreen> {
  final _playerService = PlayerService();
  final _statsService = StatsService();
  final _matchService = MatchService();

  // Section entries: { playerId: { player: PlayerModel, value: int } }
  final Map<String, Map<String, dynamic>> _t1Batting = {};
  final Map<String, Map<String, dynamic>> _t2Bowling = {};
  final Map<String, Map<String, dynamic>> _t2Batting = {};
  final Map<String, Map<String, dynamic>> _t1Bowling = {};

  String? _motmPlayerId;
  String? _motsPlayerId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.team1Name} vs ${widget.team2Name}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // SECTION 1: Team1 Batting
          _section(
            title: '${widget.team1Name} — Batting',
            icon: Icons.sports_cricket,
            teamId: widget.team1Id,
            entries: _t1Batting,
            valueLabel: 'Runs',
          ),

          // SECTION 2: Team2 Bowling
          _section(
            title: '${widget.team2Name} — Bowling',
            icon: Icons.sports_baseball,
            teamId: widget.team2Id,
            entries: _t2Bowling,
            valueLabel: 'Wickets',
          ),

          // SECTION 3: Team2 Batting
          _section(
            title: '${widget.team2Name} — Batting',
            icon: Icons.sports_cricket,
            teamId: widget.team2Id,
            entries: _t2Batting,
            valueLabel: 'Runs',
          ),

          // SECTION 4: Team1 Bowling
          _section(
            title: '${widget.team1Name} — Bowling',
            icon: Icons.sports_baseball,
            teamId: widget.team1Id,
            entries: _t1Bowling,
            valueLabel: 'Wickets',
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 2),
          const SizedBox(height: 12),

          // MOTM
          _playerDropdown(
            label: 'Man of the Match',
            icon: Icons.star,
            value: _motmPlayerId,
            onChanged: (v) => setState(() => _motmPlayerId = v),
          ),

          const SizedBox(height: 16),

          // MOTS (optional)
          _playerDropdown(
            label: 'Man of the Series (optional)',
            icon: Icons.emoji_events,
            value: _motsPlayerId,
            onChanged: (v) => setState(() => _motsPlayerId = v),
          ),

          const SizedBox(height: 24),

          // Save button
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
            label: Text(_saving ? 'Saving...' : 'Save Stats'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────── Section Builder ───────────────────
  Widget _section({
    required String title,
    required IconData icon,
    required String teamId,
    required Map<String, Map<String, dynamic>> entries,
    required String valueLabel,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0A1931), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1931),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Existing players list
            ...entries.entries.map((e) {
              final data = e.value;
              final player = data['player'] as PlayerModel;
              return _playerRow(
                key: ValueKey('${title}_${e.key}'),
                player: player,
                initialValue: data['value'] as int,
                valueLabel: valueLabel,
                onChanged: (v) {
                  entries[e.key]!['value'] = v;
                },
                onRemove: () {
                  setState(() {
                    entries.remove(e.key);
                    if (_motmPlayerId == e.key) _motmPlayerId = null;
                    if (_motsPlayerId == e.key) _motsPlayerId = null;
                  });
                },
              );
            }),

            // Add player dropdown
            const SizedBox(height: 8),
            _addPlayerRow(
              teamId: teamId,
              excludeIds: entries.keys.toSet(),
              onSelected: (player) {
                setState(() {
                  entries[player.id] = {
                    'player': player,
                    'value': 0,
                  };
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerRow({
    required Key key,
    required PlayerModel player,
    required int initialValue,
    required String valueLabel,
    required ValueChanged<int> onChanged,
    required VoidCallback onRemove,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 80,
            child: _NumberField(
              initialValue: initialValue,
              label: valueLabel,
              onChanged: onChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _addPlayerRow({
    required String teamId,
    required Set<String> excludeIds,
    required ValueChanged<PlayerModel> onSelected,
  }) {
    return StreamBuilder<List<PlayerModel>>(
      stream: _playerService.streamPlayers(widget.tournamentId, teamId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final available = snapshot.data!
            .where((p) => !excludeIds.contains(p.id))
            .toList();

        if (available.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'All players added.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        return Row(
          children: [
            const Icon(Icons.add_circle_outline,
                color: Color(0xFF0A1931), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text('Add Player',
                      style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  isDense: true,
                  items: available
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final player = available.firstWhere((p) => p.id == id);
                    onSelected(player);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────── MOTM / MOTS Dropdown ───────────────────
  Widget _playerDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final allPlayers = _allSelectedPlayers();

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Select'),
          isExpanded: true,
          isDense: true,
          items: [
            const DropdownMenuItem<String>(
                value: null, child: Text('None')),
            ...allPlayers.map(
              (p) => DropdownMenuItem(
                value: p.id,
                child: Text('${p.name} (${_playerSection(p.id)})',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<PlayerModel> _allSelectedPlayers() {
    final Set<String> seen = {};
    final List<PlayerModel> result = [];
    for (final map in [_t1Batting, _t2Bowling, _t2Batting, _t1Bowling]) {
      for (final e in map.values) {
        final p = e['player'] as PlayerModel;
        if (!seen.contains(p.id)) {
          seen.add(p.id);
          result.add(p);
        }
      }
    }
    return result;
  }

  String _playerSection(String playerId) {
    if (_t1Batting.containsKey(playerId)) return '${widget.team1Name} bat';
    if (_t2Bowling.containsKey(playerId)) return '${widget.team2Name} bowl';
    if (_t2Batting.containsKey(playerId)) return '${widget.team2Name} bat';
    if (_t1Bowling.containsKey(playerId)) return '${widget.team1Name} bowl';
    return '';
  }

  // ─────────────────── Save ───────────────────
  Future<void> _submit() async {
    if (_t1Batting.isEmpty &&
        _t2Batting.isEmpty &&
        _t1Bowling.isEmpty &&
        _t2Bowling.isEmpty) {
      _snack('Please add at least one player stats');
      return;
    }

    setState(() => _saving = true);

    try {
      final futures = <Future>[];

      void saveSection(
          Map<String, Map<String, dynamic>> section, bool isBatting) {
        section.forEach((playerId, data) {
          final value = data['value'] as int;
          futures.add(_statsService.savePlayerStats(
            tournamentId: widget.tournamentId,
            matchId: widget.matchId,
            playerId: playerId,
            runs: isBatting ? value : 0,
            wickets: isBatting ? 0 : value,
            played: true,
            isMom: _motmPlayerId == playerId,
            isMots: _motsPlayerId == playerId,
          ));
        });
      }

      saveSection(_t1Batting, true);
      saveSection(_t2Batting, true);
      saveSection(_t1Bowling, false);
      saveSection(_t2Bowling, false);

      await Future.wait(futures);

      // Mark match completed
      await _matchService.markCompleted(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        motmPlayerId: _motmPlayerId,
        motsPlayerId: _motsPlayerId,
      );

      // ── Points Engine trigger ──
      final updatedCount = await PointsEngine().calculateMatchPoints(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      );

      if (mounted) {
        _snack('Stats saved! Points calculated for $updatedCount users.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _snack('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

// ─────────────────── Number Field Widget ───────────────────
class _NumberField extends StatefulWidget {
  final int initialValue;
  final String label;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.initialValue,
    required this.label,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue == 0 ? '' : widget.initialValue.toString(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(fontSize: 10),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        isDense: true,
      ),
      onChanged: (s) {
        final v = int.tryParse(s) ?? 0;
        widget.onChanged(v);
      },
    );
  }
}