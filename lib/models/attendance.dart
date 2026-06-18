/// Represents a single attendance record for a student.
/// One record is created per student per calendar day - if the student is
/// recognized multiple times in the same day, the existing record's
/// `markedAt`/`status` is left as-is (first recognition of the day wins).
class Attendance {
  final String studentId;
  final String studentName;
  final String dateKey; // "yyyy-MM-dd", used as the Firestore document ID.
  final String status; // "marked" or "not_marked"
  final String? markedAt; // ISO8601 timestamp of when recognition happened.

  Attendance({
    required this.studentId,
    required this.studentName,
    required this.dateKey,
    required this.status,
    this.markedAt,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'dateKey': dateKey,
        'status': status,
        'markedAt': markedAt,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        dateKey: json['dateKey'] as String,
        status: json['status'] as String? ?? 'not_marked',
        markedAt: json['markedAt'] as String?,
      );
}