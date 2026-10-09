import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/points_rules.dart';
import 'points_calculator.dart';
import 'leaderboard_service.dart';
import 'fpod_service.dart';

class PointsEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final FpodService _fpodService = FpodService();

  Future<int> calculateMatchPoints({
    required String tournamentId,
    required String matchId,
  }) async {
    final matchDoc = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId)
        .get();

    if (!matchDoc.exists) throw Exception('Match not found');

    final matchData = matchDoc.data()!;
    final team1Id = matchData['team1Id'] as String?;
    final team2Id = matchData['team2Id'] as String?;

    final tournamentDoc = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .get();
    if (!tournamentDoc.exists) throw Exception('Tournament not found');
    final format = (tournamentDoc.data()!['format'] ?? 'T20') as String;

    final rulesDoc =
        await _firestore.collection('settings').doc('rules').get();
    final rules = rulesDoc.exists
        ? PointsRules.fromMap(rulesDoc.data()!)
        : PointsRules.defaults();
    final calculator = PointsCalculator(rules);

    final statsSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId)
        .collection('stats')
        .get();

    final Map<String, Map<String, dynamic>> statsMap = {};
    for (final doc in statsSnap.docs) {
      statsMap[doc.id] = doc.data();
    }

    if (statsMap.isEmpty) return 0;

    final Map<String, String> nameToId = {};

    if (team1Id != null) {
      final p1 = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(team1Id)
          .collection('players')
          .get();
      for (final p in p1.docs) {
        final name = (p.data()['name'] ?? '').toString();
        if (name.isNotEmpty) nameToId[name] = p.id;
      }
    }

    if (team2Id != null) {
      final p2 = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(team2Id)
          .collection('players')
          .get();
      for (final p in p2.docs) {
        final name = (p.data()['name'] ?? '').toString();
        if (name.isNotEmpty) nameToId[name] = p.id;
      }
    }

    final squadsSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('squads')
        .get();

    if (squadsSnap.docs.isEmpty) return 0;

    int updated = 0;

    for (final squadDoc in squadsSnap.docs) {
      final userId = squadDoc.id;
      final squadData = squadDoc.data();
      final userName = (squadData['userName'] ?? 'Unknown').toString();

      final teamsSnap = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('squads')
          .doc(userId)
          .collection('teams')
          .get();

      if (teamsSnap.docs.isEmpty) continue;

      int matchPoints = 0;

      for (final teamDoc in teamsSnap.docs) {
        final teamSlots = teamDoc.data();

        String? resolve(String? value) {
          if (value == null || value.isEmpty) return null;
          if (statsMap.containsKey(value)) return value;
          final id = nameToId[value];
          if (id != null && statsMap.containsKey(id)) return id;
          return null;
        }

        final batterMainId = resolve(teamSlots['batterMain'] as String?);
        final batterBackupId = resolve(teamSlots['batterBackup'] as String?);
        final bowlerMainId = resolve(teamSlots['bowlerMain'] as String?);
        final bowlerBackupId = resolve(teamSlots['bowlerBackup'] as String?);
        final wildcardId = resolve(teamSlots['wildcard'] as String?);

        final batterMainPlayed = batterMainId != null;
        final bowlerMainPlayed = bowlerMainId != null;

        if (batterMainPlayed) {
          matchPoints +=
              _calcBatting(statsMap[batterMainId]!, calculator, format);
          matchPoints += _calcBonus(statsMap[batterMainId]!, rules);
        }

        if (!batterMainPlayed && batterBackupId != null) {
          matchPoints +=
              _calcBatting(statsMap[batterBackupId]!, calculator, format);
          matchPoints += _calcBonus(statsMap[batterBackupId]!, rules);
        }

        if (bowlerMainPlayed) {
          matchPoints +=
              _calcBowling(statsMap[bowlerMainId]!, calculator, format);
          matchPoints += _calcBonus(statsMap[bowlerMainId]!, rules);
        }

        if (!bowlerMainPlayed && bowlerBackupId != null) {
          matchPoints +=
              _calcBowling(statsMap[bowlerBackupId]!, calculator, format);
          matchPoints += _calcBonus(statsMap[bowlerBackupId]!, rules);
        }

        if (wildcardId != null) {
          final wStats = statsMap[wildcardId]!;
          matchPoints += _calcBatting(wStats, calculator, format);
          matchPoints += _calcBowling(wStats, calculator, format);
          matchPoints += _calcBonus(wStats, rules);
        }
      }

      await _leaderboardService.updateUserPoints(
        tournamentId: tournamentId,
        userId: userId,
        userName: userName,
        matchId: matchId,
        matchPoints: matchPoints,
      );

      updated++;
    }

    await _leaderboardService.recalculateRanks(tournamentId);

    // ✅ FIX: Ab match-based FPOD calculate hoga (date ki jagah matchId)
    await _fpodService.recalculateForMatch(
      tournamentId: tournamentId,
      matchId: matchId,
    );

    return updated;
  }

  int _calcBatting(
    Map<String, dynamic> stats,
    PointsCalculator calculator,
    String format,
  ) {
    final runs = (stats['runs'] ?? 0) as int;
    return calculator.calculateBattingPoints(runs, format);
  }

  int _calcBowling(
    Map<String, dynamic> stats,
    PointsCalculator calculator,
    String format,
  ) {
    final wickets = (stats['wickets'] ?? 0) as int;
    return calculator.calculateBowlingPoints(wickets, format);
  }

  int _calcBonus(Map<String, dynamic> stats, PointsRules rules) {
    int bonus = 0;
    if (stats['isMom'] == true) bonus += rules.momPoints;
    if (stats['isMots'] == true) bonus += rules.mosPoints;
    return bonus;
  }
}