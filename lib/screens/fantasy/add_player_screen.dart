import 'package:flutter/material.dart';
import '../../services/fantasy/player_service.dart';

/// Add Player Screen — team ke andar naya player add karne ke liye
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

  String _role = 'Batter';
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
            // Team name context
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
            ),
            const SizedBox(height: 16),

            // Role selector — visual radio cards
            const Text(
              'Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _roleCard(
                    label: 'Batter',
                    icon: Icons.sports_cricket,
                    isSelected: _role == 'Batter',
                    onTap: () => setState(() => _role = 'Batter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleCard(
                    label: 'Bowler',
                    icon: Icons.sports_baseball,
                    isSelected: _role == 'Bowler',
                    onTap: () => setState(() => _role = 'Bowler'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

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
              label: Text(_saving ? 'Saving...' : 'Add Player'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: Ek hi screen se bar bar players add kar sakte hain. '
              'Save hone ke baad ye screen wapas khulegi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0A1931)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0A1931)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : const Color(0xFF0A1931),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF0A1931),
              ),
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
        role: _role,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameCtrl.text.trim()} add ho gaya!'),
            duration: const Duration(seconds: 2),
          ),
        );
        // Clear name, keep screen open for next player
        _nameCtrl.clear();
        setState(() => _saving = false);
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