import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/fantasy/match_model.dart';
import '../../services/fantasy/elimination_service.dart';
import '../../services/fantasy/match_service.dart';

/// Elimination Screen — admin controls elimination rounds
class EliminationScreen extends StatefulWidget {
  final String tournamentId;
  const EliminationScreen({super.key, required this.tournamentId});

  @override
  State<EliminationScreen> createState() => _EliminationScreenState();
}

class _EliminationScreenState extends State<EliminationScreen> {
  final _elimService = EliminationService();
  final _matchService = MatchService();

  int _activeCount = 0;
  bool _loadingCount = true;

  String? _selectedMatchId;
  String? _selectedMatchName;
  final _keepCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadActiveCount();
  }

  @override
  void dispose() {
    _keepCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveCount() async {
    setState(() => _loadingCount = true);
    try {
      final count = await _elimService.getActiveCount(widget.tournamentId);
      if (mounted) {
        setState(() {
          _activeCount = count;
          _loadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Eliminations',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active count card
          _activeCountCard(),

          const SizedBox(height: 20),

          // Elimination form
          _eliminationForm(),

          const SizedBox(height: 24),

          // History
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'ELIMINATION HISTORY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1931),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _historyList(),
        ],
      ),
    );
  }

  // ─── Active count card ───
  Widget _activeCountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1931), Color(0xFF1B3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1931).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Active Participants',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingCount)
            const SizedBox(
              height: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Text(
              '$_activeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'in this tournament',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Elimination form ───
  Widget _eliminationForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Elimination',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep top N participants. All others are eliminated.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // Match selector
          StreamBuilder<List<MatchModel>>(
            stream: _matchService.streamMatches(widget.tournamentId),
            builder: (context, snapshot) {
              final matches = snapshot.data ?? [];

              return DropdownButtonFormField<String>(
                initialValue: _selectedMatchId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'After Match',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_cricket),
                ),
                items: matches.map((m) {
                  final name =
                      '${m.team1Name} vs ${m.team2Name}';
                  return DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final match =
                      matches.firstWhere((m) => m.id == v);
                  setState(() {
                    _selectedMatchId = v;
                    _selectedMatchName =
                        '${match.team1Name} vs ${match.team2Name}';
                  });
                },
              );
            },
          ),

          const SizedBox(height: 14),

          // Keep count
          TextField(
            controller: _keepCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Keep Top',
              hintText: 'e.g. 50000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.star),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Live calculation
          _keepCalculation(),

          const SizedBox(height: 16),

          // Warning
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action is permanent. Eliminated users cannot be brought back.',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1931),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : _confirmAndEliminate,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.filter_alt),
              label: Text(_saving ? 'Processing...' : 'Eliminate Now'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Keep calculation text ───
  Widget _keepCalculation() {
    final keep = int.tryParse(_keepCtrl.text.trim()) ?? 0;

    if (keep <= 0 || _activeCount == 0) {
      return const SizedBox.shrink();
    }

    if (keep >= _activeCount) {
      return const Text(
        'Keep count must be less than active participants.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final willEliminate = _activeCount - keep;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1931).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF0A1931), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Will keep $keep, eliminate $willEliminate',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0A1931),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirm & eliminate ───
  Future<void> _confirmAndEliminate() async {
    final keep = int.tryParse(_keepCtrl.text.trim()) ?? 0;

    if (_selectedMatchId == null) {
      _snack('Please select a match');
      return;
    }
    if (keep <= 0) {
      _snack('Please enter a valid keep count');
      return;
    }
    if (keep >= _activeCount) {
      _snack('Keep count must be less than $_activeCount');
      return;
    }

    final willEliminate = _activeCount - keep;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Elimination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('After: ${_selectedMatchName ?? '-'}'),
            const SizedBox(height: 6),
            Text('Keep: $keep participants'),
            const SizedBox(height: 6),
            Text('Eliminate: $willEliminate participants'),
            const SizedBox(height: 12),
            const Text(
              'This cannot be undone. Continue?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminate'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      final adminEmail =
          FirebaseAuth.instance.currentUser?.email ?? 'admin';

      final result = await _elimService.eliminate(
        tournamentId: widget.tournamentId,
        afterMatchId: _selectedMatchId!,
        afterMatchName: _selectedMatchName ?? '',
        keepTop: keep,
        performedBy: adminEmail,
      );

      _snack(
        'Eliminated ${result['eliminated']} participants. '
        '${result['kept']} remaining.',
      );

      _keepCtrl.clear();
      setState(() {
        _selectedMatchId = null;
        _selectedMatchName = null;
      });

      await _loadActiveCount();
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── History list ───
  Widget _historyList() {
    return StreamBuilder<List<EliminationRecord>>(
      stream: _elimService.streamHistory(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No eliminations yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: history.asMap().entries.map((entry) {
            final index = history.length - entry.key;
            final rec = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1931),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After: ${rec.afterMatchName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1931),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statChip(
                        Icons.check_circle,
                        Colors.green,
                        'Kept: ${rec.keptCount}',
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        Icons.cancel,
                        Colors.red,
                        'Out: ${rec.eliminatedCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fmtDateTime(rec.performedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year}  $hour:$min';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
}