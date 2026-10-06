import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/player_model.dart';

/// Player Service
/// Firestore path: tournaments/{tournamentId}/teams/{teamId}/players/{playerId}
class PlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _players(
    String tournamentId,
    String teamId,
  ) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(teamId)
          .collection('players');

  /// Stream players of a team
  Stream<List<PlayerModel>> streamPlayers(
    String tournamentId,
    String teamId,
  ) {
    return _players(tournamentId, teamId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlayerModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Add player
  Future<String> addPlayer({
    required String tournamentId,
    required String teamId,
    required String name,
    required String role,
  }) async {
    final docRef = await _players(tournamentId, teamId).add({
      'name': name,
      'role': role,
      'teamId': teamId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    return docRef.id;
  }

  /// Update player
  Future<void> updatePlayer({
    required String tournamentId,
    required String teamId,
    required String playerId,
    required String name,
    required String role,
  }) async {
    await _players(tournamentId, teamId).doc(playerId).update({
      'name': name,
      'role': role,
    });
  }

  /// Delete player
  Future<void> deletePlayer({
    required String tournamentId,
    required String teamId,
    required String playerId,
  }) async {
    await _players(tournamentId, teamId).doc(playerId).delete();
  }

  /// Get all players across all teams in a tournament
  Future<List<PlayerModel>> getAllPlayersInTournament(
    String tournamentId,
  ) async {
    final teamsSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('teams')
        .get();

    final List<PlayerModel> all = [];
    for (final teamDoc in teamsSnap.docs) {
      final playersSnap = await teamDoc.reference.collection('players').get();
      for (final p in playersSnap.docs) {
        all.add(PlayerModel.fromMap(p.id, p.data()));
      }
    }
    return all;
  }
}