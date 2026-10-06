import 'package:flutter/material.dart';
import 'tournament_list_screen.dart';
import 'points_rules_screen.dart';

/// Fantasy Home — Dashboard se yahan aayenge
class FantasyHomeScreen extends StatelessWidget {
  const FantasyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text(
          'Fantasy League',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A1931).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏏 Fantasy League',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage tournaments, teams, players, matches, and sponsors.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'MANAGE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _tile(
            context,
            '🏆 Tournaments',
            'Create and manage tournaments',
            Icons.emoji_events,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TournamentListScreen(),
              ),
            ),
          ),

          _tile(
            context,
            '⚙️ Points Rules',
            'View T20/ODI scoring rules',
            Icons.tune,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PointsRulesScreen(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _infoCard(
            '1. Create Tournament',
            'Name, format (T20/ODI), dates, and deadline',
            Icons.emoji_events,
          ),
          _infoCard(
            '2. Add Teams & Players',
            'Add teams, then add their squad players',
            Icons.groups,
          ),
          _infoCard(
            '3. Add Matches',
            'Schedule matches between teams',
            Icons.sports_cricket,
          ),
          _infoCard(
            '4. Enter Stats',
            'After each match, enter player stats + MOTM',
            Icons.edit_note,
          ),
          _infoCard(
            '5. Points Auto-Calculated',
            'System updates leaderboard and FPOD automatically',
            Icons.calculate,
          ),
          _infoCard(
            '6. Declare Winner',
            'At the end, declare the tournament winner',
            Icons.workspace_premium,
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'CRIC MANIA FANTASY',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1931).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0A1931)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _infoCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0A1931)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}