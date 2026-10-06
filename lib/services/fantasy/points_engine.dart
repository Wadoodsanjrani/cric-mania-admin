import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fantasy/points_rules.dart';
import 'points_calculator.dart';
import 'leaderboard_service.dart';
import 'fpod_service.dart';

/// Points Engine
/// Calculate match points for all users, update leaderboard, FPOD
/// Triggered automatically after match stats are saved
class PointsEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final FpodService _fpodService = FpodService();

  /// Calculate points for a match
  /// Reads: match stats, all squads, points rules
  /// Writes: leaderboard entries, FPOD for match date
  /// Returns: number of users updated
  Future<int> calculateMatchPoints({
    required String tournamentId,
    required String matchId,
  }) async {
    // 1. Get match details (format + date)
    final matchDoc = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId)
        .get();

    if (!matchDoc.exists) {
      throw Exception('Match not found');
    }

    final matchData = matchDoc.data()!;
    final matchDate =
        (matchData['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    // 2. Get tournament format (T20 / ODI)
    final tournamentDoc = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .get();

    if (!tournamentDoc.exists) {
      throw Exception('Tournament not found');
    }

    final tournamentData = tournamentDoc.data()!;
    final format = (tournamentData['format'] ?? 'T20') as String;

    // 3. Load points rules
    final rulesDoc =
        await _firestore.collection('settings').doc('rules').get();
    final rules = rulesDoc.exists
        ? PointsRules.fromMap(rulesDoc.data()!)
        : PointsRules.defaults();

    final calculator = PointsCalculator(rules);

    // 4. Load match stats
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

    if (statsMap.isEmpty) {
      return 0;
    }

    // 5. Load all squads
    final squadsSnap = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('squads')
        .get();

    if (squadsSnap.docs.isEmpty) {
      return 0;
    }

    // 6. Calculate points for each user
    int updated = 0;

    for (final squadDoc in squadsSnap.docs) {
      final userId = squadDoc.id;
      final squadData = squadDoc.data();
      final userName = (squadData['userName'] ?? 'Unknown') as String;
      final teams = squadData['teams'] as Map<String, dynamic>? ?? {};

      int matchPoints = 0;

      for (final teamEntry in teams.entries) {
        final teamSlots = teamEntry.value as Map<String, dynamic>? ?? {};

        // Extract player IDs from slots
        final batterMain = teamSlots['batterMain'] as String?;
        final batterBackup = teamSlots['batterBackup'] as String?;
        final bowlerMain = teamSlots['bowlerMain'] as String?;
        final bowlerBackup = teamSlots['bowlerBackup'] as String?;
        final wildcard = teamSlots['wildcard'] as String?;

        // Check if main players played
        final batterMainPlayed =
            batterMain != null && statsMap.containsKey(batterMain);
        final bowlerMainPlayed =
            bowlerMain != null && statsMap.containsKey(bowlerMain);

        // ─── BATTER MAIN ───
        if (batterMainPlayed) {
          matchPoints +=
              _calcBatting(statsMap[batterMain]!, calculator, format);
          matchPoints += _calcBonus(statsMap[batterMain]!, rules);
        }

        // ─── BATTER BACKUP ───
        if (!batterMainPlayed &&
            batterBackup != null &&
            statsMap.containsKey(batterBackup)) {
          matchPoints +=
              _calcBatting(statsMap[batterBackup]!, calculator, format);
          matchPoints += _calcBonus(statsMap[batterBackup]!, rules);
        }

        // ─── BOWLER MAIN ───
        if (bowlerMainPlayed) {
          matchPoints +=
              _calcBowling(statsMap[bowlerMain]!, calculator, format);
          matchPoints += _calcBonus(statsMap[bowlerMain]!, rules);
        }

        // ─── BOWLER BACKUP ───
        if (!bowlerMainPlayed &&
            bowlerBackup != null &&
            statsMap.containsKey(bowlerBackup)) {
          matchPoints +=
              _calcBowling(statsMap[bowlerBackup]!, calculator, format);
          matchPoints += _calcBonus(statsMap[bowlerBackup]!, rules);
        }

        // ─── WILDCARD ───
        if (wildcard != null && statsMap.containsKey(wildcard)) {
          final wStats = statsMap[wildcard]!;
          matchPoints += _calcBatting(wStats, calculator, format);
          matchPoints += _calcBowling(wStats, calculator, format);
          matchPoints += _calcBonus(wStats, rules);
        }
      }

      // 7. Update leaderboard
      await _leaderboardService.updateUserPoints(
        tournamentId: tournamentId,
        userId: userId,
        userName: userName,
        matchId: matchId,
        matchPoints: matchPoints,
      );

      updated++;
    }

    // 8. Recalculate ranks
    await _leaderboardService.recalculateRanks(tournamentId);

    // 9. Recalculate FPOD for this match date
    await _fpodService.recalculateForDate(
      tournamentId: tournamentId,
      date: matchDate,
    );

    return updated;
  }

  /// Calculate batting points (runs)
  int _calcBatting(
    Map<String, dynamic> stats,
    PointsCalculator calculator,
    String format,
  ) {
    final runs = (stats['runs'] ?? 0) as int;
    return calculator.calculateBattingPoints(runs, format);
  }

  /// Calculate bowling points (wickets)
  int _calcBowling(
    Map<String, dynamic> stats,
    PointsCalculator calculator,
    String format,
  ) {
    final wickets = (stats['wickets'] ?? 0) as int;
    return calculator.calculateBowlingPoints(wickets, format);
  }

  /// Calculate MOTM / MOS bonus
  /// Note: MOM = Man of the Match, MOS = Man of the Series
  int _calcBonus(Map<String, dynamic> stats, PointsRules rules) {
    int bonus = 0;
    if (stats['isMom'] == true) bonus += rules.momPoints;
    if (stats['isMots'] == true) bonus += rules.mosPoints;
    return bonus;
  }
}