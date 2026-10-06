import 'package:flutter/material.dart';
import '../../models/fantasy/tournament_model.dart';
import '../../services/fantasy/tournament_service.dart';
import '../../services/fantasy/team_service.dart';
import '../../services/fantasy/match_service.dart';
import 'add_team_screen.dart';
import 'team_detail_screen.dart';
import 'add_match_screen.dart';

/// Tournament Detail Screen — Teams, Matches, Overview tabs
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
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A1931),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                t.name,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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
                  Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
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
                ),
                _OverviewTab(tournament: t),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(TournamentModel t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tournament?'),
        content: Text(
          'Kya aap "${t.name}" ko delete karna chahte hain?\n\n'
          '⚠️ Ye saare Teams, Players, Matches, aur Stats bhi delete ho jayenge.\n'
          'Ye action undo nahi ho sakta.',
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
          const SnackBar(content: Text('Tournament delete ho gaya!')),
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
                      'Koi team nahi hai.\nNeeche + button se team add karein.',
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
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    team.flag.isEmpty ? '🏏' : team.flag,
                    style: const TextStyle(fontSize: 28),
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
  const _MatchesTab({required this.tournamentId, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      'Koi match nahi hai.\nNeeche + button se match add karein.',
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
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.sports_cricket,
                      color: Color(0xFF0A1931)),
                  title: Text('${m.team1Name} vs ${m.team2Name}'),
                  subtitle: Text(
                    '${m.matchDate.day}/${m.matchDate.month}/${m.matchDate.year} • ${m.status}',
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
        _row('Created By', tournament.createdBy),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}