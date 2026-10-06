import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/fantasy/fpod_service.dart';
import '../../services/fantasy/sponsor_service.dart';

/// FPOD Screen — Fantasy Participant of the Day (sponsored)
class FpodScreen extends StatefulWidget {
  final String tournamentId;
  const FpodScreen({super.key, required this.tournamentId});

  @override
  State<FpodScreen> createState() => _FpodScreenState();
}

class _FpodScreenState extends State<FpodScreen> {
  final _fpodService = FpodService();
  final _sponsorService = SponsorService();
  final _picker = ImagePicker();
  bool _uploading = false;

  // ─── Upload FPOD sponsor logo ───
  Future<void> _pickSponsorLogo() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      await _sponsorService.uploadFpodSponsorLogo(widget.tournamentId, file);
      _snack('Sponsor logo uploaded');
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Remove sponsor logo ───
  Future<void> _confirmRemoveLogo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Sponsor Logo?'),
        content: const Text('This will remove the logo.'),
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
      await _sponsorService.removeFpodSponsorLogo(widget.tournamentId);
      _snack('Logo removed');
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Edit sponsor text ───
  Future<void> _editTexts(
    String currentName,
    String currentTitle,
  ) async {
    final nameCtrl = TextEditingController(text: currentName);
    final titleCtrl = TextEditingController(text: currentTitle);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sponsor Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Sponsor Name',
                hintText: 'e.g. Zero Lifestyle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Card Title',
                hintText: 'e.g. Player of the Day',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _uploading = true);
    try {
      await _sponsorService.saveFpodTexts(
        tournamentId: widget.tournamentId,
        sponsorName: nameCtrl.text.trim(),
        cardTitle: titleCtrl.text.trim(),
      );
      _snack('Sponsor info saved');
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Show image options bottom sheet ───
  void _showLogoOptions(bool hasImage) {
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
                _pickSponsorLogo();
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Logo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemoveLogo();
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
        final title = config.fpodCardTitle.isEmpty
            ? 'Player of the Day'
            : config.fpodCardTitle;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1931),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              // Edit texts button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Sponsor Info',
                onPressed: () => _editTexts(
                  config.fpodSponsorName,
                  config.fpodCardTitle,
                ),
              ),
              // Corner logo
              if (config.hasCornerLogo)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        config.cornerLogoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 18,
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
                padding: const EdgeInsets.all(16),
                children: [
                  // Sponsor section
                  _sponsorSection(config),

                  const SizedBox(height: 24),

                  // FPOD card
                  _fpodCard(config),
                ],
              ),

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

  // ─── Sponsor section (top) ───
  Widget _sponsorSection(SponsorConfig config) {
    final hasLogo = config.fpodSponsorLogoUrl.isNotEmpty;
    final hasName = config.fpodSponsorName.isNotEmpty;

    if (!hasLogo && !hasName) {
      // Placeholder — prompt admin to set up
      return GestureDetector(
        onLongPress: () => _showLogoOptions(false),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF0A1931).withValues(alpha: 0.1),
              style: BorderStyle.solid,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.card_giftcard, color: Color(0xFF0A1931)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sponsor this award',
                  style: TextStyle(
                    color: Color(0xFF0A1931),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showLogoOptions(hasLogo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0A1931),
              const Color(0xFF0A1931).withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1931).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasLogo
                    ? Image.network(
                        config.fpodSponsorLogoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.business,
                          color: Color(0xFF0A1931),
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        color: Color(0xFF0A1931),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presented by',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasName ? config.fpodSponsorName : 'Sponsor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FPOD Card ───
  Widget _fpodCard(SponsorConfig config) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _fpodService.streamLatestFpod(widget.tournamentId),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (data == null) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_off_outlined,
                    size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No FPOD yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'The daily top performer will appear\nhere after the first match.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final userName = data['userName'] ?? 'Player';
        final userCity = data['userCity'] ?? '';
        final userPhotoUrl = data['userPhotoUrl'] ?? '';
        final points = data['points'] ?? 0;
        final date = data['date'] ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF9E6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile picture
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFC93C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor:
                        const Color(0xFF0A1931).withValues(alpha: 0.1),
                    backgroundImage:
                        userPhotoUrl.isNotEmpty
                            ? NetworkImage(userPhotoUrl)
                            : null,
                    child: userPhotoUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: Color(0xFF0A1931),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
                textAlign: TextAlign.center,
              ),

              // City
              if (userCity.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      userCity,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Points badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFC93C)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Date
              if (date.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}