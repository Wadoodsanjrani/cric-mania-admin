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

  /// Submission lock — when true, users cannot submit/edit squads
  final bool submissionLocked;

  // ── Winner (1st Place) ──
  final String? winnerUserId;
  final String? winnerUserName;

  // ── Runner-Up (2nd Place) ──
  final String? runnerUpUserId;
  final String? runnerUpUserName;

  // ── Third Place (3rd Place) ──
  final String? thirdPlaceUserId;
  final String? thirdPlaceUserName;

  /// How many winners were declared: 1, 2, or 3
  /// null = not declared yet
  final int? winnersCount;

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
    this.submissionLocked = false,
    this.winnerUserId,
    this.winnerUserName,
    this.runnerUpUserId,
    this.runnerUpUserName,
    this.thirdPlaceUserId,
    this.thirdPlaceUserName,
    this.winnersCount,
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
      submissionLocked: map['submissionLocked'] ?? false,
      winnerUserId: map['winnerUserId'],
      winnerUserName: map['winnerUserName'],
      runnerUpUserId: map['runnerUpUserId'],
      runnerUpUserName: map['runnerUpUserName'],
      thirdPlaceUserId: map['thirdPlaceUserId'],
      thirdPlaceUserName: map['thirdPlaceUserName'],
      winnersCount: map['winnersCount'],
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
      'submissionLocked': submissionLocked,
      'winnerUserId': winnerUserId,
      'winnerUserName': winnerUserName,
      'runnerUpUserId': runnerUpUserId,
      'runnerUpUserName': runnerUpUserName,
      'thirdPlaceUserId': thirdPlaceUserId,
      'thirdPlaceUserName': thirdPlaceUserName,
      'winnersCount': winnersCount,
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
    bool? submissionLocked,
    String? winnerUserId,
    String? winnerUserName,
    String? runnerUpUserId,
    String? runnerUpUserName,
    String? thirdPlaceUserId,
    String? thirdPlaceUserName,
    int? winnersCount,
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
      submissionLocked: submissionLocked ?? this.submissionLocked,
      winnerUserId: winnerUserId ?? this.winnerUserId,
      winnerUserName: winnerUserName ?? this.winnerUserName,
      runnerUpUserId: runnerUpUserId ?? this.runnerUpUserId,
      runnerUpUserName: runnerUpUserName ?? this.runnerUpUserName,
      thirdPlaceUserId: thirdPlaceUserId ?? this.thirdPlaceUserId,
      thirdPlaceUserName: thirdPlaceUserName ?? this.thirdPlaceUserName,
      winnersCount: winnersCount ?? this.winnersCount,
      winnerDeclaredAt: winnerDeclaredAt ?? this.winnerDeclaredAt,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Helper: Check if winners declared
  bool get isWinnerDeclared => winnersCount != null && winnerUserId != null;

  /// Helper: Check if runner-up exists
  bool get hasRunnerUp => runnerUpUserId != null;

  /// Helper: Check if third place exists
  bool get hasThirdPlace => thirdPlaceUserId != null;
}