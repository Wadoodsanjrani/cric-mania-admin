import '../../models/fantasy/points_rules.dart';

/// Points Calculator — pure logic
/// Input: runs, wickets, format, isMom, isMots
/// Output: total points
class PointsCalculator {
  final PointsRules rules;

  PointsCalculator(this.rules);

  /// Calculate batting points
  int calculateBattingPoints(int runs, String format) {
    final thresholds =
        format == 'T20' ? rules.t20Batting : rules.odiBatting;
    final points =
        format == 'T20' ? rules.t20BattingPoints : rules.odiBattingPoints;

    // Highest milestone jo runs ne cross kiya
    int awarded = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (runs >= thresholds[i]) {
        awarded = points[i];
      } else {
        break;
      }
    }
    return awarded;
  }

  /// Calculate bowling points
  int calculateBowlingPoints(int wickets, String format) {
    final thresholds =
        format == 'T20' ? rules.t20Bowling : rules.odiBowling;
    final points =
        format == 'T20' ? rules.t20BowlingPoints : rules.odiBowlingPoints;

    int awarded = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (wickets >= thresholds[i]) {
        awarded = points[i];
      } else {
        break;
      }
    }
    return awarded;
  }

  /// Total points for a single player in a single match
  int calculatePlayerMatchPoints({
    required int runs,
    required int wickets,
    required String role,
    required String format,
    bool isMom = false,
    bool isMots = false,
  }) {
    int total = 0;

    if (role == 'Batter') {
      total += calculateBattingPoints(runs, format);
    } else if (role == 'Bowler') {
      total += calculateBowlingPoints(wickets, format);
    } else {
      // Wildcard / All-rounder: dono consider karo, lekin role ke hisaab se
      total += calculateBattingPoints(runs, format);
      total += calculateBowlingPoints(wickets, format);
    }

    if (isMom) total += rules.momPoints;
    if (isMots) total += rules.mosPoints;

    return total;
  }
}