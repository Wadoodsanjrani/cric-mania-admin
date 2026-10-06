import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/match_model.dart';

/// Match Service
/// Firestore path: tournaments/{tournamentId}/matches/{matchId}
class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _matches(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches');

  /// Stream all matches
  Stream<List<MatchModel>> streamMatches(String tournamentId) {
    return _matches(tournamentId)
        .orderBy('matchDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get single match
  Future<MatchModel?> getMatch(
    String tournamentId,
    String matchId,
  ) async {
    final doc = await _matches(tournamentId).doc(matchId).get();
    if (!doc.exists) return null;
    return MatchModel.fromMap(doc.id, doc.data()!);
  }

  /// Add match
  Future<String> addMatch({
    required String tournamentId,
    required String team1Id,
    required String team2Id,
    required String team1Name,
    required String team2Name,
    required DateTime matchDate,
  }) async {
    final docRef = await _matches(tournamentId).add({
      'team1Id': team1Id,
      'team2Id': team2Id,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'matchDate': Timestamp.fromDate(matchDate),
      'status': 'scheduled',
      'motmPlayerId': null,
      'motsPlayerId': null,
      'completedAt': null,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    return docRef.id;
  }

  /// Mark match completed + set MOTM
  Future<void> markCompleted({
    required String tournamentId,
    required String matchId,
    String? motmPlayerId,
    String? motsPlayerId,
  }) async {
    await _matches(tournamentId).doc(matchId).update({
      'status': 'completed',
      'motmPlayerId': motmPlayerId,
      'motsPlayerId': motsPlayerId,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete match (stats bhi delete karo)
  Future<void> deleteMatch(
    String tournamentId,
    String matchId,
  ) async {
    final stats =
        await _matches(tournamentId).doc(matchId).collection('stats').get();
    for (final s in stats.docs) {
      await s.reference.delete();
    }
    await _matches(tournamentId).doc(matchId).delete();
  }
}