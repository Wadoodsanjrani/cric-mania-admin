import 'package:cloud_firestore/cloud_firestore.dart';

/// Team Model
/// Firestore path: tournaments/{tournamentId}/teams/{teamId}
class TeamModel {
  final String id;
  final String name;
  final String flag; // emoji or short code e.g. 🇵🇰 or PAK
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.flag,
    required this.createdAt,
  });

  factory TeamModel.fromMap(String id, Map<String, dynamic> map) {
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      flag: map['flag'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'flag': flag,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TeamModel copyWith({
    String? name,
    String? flag,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      flag: flag ?? this.flag,
      createdAt: createdAt,
    );
  }
}