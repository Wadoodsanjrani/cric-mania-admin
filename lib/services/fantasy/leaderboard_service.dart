import 'package:cloud_firestore/cloud_firestore.dart';

/// Leaderboard Service
/// Firestore path: tournaments/{tournamentId}/leaderboard/{userId}
/// Document: {
///   userId, userName, totalPoints,
///   matchPoints: { matchId: points },
///   rank, previousRank, fpodCount,
///   lastUpdatedAt
/// }
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _leaderboard(
    String tournamentId,
  ) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('leaderboard');

  /// Stream leaderboard sorted by rank
  Stream<List<Map<String, dynamic>>> streamLeaderboard(
    String tournamentId,
  ) {
    return _leaderboard(tournamentId)
        .orderBy('rank', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Get single user's entry
  Future<Map<String, dynamic>?> getUserEntry(
    String tournamentId,
    String userId,
  ) async {
    final doc = await _leaderboard(tournamentId).doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Update / create user's total points and per-match points
  Future<void> updateUserPoints({
    required String tournamentId,
    required String userId,
    required String userName,
    required String matchId,
    required int matchPoints,
  }) async {
    final docRef = _leaderboard(tournamentId).doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'userId': userId,
        'userName': userName,
        'totalPoints': matchPoints,
        'matchPoints': {matchId: matchPoints},
        'rank': 0,
        'previousRank': 0,
        'fpodCount': 0,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      final data = doc.data()!;
      final Map<String, dynamic> mp =
          Map<String, dynamic>.from(data['matchPoints'] ?? {});
      final int oldPoints = (mp[matchId] ?? 0) as int;
      final int newTotal =
          ((data['totalPoints'] ?? 0) as int) - oldPoints + matchPoints;
      mp[matchId] = matchPoints;
      await docRef.update({
        'totalPoints': newTotal,
        'matchPoints': mp,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  /// Save a full sorted leaderboard (called after tie-breaker calculation)
  /// Entries: List of { userId, userName, totalPoints, rank, previousRank, fpodCount, matchPoints }
  Future<void> saveFullLeaderboard({
    required String tournamentId,
    required List<Map<String, dynamic>> entries,
  }) async {
    final batch = _firestore.batch();
    for (final e in entries) {
      final ref = _leaderboard(tournamentId).doc(e['userId'] as String);
      batch.set(ref, {
        ...e,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Delete entire leaderboard (reset)
  Future<void> clearLeaderboard(String tournamentId) async {
    final docs = await _leaderboard(tournamentId).get();
    for (final d in docs.docs) {
      await d.reference.delete();
    }
  }
}