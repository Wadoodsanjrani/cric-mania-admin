
/// Points Rules Model
/// Firestore path: settings/rules
/// Yeh global settings hai â€” admin yahan se rules change kar sakta hai
class PointsRules {
  /// T20 Batting milestones: [runsThreshold, points]
  final List<int> t20Batting; // [25, 40, 60, 75] -> [1, 2, 3, 4]
  final List<int> t20BattingPoints; // [1, 2, 3, 4]

  /// T20 Bowling milestones
  final List<int> t20Bowling; // [1, 2, 4, 5] -> [1, 2, 3, 4]
  final List<int> t20BowlingPoints;

  /// ODI Batting
  final List<int> odiBatting; // [30, 46, 61, 80, 100]
  final List<int> odiBattingPoints; // [1, 2, 3, 4, 5]

  /// ODI Bowling
  final List<int> odiBowling; // [1, 3, 4, 5, 6]
  final List<int> odiBowlingPoints; // [1, 2, 3, 4, 5]

  /// Man of the Match / Man of the Series
  final int momPoints; // +1
  final int mosPoints; // +5

  PointsRules({
    required this.t20Batting,
    required this.t20BattingPoints,
    required this.t20Bowling,
    required this.t20BowlingPoints,
    required this.odiBatting,
    required this.odiBattingPoints,
    required this.odiBowling,
    required this.odiBowlingPoints,
    required this.momPoints,
    required this.mosPoints,
  });

  /// Default rules (agar Firestore mein nahi mile to yeh use honge)
  factory PointsRules.defaults() {
    return PointsRules(
      // T20 Batting: 25-40=1, 41-59=2, 60-74=3, 75+=4
      t20Batting: [25, 41, 60, 75],
      t20BattingPoints: [1, 2, 3, 4],
      // T20 Bowling: 1=1, 2-3=2, 4=3, 5+=4
      t20Bowling: [1, 2, 4, 5],
      t20BowlingPoints: [1, 2, 3, 4],
      // ODI Batting: 30-45=1, 46-60=2, 61-79=3, 80-99=4, 100+=5
      odiBatting: [30, 46, 61, 80, 100],
      odiBattingPoints: [1, 2, 3, 4, 5],
      // ODI Bowling: 1-2=1, 3=2, 4=3, 5=4, 6+=5
      odiBowling: [1, 3, 4, 5, 6],
      odiBowlingPoints: [1, 2, 3, 4, 5],
      momPoints: 1,
      mosPoints: 5,
    );
  }

  factory PointsRules.fromMap(Map<String, dynamic> map) {
    return PointsRules(
      t20Batting: List<int>.from(map['t20Batting'] ?? [25, 41, 60, 75]),
      t20BattingPoints:
          List<int>.from(map['t20BattingPoints'] ?? [1, 2, 3, 4]),
      t20Bowling: List<int>.from(map['t20Bowling'] ?? [1, 2, 4, 5]),
      t20BowlingPoints:
          List<int>.from(map['t20BowlingPoints'] ?? [1, 2, 3, 4]),
      odiBatting:
          List<int>.from(map['odiBatting'] ?? [30, 46, 61, 80, 100]),
      odiBattingPoints:
          List<int>.from(map['odiBattingPoints'] ?? [1, 2, 3, 4, 5]),
      odiBowling: List<int>.from(map['odiBowling'] ?? [1, 3, 4, 5, 6]),
      odiBowlingPoints:
          List<int>.from(map['odiBowlingPoints'] ?? [1, 2, 3, 4, 5]),
      momPoints: map['momPoints'] ?? 1,
      mosPoints: map['mosPoints'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      't20Batting': t20Batting,
      't20BattingPoints': t20BattingPoints,
      't20Bowling': t20Bowling,
      't20BowlingPoints': t20BowlingPoints,
      'odiBatting': odiBatting,
      'odiBattingPoints': odiBattingPoints,
      'odiBowling': odiBowling,
      'odiBowlingPoints': odiBowlingPoints,
      'momPoints': momPoints,
      'mosPoints': mosPoints,
    };
  }
}
