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
  /// Directly creates with status: 'active' (no draft)
  /// submissionLocked: false (users can submit squads)
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
      'status': 'active',                    // ✅ direct active
      'submissionLocked': false,             // ✅ users can submit

      // Winner (1st place)
      'winnerUserId': null,
      'winnerUserName': null,

      // Runner-Up (2nd place)
      'runnerUpUserId': null,
      'runnerUpUserName': null,

      // Third Place (3rd place)
      'thirdPlaceUserId': null,
      'thirdPlaceUserName': null,

      // Count + timestamp
      'winnersCount': null,
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

  /// Update submission lock
  Future<void> updateSubmissionLock(
    String tournamentId,
    bool locked,
  ) async {
    await _tournaments.doc(tournamentId).update({
      'submissionLocked': locked,
    });
  }

  /// Update tournament (generic fields)
  Future<void> updateTournament(
    String tournamentId,
    Map<String, dynamic> data,
  ) async {
    await _tournaments.doc(tournamentId).update(data);
  }

  // ─────────────────────────────────────────────────────────
  // DECLARE WINNERS (Top 1 / Top 2 / Top 3)
  // ─────────────────────────────────────────────────────────

  /// Declare top N winners from the leaderboard.
  ///
  /// [winnersCount] must be 1, 2, or 3.
  Future<TournamentModel> declareWinners({
    required String tournamentId,
    required int winnersCount,
  }) async {
    if (winnersCount < 1 || winnersCount > 3) {
      throw ArgumentError('winnersCount must be 1, 2, or 3');
    }

    final leaderboardSnap = await _tournaments
        .doc(tournamentId)
        .collection('leaderboard')
        .where('status', isEqualTo: 'active')
        .orderBy('rank', descending: false)
        .limit(3)
        .get();

    if (leaderboardSnap.docs.isEmpty) {
      throw Exception('No active participants found in leaderboard');
    }

    if (leaderboardSnap.docs.length < winnersCount) {
      throw Exception(
        'Only ${leaderboardSnap.docs.length} active participants found, '
        'cannot declare $winnersCount winners.',
      );
    }

    final winners = leaderboardSnap.docs.take(winnersCount).toList();

    String? winnerUserId;
    String? winnerUserName;
    String? runnerUpUserId;
    String? runnerUpUserName;
    String? thirdPlaceUserId;
    String? thirdPlaceUserName;

    final firstData = winners[0].data();
    winnerUserId = firstData['userId'] as String?;
    winnerUserName = firstData['userName'] as String?;

    if (winnersCount >= 2) {
      final secondData = winners[1].data();
      runnerUpUserId = secondData['userId'] as String?;
      runnerUpUserName = secondData['userName'] as String?;
    }

    if (winnersCount == 3) {
      final thirdData = winners[2].data();
      thirdPlaceUserId = thirdData['userId'] as String?;
      thirdPlaceUserName = thirdData['userName'] as String?;
    }

    await _tournaments.doc(tournamentId).update({
      'status': 'completed',
      'winnerUserId': winnerUserId,
      'winnerUserName': winnerUserName,
      'runnerUpUserId': runnerUpUserId,
      'runnerUpUserName': runnerUpUserName,
      'thirdPlaceUserId': thirdPlaceUserId,
      'thirdPlaceUserName': thirdPlaceUserName,
      'winnersCount': winnersCount,
      'winnerDeclaredAt': Timestamp.fromDate(DateTime.now()),
    });

    final updatedDoc = await _tournaments.doc(tournamentId).get();
    return TournamentModel.fromMap(
      updatedDoc.id,
      updatedDoc.data()!,
    );
  }

  /// Reset winners (admin mistake recovery)
  Future<void> resetWinners(String tournamentId) async {
    await _tournaments.doc(tournamentId).update({
      'status': 'active',
      'winnerUserId': null,
      'winnerUserName': null,
      'runnerUpUserId': null,
      'runnerUpUserName': null,
      'thirdPlaceUserId': null,
      'thirdPlaceUserName': null,
      'winnersCount': null,
      'winnerDeclaredAt': null,
    });
  }

  /// Delete tournament (cascade subcollections)
  Future<void> deleteTournament(String tournamentId) async {
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