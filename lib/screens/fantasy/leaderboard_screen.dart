import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_helper.dart';
import '../../services/fantasy/leaderboard_service.dart';
import '../../services/fantasy/sponsor_service.dart';

/// Leaderboard Screen
/// Shows sponsor banner, slots, corner logo, and ranked users
/// Long-press on banner/slots/logo to replace image (admin only)
class LeaderboardScreen extends StatefulWidget {
  final String tournamentId;
  const LeaderboardScreen({super.key, required this.tournamentId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _leaderboardService = LeaderboardService();
  final _sponsorService = SponsorService();
  final _picker = ImagePicker();
  bool _uploading = false;

  // ─── Pick & upload image ───
  Future<void> _pickAndUpload(String field) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      switch (field) {
        case 'banner':
          await _sponsorService.uploadBanner(widget.tournamentId, file);
          break;
        case 'slot1':
          await _sponsorService.uploadSlot(widget.tournamentId, file, 1);
          break;
        case 'slot2':
          await _sponsorService.uploadSlot(widget.tournamentId, file, 2);
          break;
        case 'slot3':
          await _sponsorService.uploadSlot(widget.tournamentId, file, 3);
          break;
        case 'corner':
          await _sponsorService.uploadCornerLogo(widget.tournamentId, file);
          break;
      }
      _snack('Image uploaded successfully');
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Remove image (with confirm) ───
  Future<void> _confirmRemove(String field, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $label?'),
        content: const Text('This will remove the image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _uploading = true);
    try {
      switch (field) {
        case 'banner':
          await _sponsorService.removeBanner(widget.tournamentId);
          break;
        case 'slot1':
          await _sponsorService.removeSlot(widget.tournamentId, 1);
          break;
        case 'slot2':
          await _sponsorService.removeSlot(widget.tournamentId, 2);
          break;
        case 'slot3':
          await _sponsorService.removeSlot(widget.tournamentId, 3);
          break;
        case 'corner':
          await _sponsorService.removeCornerLogo(widget.tournamentId);
          break;
      }
      _snack('$label removed');
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Bottom sheet with options ───
  void _showImageOptions(String field, String label, bool hasImage) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(field);
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemove(field, label);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SponsorConfig>(
      stream: _sponsorService.streamConfig(widget.tournamentId),
      builder: (context, sponsorSnap) {
        final config = sponsorSnap.data ?? SponsorConfig();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1931),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Leaderboard',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              // Corner logo
              if (config.hasCornerLogo)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: GestureDetector(
                    onLongPress: () => _showImageOptions(
                        'corner', 'Corner Logo', true),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _base64Image(
                          config.cornerLogoBase64,
                          icon: Icons.image_not_supported,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Banner
                  _bannerWidget(config),

                  const SizedBox(height: 12),

                  // 3 slots
                  _slotsRow(config),

                  const SizedBox(height: 24),

                  // Leaderboard header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events,
                            color: Color(0xFFD4AF37), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'LEADERBOARD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1931),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Leaderboard list
                  _leaderboardList(),
                ],
              ),

              // Uploading overlay
              if (_uploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Helper: base64 image widget ───
  Widget _base64Image(
    String base64String, {
    BoxFit fit = BoxFit.cover,
    IconData icon = Icons.business,
  }) {
    if (base64String.isEmpty) {
      return Center(
        child: Icon(
          icon,
          color: const Color(0xFF0A1931).withValues(alpha: 0.3),
          size: 24,
        ),
      );
    }
    return Image.memory(
      ImageHelper.base64ToBytes(base64String),
      fit: fit,
      errorBuilder: (_, _, _) => Center(
        child: Icon(
          icon,
          color: const Color(0xFF0A1931).withValues(alpha: 0.3),
          size: 24,
        ),
      ),
    );
  }

  // ─── Banner widget ───
  Widget _bannerWidget(SponsorConfig config) {
    return GestureDetector(
      onLongPress: () => _showImageOptions(
          'banner', 'Banner', config.hasBanner),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: config.hasBanner
              ? _base64Image(config.bannerBase64)
              : _bannerPlaceholder(),
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, color: Colors.white54, size: 40),
            SizedBox(height: 6),
            Text(
              'Sponsor Banner',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slots row ───
  Widget _slotsRow(SponsorConfig config) {
    return Row(
      children: [
        Expanded(child: _slotWidget(config.slot1Base64, 'slot1', 1)),
        const SizedBox(width: 8),
        Expanded(child: _slotWidget(config.slot2Base64, 'slot2', 2)),
        const SizedBox(width: 8),
        Expanded(child: _slotWidget(config.slot3Base64, 'slot3', 3)),
      ],
    );
  }

  Widget _slotWidget(String base64String, String field, int number) {
    final has = base64String.isNotEmpty;
    return GestureDetector(
      onLongPress: () => _showImageOptions(field, 'Slot $number', has),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: has
              ? _base64Image(base64String)
              : _slotPlaceholder(number),
        ),
      ),
    );
  }

  Widget _slotPlaceholder(int number) {
    return Container(
      color: const Color(0xFFEDF1F7),
      child: Center(
        child: Icon(
          Icons.business,
          color: const Color(0xFF0A1931).withValues(alpha: 0.3),
          size: 24,
        ),
      ),
    );
  }

  // ─── Leaderboard list ───
  Widget _leaderboardList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _leaderboardService.streamActiveLeaderboard(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.people_outline, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No participants yet',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Leaderboard will show here once\nusers submit their squads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: users.asMap().entries.map((entry) {
            return _leaderboardRow(
              rank: entry.value['rank'] ?? entry.key + 1,
              userName: entry.value['userName'] ?? 'User',
              points: entry.value['totalPoints'] ?? 0,
              city: entry.value['userCity'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  // ─── Single leaderboard row ───
  Widget _leaderboardRow({
    required int rank,
    required String userName,
    required int points,
    required String city,
  }) {
    // Top 3 get special colors
    Color? cardColor;
    Color? borderColor;
    String? medalEmoji;

    if (rank == 1) {
      cardColor = const Color(0xFFFFF9E6);
      borderColor = const Color(0xFFD4AF37);
      medalEmoji = '🥇';
    } else if (rank == 2) {
      cardColor = const Color(0xFFF5F5F5);
      borderColor = const Color(0xFFB0B0B0);
      medalEmoji = '🥈';
    } else if (rank == 3) {
      cardColor = const Color(0xFFFDF3E7);
      borderColor = const Color(0xFFCD7F32);
      medalEmoji = '🥉';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? borderColor!.withValues(alpha: 0.15)
                  : const Color(0xFF0A1931).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Text(
                      medalEmoji!,
                      style: const TextStyle(fontSize: 20),
                    )
                  : Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1931),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        rank <= 3 ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xFF0A1931),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (city.isNotEmpty)
                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? borderColor : const Color(0xFF0A1931),
                ),
              ),
              const Text(
                'points',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}