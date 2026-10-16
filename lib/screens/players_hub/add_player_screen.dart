import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_helper.dart';

/// Admin — Add / Edit Player Screen
class AddPlayerScreen extends StatefulWidget {
  final String? playerId;
  final Map<String, dynamic>? existingData;

  const AddPlayerScreen({
    super.key,
    this.playerId,
    this.existingData,
  });

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  static const Color primary = Color(0xFF0A1931);
  static const Color bg = Color(0xFFF5F7FA);

  final _nameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _bornYearCtrl = TextEditingController();
  final _bornCityCtrl = TextEditingController();
  final _debutYearCtrl = TextEditingController();
  final _battingStyleCtrl = TextEditingController();
  final _bowlingStyleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _role = 'Batter';
  File? _photoFile;
  String _photoBase64 = '';

  final List<Map<String, dynamic>> _formatSections = [];

  // ✅ NAYA: BF add kiya
  final List<String> _battingFields = [
    'Matches', 'Innings', 'NO', 'Runs', 'HS', 'BF', 'Avg', 'SR',
    '100s', '50s', '6s', '4s',
  ];

  final List<String> _bowlingFields = [
    'Matches', 'Innings', 'Wickets', 'Econ', 'SR', 'BBI', 'BBM', 'Avg',
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fullNameCtrl.dispose();
    _bornYearCtrl.dispose();
    _bornCityCtrl.dispose();
    _debutYearCtrl.dispose();
    _battingStyleCtrl.dispose();
    _bowlingStyleCtrl.dispose();
    _descCtrl.dispose();

    for (final section in _formatSections) {
      (section['nameCtrl'] as TextEditingController).dispose();
      final batting = section['batting'] as Map<String, TextEditingController>;
      final bowling = section['bowling'] as Map<String, TextEditingController>;
      for (final c in batting.values) c.dispose();
      for (final c in bowling.values) c.dispose();
    }

    super.dispose();
  }

  void _loadExistingData() {
    final data = widget.existingData;
    if (data == null) return;

    _nameCtrl.text = (data['name'] ?? '').toString();
    _fullNameCtrl.text = (data['fullName'] ?? '').toString();
    _bornYearCtrl.text = (data['bornYear'] ?? '').toString();
    _bornCityCtrl.text = (data['bornCity'] ?? '').toString();
    _debutYearCtrl.text = (data['debutYear'] ?? '').toString();
    _battingStyleCtrl.text = (data['battingStyle'] ?? '').toString();
    _bowlingStyleCtrl.text = (data['bowlingStyle'] ?? '').toString();
    _descCtrl.text = (data['description'] ?? '').toString();
    _role = (data['role'] ?? 'Batter').toString();
    _photoBase64 = (data['photoBase64'] ?? '').toString();

    final stats = data['stats'] as Map<String, dynamic>?;
    if (stats != null) {
      stats.forEach((formatName, formatData) {
        if (formatData is! Map) return;

        final section = _createFormatSection(formatName);

        final batting = formatData['batting'];
        if (batting is Map) {
          final battingCtrl =
              section['batting'] as Map<String, TextEditingController>;
          batting.forEach((key, value) {
            if (battingCtrl.containsKey(key)) {
              battingCtrl[key]!.text = value.toString();
            }
          });
        }

        final bowling = formatData['bowling'];
        if (bowling is Map) {
          final bowlingCtrl =
              section['bowling'] as Map<String, TextEditingController>;
          bowling.forEach((key, value) {
            if (bowlingCtrl.containsKey(key)) {
              bowlingCtrl[key]!.text = value.toString();
            }
          });
        }

        _formatSections.add(section);
      });
    }
  }

  Map<String, dynamic> _createFormatSection([String? name]) {
    return {
      'nameCtrl': TextEditingController(text: name ?? ''),
      'batting': {
        for (final f in _battingFields) f: TextEditingController(),
      },
      'bowling': {
        for (final f in _bowlingFields) f: TextEditingController(),
      },
    };
  }

  void _addFormatSection() {
    setState(() {
      _formatSections.add(_createFormatSection());
    });
  }

  void _removeFormatSection(int index) {
    setState(() {
      final section = _formatSections.removeAt(index);
      (section['nameCtrl'] as TextEditingController).dispose();
      final batting =
          section['batting'] as Map<String, TextEditingController>;
      final bowling =
          section['bowling'] as Map<String, TextEditingController>;
      for (final c in batting.values) c.dispose();
      for (final c in bowling.values) c.dispose();
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    setState(() => _photoFile = File(picked.path));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Name is required', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      String photoBase64 = _photoBase64;
      if (_photoFile != null) {
        photoBase64 = await ImageHelper.fileToBase64(_photoFile!);
        if (!ImageHelper.isSafeForFirestore(photoBase64)) {
          throw Exception('Image too large. Choose a smaller one.');
        }
      }

      final Map<String, dynamic> statsMap = {};
      for (final section in _formatSections) {
        final formatName =
            (section['nameCtrl'] as TextEditingController).text.trim();
        if (formatName.isEmpty) continue;

        final battingCtrl =
            section['batting'] as Map<String, TextEditingController>;
        final bowlingCtrl =
            section['bowling'] as Map<String, TextEditingController>;

        final battingData = <String, dynamic>{};
        for (final field in _battingFields) {
          final txt = battingCtrl[field]?.text.trim() ?? '';
          if (txt.isNotEmpty) battingData[field] = txt;
        }

        final bowlingData = <String, dynamic>{};
        for (final field in _bowlingFields) {
          final txt = bowlingCtrl[field]?.text.trim() ?? '';
          if (txt.isNotEmpty) bowlingData[field] = txt;
        }

        if (battingData.isNotEmpty || bowlingData.isNotEmpty) {
          statsMap[formatName] = {
            'batting': battingData,
            'bowling': bowlingData,
          };
        }
      }

      final payload = {
        'name': _nameCtrl.text.trim(),
        'fullName': _fullNameCtrl.text.trim(),
        'photoBase64': photoBase64,
        'bornYear': _bornYearCtrl.text.trim(),
        'bornCity': _bornCityCtrl.text.trim(),
        'debutYear': _debutYearCtrl.text.trim(),
        'battingStyle': _battingStyleCtrl.text.trim(),
        'bowlingStyle': _bowlingStyleCtrl.text.trim(),
        'role': _role,
        'description': _descCtrl.text.trim(),
        'stats': statsMap,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.playerId == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('player_hub').add(payload);
      } else {
        await _firestore
            .collection('player_hub')
            .doc(widget.playerId)
            .set(payload, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Player saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _snack('❌ $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 8 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.playerId == null ? 'Add Player' : 'Edit Player',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 2),
                ),
                child: ClipOval(
                  child: _photoFile != null
                      ? Image.file(_photoFile!, fit: BoxFit.cover)
                      : _photoBase64.isNotEmpty
                          ? Image.memory(
                              _safeBase64Decode(_photoBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey,
                            ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Tap to upload photo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),

          _section('Basic Info'),
          _textField(_nameCtrl, 'Name *'),
          _textField(_fullNameCtrl, 'Full Name'),
          _textField(_bornYearCtrl, 'Born Year', number: true),
          _textField(_bornCityCtrl, 'Born City'),
          _textField(_debutYearCtrl, 'Debut Year', number: true),
          _textField(_battingStyleCtrl, 'Batting Style'),
          _textField(_bowlingStyleCtrl, 'Bowling Style'),

          const SizedBox(height: 8),
          const Text(
            'Role',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: const [
              DropdownMenuItem(value: 'Batter', child: Text('Batter')),
              DropdownMenuItem(value: 'Bowler', child: Text('Bowler')),
              DropdownMenuItem(
                  value: 'All Rounder', child: Text('All Rounder')),
              DropdownMenuItem(
                  value: 'Wicket Keeper', child: Text('Wicket Keeper')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),

          const SizedBox(height: 12),
          _textField(_descCtrl, 'Description', maxLines: 3),

          const SizedBox(height: 24),

          _section('Formats'),

          ..._formatSections
              .asMap()
              .entries
              .map((e) => _formatSectionWidget(e.key, e.value)),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('+ ADD FORMAT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _addFormatSection,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saving ? null : _save,
              child: Text(
                widget.playerId == null ? 'SAVE PLAYER' : 'UPDATE PLAYER',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _formatSectionWidget(int index, Map<String, dynamic> section) {
    final nameCtrl = section['nameCtrl'] as TextEditingController;
    final batting = section['batting'] as Map<String, TextEditingController>;
    final bowling = section['bowling'] as Map<String, TextEditingController>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Format Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeFormatSection(index),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            '🏏 Batting',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ..._battingFields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TextField(
                controller: batting[field],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: field,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          const Text(
            '🎯 Bowling',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ..._bowlingFields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TextField(
                controller: bowling[field],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: field,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: primary,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Uint8List _safeBase64Decode(String b64) {
    try {
      String cleaned = b64;
      if (cleaned.contains(',')) cleaned = cleaned.split(',').last;
      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0);
    }
  }
}