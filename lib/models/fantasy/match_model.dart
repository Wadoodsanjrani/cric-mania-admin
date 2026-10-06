import 'package:cloud_firestore/cloud_firestore.dart';

/// Match Model
/// Firestore path: tournaments/{tournamentId}/matches/{matchId}
class MatchModel {
  final String id;
  final String team1Id;
  final String team2Id;
  final String team1Name;
  final String team2Name;
  final DateTime matchDate;
  final String status; // 'scheduled' | 'completed'
  final String? motmPlayerId; // Man of the Match
  final String? motsPlayerId; // Man of the Series (optional)
  final DateTime? completedAt;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.team1Id,
    required this.team2Id,
    required this.team1Name,
    required this.team2Name,
    required this.matchDate,
    required this.status,
    this.motmPlayerId,
    this.motsPlayerId,
    this.completedAt,
    required this.createdAt,
  });

  factory MatchModel.fromMap(String id, Map<String, dynamic> map) {
    return MatchModel(
      id: id,
      team1Id: map['team1Id'] ?? '',
      team2Id: map['team2Id'] ?? '',
      team1Name: map['team1Name'] ?? '',
      team2Name: map['team2Name'] ?? '',
      matchDate: (map['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'scheduled',
      motmPlayerId: map['motmPlayerId'],
      motsPlayerId: map['motsPlayerId'],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'team1Id': team1Id,
      'team2Id': team2Id,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'matchDate': Timestamp.fromDate(matchDate),
      'status': status,
      'motmPlayerId': motmPlayerId,
      'motsPlayerId': motsPlayerId,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MatchModel copyWith({
    String? team1Id,
    String? team2Id,
    String? team1Name,
    String? team2Name,
    DateTime? matchDate,
    String? status,
    String? motmPlayerId,
    String? motsPlayerId,
    DateTime? completedAt,
  }) {
    return MatchModel(
      id: id,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      matchDate: matchDate ?? this.matchDate,
      status: status ?? this.status,
      motmPlayerId: motmPlayerId ?? this.motmPlayerId,
      motsPlayerId: motsPlayerId ?? this.motsPlayerId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }
}