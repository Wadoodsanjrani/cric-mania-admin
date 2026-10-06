import 'package:cloud_firestore/cloud_firestore.dart';

/// Elimination Record Model
class EliminationRecord {
  final String id;
  final String afterMatchId;
  final String afterMatchName;
  final int keptCount;
  final int eliminatedCount;
  final DateTime performedAt;
  final String performedBy;

  EliminationRecord({
    required this.id,
    required this.afterMatchId,
    required this.afterMatchName,
    required this.keptCount,
    required this.eliminatedCount,
    required this.performedAt,
    required this.performedBy,
  });

  factory EliminationRecord.fromMap(String id, Map<String, dynamic> map) {
    return EliminationRecord(
      id: id,
      afterMatchId: map['afterMatchId'] ?? '',
      afterMatchName: map['afterMatchName'] ?? '',
      keptCount: map['keptCount'] ?? 0,
      eliminatedCount: map['eliminatedCount'] ?? 0,
      performedAt:
          (map['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      performedBy: map['performedBy'] ?? '',
    );
  }
}

/// Elimination Service
/// Firestore paths:
///   tournaments/{tid}/leaderboard/{userId}  (updates status)
///   tournaments/{tid}/eliminations/{elimId}  (records)
class EliminationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _leaderboard(String tid) =>
      _firestore
          .collection('tournaments')
          .doc(tid)
          .collection('leaderboard');

  CollectionReference<Map<String, dynamic>> _eliminations(String tid) =>
      _firestore
          .collection('tournaments')
          .doc(tid)
          .collection('eliminations');

  /// Stream elimination history (latest first)
  Stream<List<EliminationRecord>> streamHistory(String tournamentId) {
    return _eliminations(tournamentId)
        .orderBy('performedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EliminationRecord.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get count of active users in tournament
  Future<int> getActiveCount(String tournamentId) async {
    final snap = await _leaderboard(tournamentId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Perform elimination — keep top N active users, eliminate rest
  /// Returns a map with kept and eliminated counts
  Future<Map<String, int>> eliminate({
    required String tournamentId,
    required String afterMatchId,
    required String afterMatchName,
    required int keepTop,
    required String performedBy,
  }) async {
    // 1. Get all active users
    final snap = await _leaderboard(tournamentId)
        .where('status', isEqualTo: 'active')
        .get();

    final allActive = snap.docs.toList();

    if (allActive.length <= keepTop) {
      throw Exception(
          'Active users (${allActive.length}) are less than or equal to keep count ($keepTop)');
    }

    // 2. Sort: points DESC → previousRank ASC → name ASC
    allActive.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final ap = (aData['totalPoints'] ?? 0) as int;
      final bp = (bData['totalPoints'] ?? 0) as int;
      if (ap != bp) return bp.compareTo(ap);

      final ar = (aData['previousRank'] ?? 999999) as int;
      final br = (bData['previousRank'] ?? 999999) as int;
      if (ar != br) return ar.compareTo(br);

      final an = (aData['userName'] ?? '') as String;
      final bn = (bData['userName'] ?? '') as String;
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });

    // 3. Split: keep top N, eliminate rest
    final kept = allActive.take(keepTop).toList();
    final eliminated = allActive.skip(keepTop).toList();

    // 4. Batch update (max 500 per batch)
    final now = Timestamp.fromDate(DateTime.now());

    Future<void> batchUpdate(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      String status,
    ) async {
      const batchSize = 500;
      for (var i = 0; i < docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = docs.skip(i).take(batchSize);
        for (final doc in chunk) {
          batch.update(doc.reference, {
            'status': status,
            if (status == 'eliminated') 'eliminatedAt': now,
            if (status == 'eliminated')
              'eliminatedAfterMatchId': afterMatchId,
          });
        }
        await batch.commit();
      }
    }

    // Ensure kept users are marked active (in case they had different status)
    await batchUpdate(kept, 'active');
    await batchUpdate(eliminated, 'eliminated');

    // 5. Save elimination record
    await _eliminations(tournamentId).add({
      'afterMatchId': afterMatchId,
      'afterMatchName': afterMatchName,
      'keptCount': kept.length,
      'eliminatedCount': eliminated.length,
      'performedAt': now,
      'performedBy': performedBy,
    });

    // 6. Update tournament document with latest counts
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'activeCount': kept.length,
      'totalEliminations': FieldValue.increment(1),
    });

    return {
      'kept': kept.length,
      'eliminated': eliminated.length,
    };
  }

  /// Reset all eliminations (bring everyone back as active)
  /// WARNING: This is destructive and should be used only if admin made a mistake
  Future<void> resetAll(String tournamentId) async {
    // Delete all elimination records
    final elims = await _eliminations(tournamentId).get();
    for (final doc in elims.docs) {
      await doc.reference.delete();
    }

    // Mark all leaderboard entries as active
    final lb = await _leaderboard(tournamentId).get();
    const batchSize = 500;
    for (var i = 0; i < lb.docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = lb.docs.skip(i).take(batchSize);
      for (final doc in chunk) {
        batch.update(doc.reference, {
          'status': 'active',
          'eliminatedAt': null,
          'eliminatedAfterMatchId': null,
        });
      }
      await batch.commit();
    }

    // Reset tournament counters
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'activeCount': lb.docs.length,
      'totalEliminations': 0,
    });
  }
}