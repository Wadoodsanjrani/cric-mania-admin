import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddNewsScreen extends StatefulWidget {
  final String? newsId;
  const AddNewsScreen({super.key, this.newsId});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _selectedImage;
  String? _existingImageBase64;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.newsId != null) _loadNews();
  }

  Future<void> _loadNews() async {
    var doc = await FirebaseFirestore.instance
        .collection('news')
        .doc(widget.newsId)
        .get();
    var data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      setState(() {
        _titleCtrl.text = data['title'] ?? '';
        _descCtrl.text = data['desc'] ?? '';
        _existingImageBase64 = data['imageBase64'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title required')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageBase64 = _existingImageBase64;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      var data = {
        'title': _titleCtrl.text.trim(),
        'desc': _descCtrl.text.trim(),
        'imageBase64': imageBase64,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (widget.newsId != null) {
        await FirebaseFirestore.instance
            .collection('news')
            .doc(widget.newsId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('news').add(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: Text(
          widget.newsId == null ? 'Add News' : 'Edit News',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Full News',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Image:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : _existingImageBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(_existingImageBase64!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to choose from gallery'),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1931),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.newsId == null ? 'UPLOAD NEWS' : 'UPDATE NEWS',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}