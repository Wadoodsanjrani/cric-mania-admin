import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/fantasy/tournament_model.dart';
import '../../services/image_helper.dart';
import '../../services/fantasy/tournament_service.dart';
import '../../services/fantasy/sponsor_service.dart';

/// Winner Declare Screen
/// Admin declares Top 1 / Top 2 / Top 3 winners from the leaderboard.
class WinnerDeclareScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const WinnerDeclareScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<WinnerDeclareScreen> createState() => _WinnerDeclareScreenState();
}

class _WinnerDeclareScreenState extends State<WinnerDeclareScreen> {
  final _tournamentService = TournamentService();
  final _sponsorService = SponsorService();
  final _firestore = FirebaseFirestore.instance;

  int _selectedCount = 3;
  bool _declaring = false;
  bool _uploadingSponsor = false;

  // ── Load top 3 leaderboard entries ──
  Stream<List<Map<String, dynamic>>> _topThreeStream() {
    return _firestore
        .collection('tournaments')
        .doc(widget.tournamentId)
        .collection('leaderboard')
        .where('status', isEqualTo: 'active')
        .orderBy('rank', descending: false)
        .limit(3)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── Load sponsor config ──
  Stream<Map<String, dynamic>?> _sponsorStream() {
    return _firestore
        .collection('tournaments')
        .doc(widget.tournamentId)
        .collection('sponsors')
        .doc('config')
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Declare Winners',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<TournamentModel?>(
        stream: _tournamentService.streamOne(widget.tournamentId),
        builder: (context, tournSnap) {
          if (!tournSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tournament = tournSnap.data!;

          if (tournament.isWinnerDeclared) {
            return _readOnlyView(tournament);
          }

          return _selectionView(tournament);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SELECTION VIEW
  // ═══════════════════════════════════════════════════════════
  Widget _selectionView(TournamentModel tournament) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _topThreeStream(),
      builder: (context, lbSnap) {
        if (lbSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final top3 = lbSnap.data ?? [];

        if (top3.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No active participants found.\n'
                'Winners cannot be declared yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 16),
            _radioSelector(),
            const SizedBox(height: 16),
            _sponsorUploadCard(),
            const SizedBox(height: 16),
            _winnerCard(
              tier: 'Diamond',
              emoji: '💎',
              rank: 1,
              data: top3[0],
              show: _selectedCount >= 1,
            ),
            if (_selectedCount >= 2 && top3.length >= 2)
              _winnerCard(
                tier: 'Platinum',
                emoji: '🥇',
                rank: 2,
                data: top3[1],
                show: true,
              ),
            if (_selectedCount >= 3 && top3.length >= 3)
              _winnerCard(
                tier: 'Gold',
                emoji: '🥉',
                rank: 3,
                data: top3[2],
                show: true,
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Once declared, this action cannot be undone. '
                      'Please review carefully before confirming.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1931),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _declaring
                  ? null
                  : () => _confirmDeclare(tournament, top3),
              icon: _declaring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.emoji_events),
              label: Text(
                _declaring ? 'Declaring...' : 'Declare Winners',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // READ-ONLY VIEW
  // ═══════════════════════════════════════════════════════════
  Widget _readOnlyView(TournamentModel tournament) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'WINNERS DECLARED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tournament.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tournament.winnerUserId != null)
          _declaredCard(
            tier: 'Diamond',
            emoji: '💎',
            rank: 1,
            userId: tournament.winnerUserId!,
            userName: tournament.winnerUserName ?? '',
          ),
        if (tournament.hasRunnerUp)
          _declaredCard(
            tier: 'Platinum',
            emoji: '🥇',
            rank: 2,
            userId: tournament.runnerUpUserId!,
            userName: tournament.runnerUpUserName ?? '',
          ),
        if (tournament.hasThirdPlace)
          _declaredCard(
            tier: 'Gold',
            emoji: '🥉',
            rank: 3,
            userId: tournament.thirdPlaceUserId!,
            userName: tournament.thirdPlaceUserName ?? '',
          ),
        const SizedBox(height: 16),
        if (tournament.winnerDeclaredAt != null)
          Center(
            child: Text(
              'Declared on: ${_formatDate(tournament.winnerDeclaredAt!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
          const SizedBox(height: 8),
          const Text(
            'DECLARE WINNERS',
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
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RADIO SELECTOR
  // ═══════════════════════════════════════════════════════════
  Widget _radioSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How many winners to declare?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _radioOption(
              value: 1,
              title: 'Only Winner (💎 Diamond)',
            ),
            _radioOption(
              value: 2,
              title: 'Top 2 (💎 Diamond + 🥇 Platinum)',
            ),
            _radioOption(
              value: 3,
              title: 'Top 3 (💎 Diamond + 🥇 Platinum + 🥉 Gold)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioOption({required int value, required String title}) {
    final selected = _selectedCount == value;
    return InkWell(
      onTap: () => setState(() => _selectedCount = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFF0A1931)
                  : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helper: base64 image widget
  // ═══════════════════════════════════════════════════════════
  Widget _base64Image(
    String base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    IconData fallbackIcon = Icons.business,
    double fallbackSize = 20,
  }) {
    if (base64String.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Icon(fallbackIcon,
            color: Colors.grey, size: fallbackSize),
      );
    }
    return Image.memory(
      ImageHelper.base64ToBytes(base64String),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: height,
        child: Icon(fallbackIcon,
            color: Colors.grey, size: fallbackSize),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SPONSOR UPLOAD CARD
  // ═══════════════════════════════════════════════════════════
  Widget _sponsorUploadCard() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _sponsorStream(),
      builder: (context, snap) {
        final config = snap.data;
        final logoBase64 = config?['cornerLogoBase64'] as String?;

        return Card(
          child: ListTile(
            leading: logoBase64 != null && logoBase64.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _base64Image(
                      logoBase64,
                      width: 48,
                      height: 48,
                    ),
                  )
                : _sponsorPlaceholder(),
            title: const Text(
              'Winner Card Sponsor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              logoBase64 != null && logoBase64.isNotEmpty
                  ? 'Tap to change sponsor logo'
                  : 'Tap to upload sponsor logo',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _uploadingSponsor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload, color: Color(0xFF0A1931)),
            onTap:
                _uploadingSponsor ? null : () => _pickAndUploadSponsor(),
          ),
        );
      },
    );
  }

  Widget _sponsorPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.business, color: Colors.grey),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WINNER CARD (preview)
  // ═══════════════════════════════════════════════════════════
  Widget _winnerCard({
    required String tier,
    required String emoji,
    required int rank,
    required Map<String, dynamic> data,
    required bool show,
  }) {
    if (!show) return const SizedBox.shrink();

    final gradient = _tierGradient(tier);
    final userName = data['userName'] as String? ?? 'Unknown';
    final userCity = data['userCity'] as String? ?? '';
    final userPhotoUrl = data['userPhotoUrl'] as String?;
    final totalPoints = data['totalPoints'] ?? 0;
    final userRank = data['rank'] ?? rank;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _sponsorStream(),
      builder: (context, snap) {
        final logoBase64 = snap.data?['cornerLogoBase64'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          tier.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFF0A1931),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#$rank',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1931),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _avatar(userPhotoUrl, tier),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1931),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (userCity.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Color(0xFF0A1931)),
                          const SizedBox(width: 4),
                          Text(
                            userCity,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0A1931),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statChip(Icons.star, '$totalPoints pts'),
                        const SizedBox(width: 12),
                        _statChip(Icons.leaderboard, 'Rank #$userRank'),
                      ],
                    ),
                  ],
                ),
              ),
              if (logoBase64 != null && logoBase64.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _base64Image(
                        logoBase64,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DECLARED CARD (read-only)
  // ═══════════════════════════════════════════════════════════
  Widget _declaredCard({
    required String tier,
    required String emoji,
    required int rank,
    required String userId,
    required String userName,
  }) {
    final gradient = _tierGradient(tier);

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('leaderboard')
          .doc(userId)
          .get(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final userCity = data?['userCity'] as String? ?? '';
        final userPhotoUrl = data?['userPhotoUrl'] as String?;
        final totalPoints = data?['totalPoints'] ?? 0;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _sponsorStream(),
          builder: (context, sponsorSnap) {
            final logoBase64 = sponsorSnap.data?['cornerLogoBase64'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              tier.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Color(0xFF0A1931),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _avatar(userPhotoUrl, tier),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1931),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (userCity.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Color(0xFF0A1931)),
                              const SizedBox(width: 4),
                              Text(
                                userCity,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0A1931),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        _statChip(Icons.star, '$totalPoints pts'),
                      ],
                    ),
                  ),
                  if (logoBase64 != null && logoBase64.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _base64Image(
                            logoBase64,
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  LinearGradient _tierGradient(String tier) {
    switch (tier) {
      case 'Diamond':
        return const LinearGradient(
          colors: [Color(0xFFB9F2FF), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Platinum':
        return const LinearGradient(
          colors: [Color(0xFFE5E4E2), Color(0xFFA7A9AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Gold':
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
        );
    }
  }

  Widget _avatar(String? url, String tier) {
    final borderColor = tier == 'Diamond'
        ? const Color(0xFF00B4D8)
        : tier == 'Platinum'
            ? const Color(0xFFA7A9AC)
            : const Color(0xFFFFA500);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 4),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey,
                ),
              )
            : const Icon(Icons.person, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0A1931)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A1931),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> _pickAndUploadSponsor() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _uploadingSponsor = true);

      await _sponsorService.uploadCornerLogo(
        widget.tournamentId,
        File(picked.path),
      );

      if (mounted) {
        _snack('Sponsor logo uploaded!');
      }
    } catch (e) {
      if (mounted) {
        _snack('Upload failed: $e');
      }
    } finally {
      if (mounted) setState(() => _uploadingSponsor = false);
    }
  }

  Future<void> _confirmDeclare(
    TournamentModel tournament,
    List<Map<String, dynamic>> top3,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Declaration'),
        content: Text(
          'You are about to declare Top $_selectedCount winner(s).\n\n'
          'This action cannot be undone.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1931),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _declaring = true);

    try {
      await _tournamentService.declareWinners(
        tournamentId: widget.tournamentId,
        winnersCount: _selectedCount,
      );

      if (mounted) {
        _snack('Winners declared successfully!');
      }
    } catch (e) {
      if (mounted) {
        _snack('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _declaring = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}