import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  Future<void> _approve(String docId, String userId, String plan) async {
    int days = plan.toLowerCase() == 'monthly' ? 30 : 365;
    DateTime expiry = DateTime.now().add(Duration(days: days));

    await FirebaseFirestore.instance
        .collection('payment_requests')
        .doc(docId)
        .update({
      'status': 'approved',
      'approvedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isPremium': true,
      'plan': plan,
      'premiumUntil': expiry.millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> _reject(String docId) async {
    await FirebaseFirestore.instance
        .collection('payment_requests')
        .doc(docId)
        .update({
      'status': 'rejected',
      'rejectedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text('Payment Approvals', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payment_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No pending payments', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var d = doc.data() as Map<String, dynamic>;
              String plan = (d['plan'] ?? 'monthly').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF0A1931)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d['userName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: plan.toLowerCase() == 'monthly' ? Colors.blue : Colors.purple,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plan.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Amount: Rs. ${d['amount'] ?? ''}',
                          style: const TextStyle(fontSize: 15)),
                      Text('TRX ID: ${d['trxId'] ?? ''}',
                          style: const TextStyle(color: Colors.grey)),
                      Text('User ID: ${d['userId'] ?? ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('APPROVE', style: TextStyle(color: Colors.white)),
                              onPressed: () => _approve(doc.id, d['userId'], plan),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              icon: const Icon(Icons.close, color: Colors.white),
                              label: const Text('REJECT', style: TextStyle(color: Colors.white)),
                              onPressed: () => _reject(doc.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}