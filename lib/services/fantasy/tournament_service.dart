import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/tournament_model.dart';

/// Tournament Service
/// Firestore path: tournaments/{tournamentId}
class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _firestore.collection('tournaments');

  /// Real-time stream of all tournaments (newest first)
  Stream<List<TournamentModel>> streamAll() {
    return _tournaments
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get single tournament stream
  Stream<TournamentModel?> streamOne(String tournamentId) {
    return _tournaments.doc(tournamentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TournamentModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// Create new tournament — returns new doc id
  Future<String> createTournament({
    required String name,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime deadline,
    required String createdBy,
  }) async {
    final docRef = await _tournaments.add({
      'name': name,
      'format': format,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'deadline': Timestamp.fromDate(deadline),
      'status': 'draft',
      'winnerUserId': null,
      'winnerUserName': null,
      'winnerDeclaredAt': null,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'createdBy': createdBy,
    });
    return docRef.id;
  }

  /// Update tournament status
  Future<void> updateStatus(String tournamentId, String status) async {
    await _tournaments.doc(tournamentId).update({'status': status});
  }

  /// Update tournament (generic fields)
  Future<void> updateTournament(
    String tournamentId,
    Map<String, dynamic> data,
  ) async {
    await _tournaments.doc(tournamentId).update(data);
  }

  /// Declare winner
  Future<void> declareWinner({
    required String tournamentId,
    required String winnerUserId,
    required String winnerUserName,
  }) async {
    await _tournaments.doc(tournamentId).update({
      'status': 'completed',
      'winnerUserId': winnerUserId,
      'winnerUserName': winnerUserName,
      'winnerDeclaredAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete tournament (cascade subcollections manually delete karne padenge — Firestore auto-delete nahi karta)
  Future<void> deleteTournament(String tournamentId) async {
    // Subcollections: teams, matches, squads, leaderboard
    final subs = ['teams', 'matches', 'squads', 'leaderboard'];
    for (final sub in subs) {
      final docs =
          await _tournaments.doc(tournamentId).collection(sub).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
    await _tournaments.doc(tournamentId).delete();
  }
}