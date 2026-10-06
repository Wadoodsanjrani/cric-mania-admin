import 'package:flutter/material.dart';
import '../../services/fantasy/player_service.dart';

/// Add Player Screen — sirf naam, koi role nahi
class AddPlayerScreen extends StatefulWidget {
  final String tournamentId;
  final String teamId;
  final String teamName;

  const AddPlayerScreen({
    super.key,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _service = PlayerService();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Player',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1931).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Color(0xFF0A1931)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.teamName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                hintText: 'e.g. Babar Azam',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Player ka naam daalein';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
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
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Saving...' : 'Add Player'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: Ek hi screen se bar bar players add kar sakte hain. '
              'Save hone ke baad naam clear ho jayega, agla player daal dein.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
      await _service.addPlayer(
        tournamentId: widget.tournamentId,
        teamId: widget.teamId,
        name: _nameCtrl.text.trim(),
        role: 'Player',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameCtrl.text.trim()} add ho gaya!'),
            duration: const Duration(seconds: 2),
          ),
        );
        _nameCtrl.clear();
        setState(() => _saving = false);
        FocusScope.of(context).requestFocus(FocusNode());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }
}