import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/team_model.dart';

/// Team Service
/// Firestore path: tournaments/{tournamentId}/teams/{teamId}
class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _teams(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams');

  /// Stream all teams in a tournament
  Stream<List<TeamModel>> streamTeams(String tournamentId) {
    return _teams(tournamentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get single team
  Future<TeamModel?> getTeam(String tournamentId, String teamId) async {
    final doc = await _teams(tournamentId).doc(teamId).get();
    if (!doc.exists) return null;
    return TeamModel.fromMap(doc.id, doc.data()!);
  }

  /// Add team — returns new team id
  Future<String> addTeam({
    required String tournamentId,
    required String name,
    required String flag,
  }) async {
    final docRef = await _teams(tournamentId).add({
      'name': name,
      'flag': flag,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    return docRef.id;
  }

  /// Update team
  Future<void> updateTeam({
    required String tournamentId,
    required String teamId,
    required String name,
    required String flag,
  }) async {
    await _teams(tournamentId).doc(teamId).update({
      'name': name,
      'flag': flag,
    });
  }

  /// Delete team (players bhi delete karo)
  Future<void> deleteTeam(String tournamentId, String teamId) async {
    final players =
        await _teams(tournamentId).doc(teamId).collection('players').get();
    for (final p in players.docs) {
      await p.reference.delete();
    }
    await _teams(tournamentId).doc(teamId).delete();
  }
}