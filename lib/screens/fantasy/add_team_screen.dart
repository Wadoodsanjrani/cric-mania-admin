import 'package:flutter/material.dart';
import '../../services/fantasy/team_service.dart';

/// Add Team Screen
/// Tournament ke andar nayi team add karne ke liye
class AddTeamScreen extends StatefulWidget {
  final String tournamentId;
  const AddTeamScreen({super.key, required this.tournamentId});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _flagCtrl = TextEditingController();
  final _service = TeamService();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _flagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text(
          'Add Team',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'e.g. Karachi Kings',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Team ka naam daalein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _flagCtrl,
              decoration: const InputDecoration(
                labelText: 'Flag / Emoji (optional)',
                hintText: 'e.g. 🇵🇰 or 🔵 or KK',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Aap emoji paste kar sakte hain (Ctrl+V) — jaise 🏏 ya 🇵🇰',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1931),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Saving...' : 'Add Team'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _service.addTeam(
        tournamentId: widget.tournamentId,
        name: _nameCtrl.text.trim(),
        flag: _flagCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team add ho gayi!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}