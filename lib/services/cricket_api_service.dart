import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class CricketApiService {
  // ═══════════════════════════════════════════════════
  // API KEY - e2d09548-e5d8-4fed-ae40-b647f0125197
  // ═══════════════════════════════════════════════════
  static const String _apiKey = 'e2d09548-e5d8-4fed-ae40-b647f0125197';
  static const String _baseUrl = 'https://api.cricapi.com/v1';

  // ─── CURRENT MATCHES (LIVE + RECENT) ───
  Future<List<Map<String, dynamic>>> getCurrentMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/currentMatches?apikey=$_apiKey&offset=0'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  // ─── ALL MATCHES (UPCOMING + LIVE + RECENT) ───
  Future<List<Map<String, dynamic>>> getAllMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/matches?apikey=$_apiKey&offset=0'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all matches: $e');
      return [];
    }
  }

  // ─── MATCH SCORECARD ───
  Future<Map<String, dynamic>?> getScorecard(String matchId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/match_scorecard?apikey=$_apiKey&id=$matchId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching scorecard: $e');
      return null;
    }
  }

  // ─── SYNC MATCH TO FIREBASE ───
  Future<bool> syncMatchToFirebase(String apiMatchId) async {
    try {
      final scorecard = await getScorecard(apiMatchId);
      if (scorecard == null) return false;

      Map<String, dynamic> firebaseData = {
        'team1': scorecard['teams']?[0] ?? 'Team 1',
        'team2': scorecard['teams']?[1] ?? 'Team 2',
        'status': scorecard['status'] ?? 'LIVE',
        'tournament': scorecard['name'] ?? '',
        'format': _detectFormat(scorecard['name'] ?? ''),
        'apiMatchId': apiMatchId,
        'apiTracked': true,
        'lastSync': DateTime.now().millisecondsSinceEpoch,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      List scores = scorecard['score'] ?? [];
      if (scores.isNotEmpty) {
        firebaseData['score1'] = _extractScore(scores, 0);
        firebaseData['score2'] =
            scores.length > 1 ? _extractScore(scores, 1) : '';
      }

      if (scorecard['scorecard'] != null) {
        firebaseData['team1Batting'] =
            _extractBatting(scorecard['scorecard'], 0);
        firebaseData['team2Batting'] =
            _extractBatting(scorecard['scorecard'], 1);
        firebaseData['team1Bowling'] =
            _extractBowling(scorecard['scorecard'], 0);
        firebaseData['team2Bowling'] =
            _extractBowling(scorecard['scorecard'], 1);
      }

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(apiMatchId)
          .set(firebaseData, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error syncing match: $e');
      return false;
    }
  }

  // ─── FORMAT DETECT ───
  String _detectFormat(String matchName) {
    String name = matchName.toLowerCase();
    if (name.contains('test')) return 'TEST';
    if (name.contains('t20') || name.contains('t20i')) return 'T20I';
    if (name.contains('odi')) return 'ODI';
    return 'ODI';
  }

  // ─── SCORE EXTRACT ───
  String _extractScore(List scores, int index) {
    if (index >= scores.length) return '';
    var score = scores[index];
    return "${score['r'] ?? 0}/${score['w'] ?? 0} (${score['o'] ?? 0})";
  }

  // ─── BATTING EXTRACT ───
  List<Map<String, dynamic>> _extractBatting(List scorecard, int inningsIndex) {
    List<Map<String, dynamic>> batting = [];
    if (inningsIndex >= scorecard.length) return batting;

    var innings = scorecard[inningsIndex];
    List batsmen = innings['batting'] ?? [];

    for (var b in batsmen) {
      batting.add({
        'name': b['batsman']?['name'] ?? '',
        'howOut': b['dismissal']?.toString() ?? '',
        'r': b['r']?.toString() ?? '0',
        'b': b['b']?.toString() ?? '0',
        '4s': b['4s']?.toString() ?? '0',
        '6s': b['6s']?.toString() ?? '0',
        'sr': b['sr']?.toString() ?? '0',
      });
    }
    return batting;
  }

  // ─── BOWLING EXTRACT ───
  List<Map<String, dynamic>> _extractBowling(List scorecard, int inningsIndex) {
    List<Map<String, dynamic>> bowling = [];
    if (inningsIndex >= scorecard.length) return bowling;

    var innings = scorecard[inningsIndex];
    List bowlers = innings['bowling'] ?? [];

    for (var b in bowlers) {
      bowling.add({
        'name': b['bowler']?['name'] ?? '',
        'o': b['o']?.toString() ?? '0',
        'm': b['m']?.toString() ?? '0',
        'r': b['r']?.toString() ?? '0',
        'w': b['w']?.toString() ?? '0',
      });
    }
    return bowling;
  }
}