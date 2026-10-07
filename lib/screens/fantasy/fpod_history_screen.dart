import 'package:flutter/material.dart';
import '../../services/fantasy/fpod_service.dart';

/// FPOD History Screen
class FpodHistoryScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const FpodHistoryScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<FpodHistoryScreen> createState() => _FpodHistoryScreenState();
}

class _FpodHistoryScreenState extends State<FpodHistoryScreen> {
  final _fpodService = FpodService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'FPOD History',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fpodService.streamAllFpod(widget.tournamentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final winners = snapshot.data ?? [];

          if (winners.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No FPOD history yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Winners will appear here after\nthe first match is completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(winners.length),
              const SizedBox(height: 16),
              ...winners.map((w) => _winnerCard(w)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _header(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1931).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
          const SizedBox(height: 8),
          const Text(
            'FPOD HISTORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.tournamentName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total Winners: $totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _winnerCard(Map<String, dynamic> data) {
    final userName = data['userName'] as String? ?? 'Player';
    final userCity = data['userCity'] as String? ?? '';
    final userPhotoUrl = data['userPhotoUrl'] as String? ?? '';
    final points = data['points'] ?? 0;
    final rank = data['rank'] ?? 1;
    final dateKey = data['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(userPhotoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1931).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDateKey(dateKey),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A1931),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1931),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userCity.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          userCity,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFC93C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rank #$rank',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String photoUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.person,
                size: 30,
                color: Colors.grey,
              ),
      ),
    );
  }

  String _formatDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return dateKey;

      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      return '$day ${months[month - 1]} $year';
    } catch (_) {
      return dateKey;
    }
  }
}