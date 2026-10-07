import 'package:cloud_firestore/cloud_firestore.dart';

/// FPOD Service — Fantasy Participant of the Day
/// Firestore path: tournaments/{tid}/fpod/{dateKey}
class FpodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _fpod(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('fpod');

  String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────
  // RECALCULATE FPOD FOR A DATE
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> recalculateForDate({
    required String tournamentId,
    required DateTime date,
  }) async {
    final lbSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('leaderboard')
        .where('status', isEqualTo: 'active')
        .get();

    if (lbSnap.docs.isEmpty) return null;

    final entries = lbSnap.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();

    // Sort: Points DESC → Rank ASC → Name ASC
    entries.sort((a, b) {
      final ap = (a['totalPoints'] ?? 0) as int;
      final bp = (b['totalPoints'] ?? 0) as int;
      if (ap != bp) return bp.compareTo(ap);

      final ar = (a['rank'] ?? 999999) as int;
      final br = (b['rank'] ?? 999999) as int;
      if (ar != br) return ar.compareTo(br);

      final an = (a['userName'] ?? '') as String;
      final bn = (b['userName'] ?? '') as String;
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });

    final top = entries.first;
    final key = dateKey(date);

    final fpodData = {
      'userId': top['userId'] ?? top['id'],
      'userName': top['userName'] ?? '',
      'userPhotoUrl': top['userPhotoUrl'] ?? '',
      'userCity': top['userCity'] ?? '',
      'points': top['totalPoints'] ?? 0,
      'rank': top['rank'] ?? 1,
      'date': key,
      'calculatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await _fpod(tournamentId).doc(key).set(fpodData);
    return fpodData;
  }

  // ─────────────────────────────────────────────────────────
  // GET FPOD FOR A SPECIFIC DATE
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getFpod(
    String tournamentId,
    DateTime date,
  ) async {
    final doc = await _fpod(tournamentId).doc(dateKey(date)).get();
    return doc.exists ? doc.data() : null;
  }

  // ─────────────────────────────────────────────────────────
  // STREAM LATEST FPOD
  // ─────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>?> streamLatestFpod(String tournamentId) {
    return _fpod(tournamentId)
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return {'id': snap.docs.first.id, ...snap.docs.first.data()};
    });
  }

  // ─────────────────────────────────────────────────────────
  // STREAM ALL FPOD (HISTORY)
  // ─────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamAllFpod(String tournamentId) {
    return _fpod(tournamentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // ─────────────────────────────────────────────────────────
  // DELETE FPOD FOR A DATE
  // ─────────────────────────────────────────────────────────
  Future<void> deleteForDate(String tournamentId, DateTime date) async {
    await _fpod(tournamentId).doc(dateKey(date)).delete();
  }
}