import 'package:flutter/material.dart';
import 'tournament_list_screen.dart';
import 'points_rules_screen.dart';

/// Fantasy Home — Dashboard se yahan aayenge
class FantasyHomeScreen extends StatelessWidget {
  const FantasyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'Tournaments, teams, players aur points — sab kuch yahan se manage karein.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Manage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _tile(
            context,
            '🏆 Tournaments',
            'Create tournaments, add teams, players aur matches',
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
            'T20/ODI batting & bowling rules edit karein',
            Icons.tune,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PointsRulesScreen(),
              ),
            ),
          ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0A1931).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF0A1931)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}