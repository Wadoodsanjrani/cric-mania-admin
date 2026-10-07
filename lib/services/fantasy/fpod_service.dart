import 'package:cloud_firestore/cloud_firestore.dart';

/// FPOD Service
class FpodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _fpod(String tid) =>
      _firestore.collection('tournaments').doc(tid).collection('fpod');

  String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Stream<List<Map<String, dynamic>>> streamAllFpod(String tid) {
    return _fpod(tid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<Map<String, dynamic>?> streamLatestFpod(String tid) {
    return _fpod(tid)
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return {'id': snap.docs.first.id, ...snap.docs.first.data()};
    });
  }

  Future<void> deleteForDate(String tid, DateTime date) async {
    await _fpod(tid).doc(dateKey(date)).delete();
  }
}