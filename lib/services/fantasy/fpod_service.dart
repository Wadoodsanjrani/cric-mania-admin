import 'package:cloud_firestore/cloud_firestore.dart';

/// FPOD Service — Pro League Participant of the Match (PLPM)
/// Firestore path: tournaments/{tid}/fpod/{matchId}
class FpodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _fpod(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('fpod');

  // ─────────────────────────────────────────────────────────
  // RECALCULATE FPOD FOR A MATCH
  // Har match ke baad top performer (sirf is match ke points)
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> recalculateForMatch({
    required String tournamentId,
    required String matchId,
  }) async {
    // 1. Match doc se matchNumber nikaalo
    final matchDoc = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId)
        .get();

    if (!matchDoc.exists) return null;
    final matchData = matchDoc.data()!;
    final matchNumber = (matchData['matchNumber'] ?? '').toString();

    // 2. Leaderboard se sab active users lo
    final lbSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('leaderboard')
        .where('status', isEqualTo: 'active')
        .get();

    if (lbSnap.docs.isEmpty) return null;

    // 3. Har user ke is match ke points nikaalo
    final entries = <Map<String, dynamic>>[];
    for (final doc in lbSnap.docs) {
      final data = doc.data();
      final matchPoints = data['matchPoints'];
      int thisMatchPoints = 0;
      if (matchPoints is Map) {
        thisMatchPoints = (matchPoints[matchId] ?? 0) as int;
      }
      entries.add({
        'id': doc.id,
        'userId': data['userId'] ?? doc.id,
        'userName': data['userName'] ?? '',
        'userPhotoUrl': data['userPhotoUrl'] ?? '',
        'userCity': data['userCity'] ?? '',
        'thisMatchPoints': thisMatchPoints,
      });
    }

    // 4. Sirf woh users jinhone is match mein points kamaye
    final participants =
        entries.where((e) => (e['thisMatchPoints'] as int) > 0).toList();

    if (participants.isEmpty) return null;

    // 5. Sort: is match ke points DESC → name ASC
    participants.sort((a, b) {
      final ap = a['thisMatchPoints'] as int;
      final bp = b['thisMatchPoints'] as int;
      if (ap != bp) return bp.compareTo(ap);
      final an = (a['userName'] ?? '') as String;
      final bn = (b['userName'] ?? '') as String;
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });

    // 6. Top performer save karo (doc ID = matchId)
    final top = participants.first;
    final fpodData = {
      'userId': top['userId'],
      'userName': top['userName'],
      'userPhotoUrl': top['userPhotoUrl'],
      'userCity': top['userCity'],
      'points': top['thisMatchPoints'],
      'matchId': matchId,
      'matchNumber': matchNumber,
      'calculatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await _fpod(tournamentId).doc(matchId).set(fpodData);
    return fpodData;
  }

  // ─────────────────────────────────────────────────────────
  // GET FPOD FOR A MATCH
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getFpodForMatch(
    String tournamentId,
    String matchId,
  ) async {
    final doc = await _fpod(tournamentId).doc(matchId).get();
    return doc.exists ? doc.data() : null;
  }

  // ─────────────────────────────────────────────────────────
  // STREAM LATEST FPOD (sabse recent match ka)
  // ─────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>?> streamLatestFpod(String tournamentId) {
    return _fpod(tournamentId)
        .orderBy('calculatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return {'id': snap.docs.first.id, ...snap.docs.first.data()};
    });
  }

  // ─────────────────────────────────────────────────────────
  // STREAM ALL FPOD (HISTORY) — match-wise
  // ─────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamAllFpod(String tournamentId) {
    return _fpod(tournamentId)
        .orderBy('calculatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // ─────────────────────────────────────────────────────────
  // DELETE FPOD FOR A MATCH
  // ─────────────────────────────────────────────────────────
  Future<void> deleteForMatch(String tournamentId, String matchId) async {
    await _fpod(tournamentId).doc(matchId).delete();
  }
}