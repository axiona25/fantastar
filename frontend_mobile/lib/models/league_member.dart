import '../utils/json_utils.dart';

/// Membro della lega (GET /leagues/{id}/members).
class LeagueMemberModel {
  final String userId;
  final String name;
  final String role; // admin | member
  final String status; // active | blocked | kicked
  final double budget;
  final int rosterCount;
  final DateTime? joinedAt;

  const LeagueMemberModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.status,
    required this.budget,
    required this.rosterCount,
    this.joinedAt,
  });

  factory LeagueMemberModel.fromJson(Map<String, dynamic> json) {
    DateTime? joinedAt;
    if (json['joined_at'] != null) {
      joinedAt = DateTime.tryParse(json['joined_at'].toString());
    }
    return LeagueMemberModel(
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'active',
      budget: toDoubleSafeOrDefault(json['budget'], 0),
      rosterCount: toIntSafeOrDefault(json['roster_count'], 0),
      joinedAt: joinedAt,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isBlocked => status == 'blocked';
  bool get isKicked => status == 'kicked';
}
