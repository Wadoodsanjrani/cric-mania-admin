import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_helper.dart';

/// Prize Ad Screen — Admin
/// Firestore path: tournaments/{tid}/prize_ad/config
/// Ye ad user app mein "Play & Win Prizes" ke roop mein dikhega.
class PrizeAdScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const PrizeAdScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<PrizeAdScreen> createState() => _PrizeAdScreenState();
}

class _PrizeAdScreenState extends State<PrizeAdScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _isActive = true;
  String _imageBase64 = '';

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .collection('prize_ad')
          .doc('config');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final doc = await _docRef.get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        _titleCtrl.text = d['title'] ?? '';
        _descCtrl.text = d['description'] ?? '';
        _imageBase64 = d['imageBase64'] ?? '';
        _isActive = d['isActive'] ?? true;
      } else {
        _titleCtrl.text = 'Play & Win Prizes — Absolutely Free';
        _descCtrl.text =
            'Participate in Cric Mania Pro League for FREE and win amazing physical prizes!\n\n'
            '• No entry fee\n'
            '• 100% skill-based\n'
            '• Physical gifts only\n\n'
            'Submit your squad before the deadline and climb the leaderboard.';
      }
    } catch (e) {
      debugPrint('Prize ad load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      final b64 = await ImageHelper.fileToBase64(
        file,
        maxWidth: 1200,
        quality: 75,
      );
      setState(() => _imageBase64 = b64);
      _snack('Image selected. Save karein.');
    } catch (e) {
      _snack('Image failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title required');
      return;
    }

    setState(() => _saving = true);
    try {
      await _docRef.set({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageBase64': _imageBase64,
        'isActive': _isActive,
        'tournamentName': widget.tournamentName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
      _snack('Prize Ad saved!');
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeImage() async {
    setState(() => _imageBase64 = '');
    _snack('Image removed. Save karein.');
  }

  Uint8List? _safeDecode(String b64) {
    if (b64.isEmpty) return null;
    try {
      String clean = b64;
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (e) {
      return null;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Prize Ad',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard,
                          color: Colors.amber, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PLAY & WIN PRIZES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.tournamentName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Active toggle
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isActive ? Icons.visibility : Icons.visibility_off,
                        color: _isActive
                            ? const Color(0xFF00C9A7)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Show in User App',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0A1931),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ON karne par user app mein ad dikhega',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        activeColor: const Color(0xFF00C9A7),
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                const Text(
                  'Title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Play & Win Prizes — Absolutely Free',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Prize details likhein...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                const SizedBox(height: 16),

                // Image
                const Text(
                  'Prize Image (Gallery se)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 8),

                if (_safeDecode(_imageBase64) != null)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.memory(
                            _safeDecode(_imageBase64)!,
                            fit: BoxFit.cover,
                            height: 220,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => Container(
                              height: 220,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey, size: 50),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed:
                                    _uploading ? null : _pickImage,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Change'),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade300,
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _removeImage,
                                icon: const Icon(Icons.delete,
                                    size: 16, color: Colors.red),
                                label: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _uploading ? null : _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0A1931)
                              .withValues(alpha: 0.2),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: _uploading
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 50,
                                      color: const Color(0xFF0A1931)
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Gallery se image select karein',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1931),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Prize Ad',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }
}