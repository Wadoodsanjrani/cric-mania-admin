import 'package:cloud_firestore/cloud_firestore.dart';

/// Leaderboard Service
/// Firestore path: tournaments/{tid}/leaderboard/{userId}
/// Document: {
///   userId, userName, totalPoints,
///   matchPoints: { matchId: points },
///   rank, previousRank, fpodCount,
///   status: 'active' | 'eliminated',
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

  /// Stream full leaderboard (all users, sorted by rank)
  Stream<List<Map<String, dynamic>>> streamLeaderboard(
    String tournamentId,
  ) {
    return _leaderboard(tournamentId)
        .orderBy('rank', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Stream only active users (excludes eliminated)
  Stream<List<Map<String, dynamic>>> streamActiveLeaderboard(
    String tournamentId,
  ) {
    return _leaderboard(tournamentId)
        .where('status', isEqualTo: 'active')
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
        'status': 'active',
        'eliminatedAt': null,
        'eliminatedAfterMatchId': null,
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

  /// Recalculate ranks for all active users
  /// Tie-breaker: Points DESC → Previous Rank ASC → Name ASC
  Future<void> recalculateRanks(String tournamentId) async {
    // 1. Get all active users
    final snap = await _leaderboard(tournamentId)
        .where('status', isEqualTo: 'active')
        .get();

    if (snap.docs.isEmpty) return;

    // 2. Convert to list of maps
    final entries = snap.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .toList();

    // 3. Sort: Points DESC → Previous Rank ASC → Name ASC
    entries.sort((a, b) {
      final ap = (a['totalPoints'] ?? 0) as int;
      final bp = (b['totalPoints'] ?? 0) as int;
      if (ap != bp) return bp.compareTo(ap);

      final ar = (a['previousRank'] ?? 999999) as int;
      final br = (b['previousRank'] ?? 999999) as int;
      if (ar != br) return ar.compareTo(br);

      final an = (a['userName'] ?? '') as String;
      final bn = (b['userName'] ?? '') as String;
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });

    // 4. Assign new ranks (batch update)
    const batchSize = 500;
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = entries.skip(i).take(batchSize).toList();

      for (var j = 0; j < chunk.length; j++) {
        final entry = chunk[j];
        final newRank = i + j + 1;
        final oldRank = (entry['rank'] ?? 0) as int;
        final ref = _leaderboard(tournamentId).doc(entry['id'] as String);
        batch.update(ref, {
          'previousRank': oldRank == 0 ? newRank : oldRank,
          'rank': newRank,
        });
      }

      await batch.commit();
    }
  }

  /// Save a full sorted leaderboard (bulk update)
  Future<void> saveFullLeaderboard({
    required String tournamentId,
    required List<Map<String, dynamic>> entries,
  }) async {
    const batchSize = 500;
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = entries.skip(i).take(batchSize);
      for (final e in chunk) {
        final ref = _leaderboard(tournamentId).doc(e['userId'] as String);
        batch.set(
          ref,
          {
            ...e,
            'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  /// Delete entire leaderboard (reset)
  Future<void> clearLeaderboard(String tournamentId) async {
    final docs = await _leaderboard(tournamentId).get();
    const batchSize = 500;
    for (var i = 0; i < docs.docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = docs.docs.skip(i).take(batchSize);
      for (final d in chunk) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}