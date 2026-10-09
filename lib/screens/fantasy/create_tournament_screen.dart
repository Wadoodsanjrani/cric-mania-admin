import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/fantasy/tournament_service.dart';

/// Create Tournament Screen
/// Creates tournament with status: 'active' directly (no draft)
/// Submission lock is controlled manually from tournament detail screen
class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _service = TournamentService();

  String _format = 'T20';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
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
        title: const Text(
          'Create Tournament',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── INFO BANNER ───
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1931).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0A1931).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: const Color(0xFF0A1931).withValues(alpha: 0.6),
                      size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tournament direct active hoga. Squad submission lock/unlock aap tournament detail screen se control kar sakte hain.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── NAME ───
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tournament Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.emoji_events),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter tournament name' : null,
            ),
            const SizedBox(height: 16),

            // ─── FORMAT ───
            DropdownButtonFormField<String>(
              initialValue: _format,
              decoration: const InputDecoration(
                labelText: 'Format',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_cricket),
              ),
              items: const [
                DropdownMenuItem(value: 'T20', child: Text('T20')),
                DropdownMenuItem(value: 'ODI', child: Text('ODI')),
              ],
              onChanged: (v) => setState(() => _format = v ?? 'T20'),
            ),
            const SizedBox(height: 16),

            // ─── START DATE ───
            _dateField(
              label: 'Start Date',
              value: _startDate,
              onPick: (d) => setState(() => _startDate = d),
            ),
            const SizedBox(height: 16),

            // ─── END DATE ───
            _dateField(
              label: 'End Date',
              value: _endDate,
              onPick: (d) => setState(() => _endDate = d),
            ),
            const SizedBox(height: 32),

            // ─── SAVE BUTTON ───
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
              label: Text(_saving ? 'Saving...' : 'SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DATE FIELD ───
  Widget _dateField({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPick,
    bool withTime = false,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null) return;
        if (withTime && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
          );
          if (time != null) {
            onPick(DateTime(
                date.year, date.month, date.day, time.hour, time.minute));
            return;
          }
        }
        onPick(DateTime(date.year, date.month, date.day));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          withTime
              ? '${_fmt(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
              : _fmt(value),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ─── SUBMIT ───
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await _service.createTournament(
        name: _nameCtrl.text.trim(),
        format: _format,
        startDate: _startDate,
        endDate: _endDate,
        deadline: _endDate, // deadline not used anymore, but keeping for backward compat
        createdBy: user?.email ?? 'admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament created and active!'),
            backgroundColor: Color(0xFF00C9A7),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}