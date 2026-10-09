import 'package:cloud_firestore/cloud_firestore.dart';
import 'points_engine.dart';

/// Stats Service
/// Firestore path: tournaments/{tournamentId}/matches/{matchId}/stats/{playerId}
/// Document: { runs, wickets, played, isMom, isMots, updatedAt }
///
/// IMPORTANT: savePlayerStats ab points engine bhi trigger karta hai
/// taake leaderboard automatically update ho jaye.
class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _stats(
    String tournamentId,
    String matchId,
  ) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .collection('stats');

  /// Stats save karo, phir points engine chalao, phir leaderboard update karo.
  Future<void> savePlayerStats({
    required String tournamentId,
    required String matchId,
    required String playerId,
    required int runs,
    required int wickets,
    bool played = true,
    bool isMom = false,
    bool isMots = false,
  }) async {
    // 1. Stats Firestore mein save karo
    await _stats(tournamentId, matchId).doc(playerId).set({
      'runs': runs,
      'wickets': wickets,
      'played': played,
      'isMom': isMom,
      'isMots': isMots,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    // 2. Points calculate karo + leaderboard update karo
    try {
      final engine = PointsEngine();
      await engine.calculateMatchPoints(
        tournamentId: tournamentId,
        matchId: matchId,
      );
    } catch (e) {
      // ignore: avoid_print
      print('PointsEngine error: $e');
    }
  }

  Future<Map<String, Map<String, dynamic>>> getMatchStats(
    String tournamentId,
    String matchId,
  ) async {
    final snap = await _stats(tournamentId, matchId).get();
    final Map<String, Map<String, dynamic>> result = {};
    for (final doc in snap.docs) {
      result[doc.id] = doc.data();
    }
    return result;
  }

  Future<Map<String, dynamic>?> getPlayerStats({
    required String tournamentId,
    required String matchId,
    required String playerId,
  }) async {
    final doc = await _stats(tournamentId, matchId).doc(playerId).get();
    return doc.exists ? doc.data() : null;
  }

  Stream<Map<String, Map<String, dynamic>>> streamMatchStats(
    String tournamentId,
    String matchId,
  ) {
    return _stats(tournamentId, matchId).snapshots().map((snap) {
      final Map<String, Map<String, dynamic>> result = {};
      for (final doc in snap.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    });
  }

  Future<bool> hasStatsForMatch(
    String tournamentId,
    String matchId,
  ) async {
    final snap = await _stats(tournamentId, matchId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> deleteMatchStats(
    String tournamentId,
    String matchId,
  ) async {
    final snap = await _stats(tournamentId, matchId).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}