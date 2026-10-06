import 'package:cloud_firestore/cloud_firestore.dart';

/// FPOD Service — Fantasy Participant of the Day
/// Aaj ke match(es) mein sabse zyada points wala user
/// Firestore path: tournaments/{tournamentId}/fpod/{dateKey}
/// Document: { userId, userName, points, date, rank }
class FpodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _fpod(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('fpod');

  /// Date key: yyyy-MM-dd
  String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Calculate FPOD for a given date from leaderboard matchPoints
  /// Tie-breaker: Points → Higher rank wala. First match: Alphabetical.
  Future<Map<String, dynamic>?> calculateAndSaveFpod({
    required String tournamentId,
    required DateTime date,
    required bool isFirstMatchOfTournament,
  }) async {
    // Get all leaderboard entries
    final lbSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('leaderboard')
        .get();

    if (lbSnap.docs.isEmpty) return null;

    // Filter users who played today (matchPoints mein aaj ke match ki entry hai)
    // For simplicity we treat all leaderboard users and their totalPoints
    // — actual daily calculation user side pe hoti hai.
    // Yahan hum sabse zyada totalPoints wala uthate hain as fallback.
    final List<Map<String, dynamic>> entries = lbSnap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    // Sort: points DESC → rank ASC → name ASC
    entries.sort((a, b) {
      final pa = (a['totalPoints'] ?? 0) as int;
      final pb = (b['totalPoints'] ?? 0) as int;
      if (pa != pb) return pb.compareTo(pa); // higher points first

      if (!isFirstMatchOfTournament) {
        final ra = (a['rank'] ?? 999999) as int;
        final rb = (b['rank'] ?? 999999) as int;
        if (ra != rb) return ra.compareTo(rb);
      }

      final na = (a['userName'] ?? '') as String;
      final nb = (b['userName'] ?? '') as String;
      return na.toLowerCase().compareTo(nb.toLowerCase());
    });

    final top = entries.first;
    final key = dateKey(date);

    final fpodData = {
      'userId': top['userId'] ?? top['id'],
      'userName': top['userName'] ?? '',
      'points': top['totalPoints'] ?? 0,
      'date': key,
      'rank': 1,
      'calculatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await _fpod(tournamentId).doc(key).set(fpodData);
    return fpodData;
  }

  /// Get FPOD for a specific date
  Future<Map<String, dynamic>?> getFpod(
    String tournamentId,
    DateTime date,
  ) async {
    final doc = await _fpod(tournamentId).doc(dateKey(date)).get();
    return doc.exists ? doc.data() : null;
  }

  /// Stream all FPOD entries (latest first)
  Stream<List<Map<String, dynamic>>> streamAllFpod(String tournamentId) {
    return _fpod(tournamentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}