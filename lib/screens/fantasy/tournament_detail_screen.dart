import 'package:flutter/material.dart';
import '../../models/fantasy/tournament_model.dart';
import '../../services/fantasy/tournament_service.dart';
import '../../services/fantasy/team_service.dart';
import '../../services/fantasy/match_service.dart';
import 'add_team_screen.dart';
import 'team_detail_screen.dart';
import 'add_match_screen.dart';
import 'match_stats_screen.dart';
import 'leaderboard_screen.dart';
import 'fpod_screen.dart';
import 'elimination_screen.dart';
import 'winner_declare_screen.dart';

/// Tournament Detail Screen — Teams, Matches, Info, Rules tabs
class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final _tournamentService = TournamentService();
  final _teamService = TeamService();
  final _matchService = MatchService();
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TournamentModel?>(
      stream: _tournamentService.streamOne(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final t = snapshot.data;
        if (t == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A1931),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A1931),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                t.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.leaderboard),
                  tooltip: 'Leaderboard',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(
                        tournamentId: widget.tournamentId,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star),
                  tooltip: 'Player of the Day',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FpodScreen(
                        tournamentId: widget.tournamentId,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  tooltip: 'Eliminations',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EliminationScreen(
                        tournamentId: widget.tournamentId,
                      ),
                    ),
                  ),
                ),
                // ── Winner Declare Action ──
                IconButton(
                  icon: const Icon(Icons.emoji_events),
                  tooltip: 'Declare Winners',
                  onPressed: t.status == 'draft'
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WinnerDeclareScreen(
                                tournamentId: widget.tournamentId,
                                tournamentName: t.name,
                              ),
                            ),
                          ),
                ),
                IconButton(
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  tooltip: 'Delete Tournament',
                  onPressed: _deleting ? null : () => _confirmDelete(t),
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Teams', icon: Icon(Icons.groups)),
                  Tab(text: 'Matches', icon: Icon(Icons.sports_cricket)),
                  Tab(text: 'Info', icon: Icon(Icons.info_outline)),
                  Tab(text: 'Rules', icon: Icon(Icons.tune)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _TeamsTab(
                  tournamentId: widget.tournamentId,
                  service: _teamService,
                ),
                _MatchesTab(
                  tournamentId: widget.tournamentId,
                  service: _matchService,
                  onMatchTap: (m) => _openMatchStats(m),
                ),
                _OverviewTab(tournament: t),
                const _RulesTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMatchStats(dynamic match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchStatsScreen(
          tournamentId: widget.tournamentId,
          matchId: match.id,
          team1Id: match.team1Id,
          team1Name: match.team1Name,
          team2Id: match.team2Id,
          team2Name: match.team2Name,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(TournamentModel t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tournament?'),
        content: Text(
          'Are you sure you want to delete "${t.name}"?\n\n'
          'This will also delete all Teams, Players, Matches, and Stats.\n'
          'This action cannot be undone.',
        ),
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

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _tournamentService.deleteTournament(widget.tournamentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament deleted!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _deleting = false);
      }
    }
  }
}

// ─────────────────── Teams Tab ───────────────────
class _TeamsTab extends StatelessWidget {
  final String tournamentId;
  final TeamService service;
  const _TeamsTab({required this.tournamentId, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder(
        stream: service.streamTeams(tournamentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teams = snapshot.data!;
          if (teams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No teams yet.\nTap + button below to add a team.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: teams.length,
            itemBuilder: (context, i) {
              final team = teams[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF0A1931).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        team.flag.isEmpty ? '🏏' : team.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamDetailScreen(
                        tournamentId: tournamentId,
                        teamId: team.id,
                        teamName: team.name,
                        teamFlag: team.flag,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTeamScreen(tournamentId: tournamentId),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────── Matches Tab ───────────────────
class _MatchesTab extends StatelessWidget {
  final String tournamentId;
  final MatchService service;
  final Function(dynamic) onMatchTap;
  const _MatchesTab({
    required this.tournamentId,
    required this.service,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder(
        stream: service.streamMatches(tournamentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = snapshot.data!;
          if (matches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_cricket_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No matches yet.\nTap + button below to add a match.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final m = matches[i];
              final isCompleted = m.status == 'completed';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : const Color(0xFF0A1931).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sports_cricket,
                      color: isCompleted
                          ? Colors.green
                          : const Color(0xFF0A1931),
                    ),
                  ),
                  title: Text('${m.team1Name} vs ${m.team2Name}'),
                  subtitle: Text(
                    '${m.matchDate.day}/${m.matchDate.month}/${m.matchDate.year}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'Done' : 'Scheduled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                  onTap: () => onMatchTap(m),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMatchScreen(tournamentId: tournamentId),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────── Overview Tab ───────────────────
class _OverviewTab extends StatelessWidget {
  final TournamentModel tournament;
  const _OverviewTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row('Name', tournament.name),
        _row('Format', tournament.format),
        _row('Status', tournament.status),
        _row('Start', _fmt(tournament.startDate)),
        _row('End', _fmt(tournament.endDate)),
        _row('Deadline', _fmt(tournament.deadline)),
        if (tournament.winnerUserName != null)
          _row('Winner', tournament.winnerUserName!),
        if (tournament.runnerUpUserName != null)
          _row('Runner-Up', tournament.runnerUpUserName!),
        if (tournament.thirdPlaceUserName != null)
          _row('Third Place', tournament.thirdPlaceUserName!),
        _row('Created By', tournament.createdBy),
      ],
    );
  }

  Widget _row(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A1931),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────── Rules Tab ───────────────────
class _RulesTab extends StatelessWidget {
  const _RulesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('T20 Batting'),
        _rule('25–40 runs', '1 pt'),
        _rule('41–59 runs', '2 pts'),
        _rule('60–74 runs', '3 pts'),
        _rule('75+ runs', '4 pts'),

        const SizedBox(height: 16),
        _sectionHeader('T20 Bowling'),
        _rule('1 wicket', '1 pt'),
        _rule('2–3 wickets', '2 pts'),
        _rule('4 wickets', '3 pts'),
        _rule('5+ wickets', '4 pts'),

        const SizedBox(height: 16),
        _sectionHeader('ODI Batting'),
        _rule('30–45 runs', '1 pt'),
        _rule('46–60 runs', '2 pts'),
        _rule('61–79 runs', '3 pts'),
        _rule('80–99 runs', '4 pts'),
        _rule('100+ runs', '5 pts'),

        const SizedBox(height: 16),
        _sectionHeader('ODI Bowling'),
        _rule('1–2 wickets', '1 pt'),
        _rule('3 wickets', '2 pts'),
        _rule('4 wickets', '3 pts'),
        _rule('5 wickets', '4 pts'),
        _rule('6+ wickets', '5 pts'),

        const SizedBox(height: 20),
        _sectionHeader('Special Awards'),
        _specialRule('Man of the Match', '+1 pt'),
        _specialRule('Man of the Series', '+5 pts'),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1931),
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _rule(String label, String pts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1931).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pts,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1931),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialRule(String label, String pts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFD4AF37), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A1931),
              ),
            ),
          ),
          Text(
            pts,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }
}