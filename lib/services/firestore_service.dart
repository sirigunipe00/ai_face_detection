import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/student.dart';

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _db.collection('students');

  CollectionReference<Map<String, dynamic>> _attendanceRecordsRef(
    String dateKey,
  ) =>
      _db.collection('attendance').doc(dateKey).collection('records');

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> saveStudent(Student student) async {
    await _studentsRef.doc(student.id).set(student.toJson());
  }

  Future<List<Student>> getAllStudents() async {
    final snapshot = await _studentsRef.get();
    return snapshot.docs.map((doc) => Student.fromJson(doc.data())).toList();
  }

  Stream<List<Student>> watchAllStudents() {
    return _studentsRef.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromJson(doc.data())).toList(),
        );
  }

  Future<void> deleteStudent(String studentId) async {
    await _studentsRef.doc(studentId).delete();
  }

  Future<void> markAttendanceIfNeeded({
    required String studentId,
    required String studentName,
    DateTime? date,
  }) async {
    final dateKey =
        date != null ? DateFormat('yyyy-MM-dd').format(date) : _todayKey();
    final docRef = _attendanceRecordsRef(dateKey).doc(studentId);

    final existing = await docRef.get();
    if (existing.exists) return;

    final attendance = Attendance(
      studentId: studentId,
      studentName: studentName,
      dateKey: dateKey,
      status: 'marked',
      markedAt: DateTime.now().toIso8601String(),
    );
    await docRef.set(attendance.toJson());
  }

  Future<List<Attendance>> getAttendanceForDate([DateTime? date]) async {
    final dateKey =
        date != null ? DateFormat('yyyy-MM-dd').format(date) : _todayKey();
    final snapshot = await _attendanceRecordsRef(dateKey).get();
    return snapshot.docs.map((doc) => Attendance.fromJson(doc.data())).toList();
  }

  Future<List<Attendance>> getFullAttendanceForDate([DateTime? date]) async {
    final dateKey =
        date != null ? DateFormat('yyyy-MM-dd').format(date) : _todayKey();
    final students = await getAllStudents();
    final marked = await getAttendanceForDate(date);
    final markedIds = {for (final a in marked) a.studentId: a};

    return students.map((student) {
      return markedIds[student.id] ??
          Attendance(
            studentId: student.id,
            studentName: student.name,
            dateKey: dateKey,
            status: 'not_marked',
          );
    }).toList();
  }

  Stream<List<Attendance>> watchAttendanceForToday() {
    return _attendanceRecordsRef(_todayKey()).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Attendance.fromJson(doc.data()))
              .toList(),
        );
  }
}
