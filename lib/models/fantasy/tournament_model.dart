import 'package:cloud_firestore/cloud_firestore.dart';

/// Tournament Model
/// Firestore path: tournaments/{tournamentId}
class TournamentModel {
  final String id;
  final String name;
  final String format; // 'T20' or 'ODI'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime deadline; // squad submission deadline
  final String status; // 'draft' | 'active' | 'completed'
  final String? winnerUserId;
  final String? winnerUserName;
  final DateTime? winnerDeclaredAt;
  final DateTime createdAt;
  final String createdBy;

  TournamentModel({
    required this.id,
    required this.name,
    required this.format,
    required this.startDate,
    required this.endDate,
    required this.deadline,
    required this.status,
    this.winnerUserId,
    this.winnerUserName,
    this.winnerDeclaredAt,
    required this.createdAt,
    required this.createdBy,
  });

  /// From Firestore
  factory TournamentModel.fromMap(String id, Map<String, dynamic> map) {
    return TournamentModel(
      id: id,
      name: map['name'] ?? '',
      format: map['format'] ?? 'T20',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'draft',
      winnerUserId: map['winnerUserId'],
      winnerUserName: map['winnerUserName'],
      winnerDeclaredAt:
          (map['winnerDeclaredAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  /// To Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'format': format,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'winnerUserId': winnerUserId,
      'winnerUserName': winnerUserName,
      'winnerDeclaredAt': winnerDeclaredAt != null
          ? Timestamp.fromDate(winnerDeclaredAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Copy with
  TournamentModel copyWith({
    String? name,
    String? format,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadline,
    String? status,
    String? winnerUserId,
    String? winnerUserName,
    DateTime? winnerDeclaredAt,
  }) {
    return TournamentModel(
      id: id,
      name: name ?? this.name,
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      winnerUserId: winnerUserId ?? this.winnerUserId,
      winnerUserName: winnerUserName ?? this.winnerUserName,
      winnerDeclaredAt: winnerDeclaredAt ?? this.winnerDeclaredAt,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}