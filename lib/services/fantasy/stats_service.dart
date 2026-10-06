import 'package:cloud_firestore/cloud_firestore.dart';

/// Stats Service
/// Firestore path: tournaments/{tournamentId}/matches/{matchId}/stats/{playerId}
/// Document: { runs, wickets, played, isMom, isMots, updatedAt }
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

  /// Save or update a single player's stats for a match
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
    await _stats(tournamentId, matchId).doc(playerId).set({
      'runs': runs,
      'wickets': wickets,
      'played': played,
      'isMom': isMom,
      'isMots': isMots,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  /// Get all stats for a match
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

  /// Get one player's stats
  Future<Map<String, dynamic>?> getPlayerStats({
    required String tournamentId,
    required String matchId,
    required String playerId,
  }) async {
    final doc = await _stats(tournamentId, matchId).doc(playerId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Stream single match's all stats
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

  /// Check if any stats exist for this match
  Future<bool> hasStatsForMatch(
    String tournamentId,
    String matchId,
  ) async {
    final snap = await _stats(tournamentId, matchId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Delete all stats for a match (for re-entry)
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