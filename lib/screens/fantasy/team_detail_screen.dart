import 'package:flutter/material.dart';
import '../../services/fantasy/player_service.dart';
import 'add_player_screen.dart';

/// Team Detail Screen — team ke andar players list + add player
class TeamDetailScreen extends StatefulWidget {
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String teamFlag;

  const TeamDetailScreen({
    super.key,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    required this.teamFlag,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _service = PlayerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            if (widget.teamFlag.isNotEmpty)
              Text(widget.teamFlag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.teamName,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: _service.streamPlayers(widget.tournamentId, widget.teamId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final players = snapshot.data ?? [];
          if (players.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Koi player nahi hai.\nNeeche + button se player add karein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Batter aur Bowler alag alag dikhao
          final batters =
              players.where((p) => p.role == 'Batter').toList();
          final bowlers =
              players.where((p) => p.role == 'Bowler').toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (batters.isNotEmpty) ...[
                _sectionHeader(
                    'Batters (${batters.length})', Icons.sports_cricket),
                ...batters.map((p) => _playerTile(p)),
                const SizedBox(height: 16),
              ],
              if (bowlers.isNotEmpty) ...[
                _sectionHeader('Bowlers (${bowlers.length})', Icons.sports_baseball),
                ...bowlers.map((p) => _playerTile(p)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Player'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddPlayerScreen(
              tournamentId: widget.tournamentId,
              teamId: widget.teamId,
              teamName: widget.teamName,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0A1931)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTile(dynamic player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0A1931).withValues(alpha: 0.1),
          child: Icon(
            player.role == 'Batter'
                ? Icons.sports_cricket
                : Icons.sports_baseball,
            color: const Color(0xFF0A1931),
            size: 20,
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          player.role,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}