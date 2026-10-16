import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_match_screen.dart';
import 'update_match_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1931),
        title: const Text(
          'Manage Matches',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'LIVE'),
            Tab(text: 'UPCOMING'),
            Tab(text: 'RECENT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _matchesList('LIVE'),
          _matchesList('UPCOMING'),
          _matchesList('RECENT'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A1931),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMatchScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── Matches list for a specific tab ───
  Widget _matchesList(String tabType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMatches = snapshot.data!.docs;
        final filtered = allMatches.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String st = (data['status'] ?? '').toString().toUpperCase();

          switch (tabType) {
            case 'LIVE':
              return st == 'LIVE';
            case 'UPCOMING':
              return st == 'UPCOMING';
            case 'RECENT':
              return st == 'RESULT' ||
                  st.contains('FINISH') ||
                  st.contains('ENDED');
            default:
              return false;
          }
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tabType == 'LIVE'
                        ? Icons.sports_cricket
                        : tabType == 'UPCOMING'
                            ? Icons.calendar_today
                            : Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tabType == 'LIVE'
                        ? 'No Live Matches'
                        : tabType == 'UPCOMING'
                            ? 'No Upcoming Matches'
                            : 'No Recent Matches',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            var doc = filtered[index];
            var m = doc.data() as Map<String, dynamic>;
            return _matchCard(context, doc, m);
          },
        );
      },
    );
  }

  // ─── Match card ───
  Widget _matchCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> m,
  ) {
    final status = (m['status'] ?? '').toString().toUpperCase();

    Color badgeColor = Colors.grey;
    if (status == 'LIVE') {
      badgeColor = Colors.redAccent;
    } else if (status == 'UPCOMING') {
      badgeColor = Colors.orange;
    } else if (status == 'RESULT' ||
        status.contains('FINISH') ||
        status.contains('ENDED')) {
      badgeColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                "${m['team1']} vs ${m['team2']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              m['tournament'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if ((m['matchNumber'] ?? '').toString().isNotEmpty)
              Text(
                'Match ${m['matchNumber']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Edit',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateMatchScreen(matchId: doc.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Match?'),
                    content: Text(
                      'Kya aap "${m['team1']} vs ${m['team2']}" delete karna chahte hain?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('matches')
                      .doc(doc.id)
                      .delete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}