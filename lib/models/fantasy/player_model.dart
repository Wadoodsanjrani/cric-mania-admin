import 'package:cloud_firestore/cloud_firestore.dart';

/// Player Model
/// Firestore path: tournaments/{tournamentId}/teams/{teamId}/players/{playerId}
class PlayerModel {
  final String id;
  final String name;
  final String role; // 'Batter' | 'Bowler'
  final String teamId; // parent team
  final DateTime createdAt;

  PlayerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.teamId,
    required this.createdAt,
  });

  factory PlayerModel.fromMap(String id, Map<String, dynamic> map) {
    return PlayerModel(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] ?? 'Batter',
      teamId: map['teamId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'teamId': teamId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PlayerModel copyWith({
    String? name,
    String? role,
    String? teamId,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      createdAt: createdAt,
    );
  }
}