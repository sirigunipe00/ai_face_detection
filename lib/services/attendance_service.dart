import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Local attendance record
class AttendanceRecord {
  final String date;
  final List<String> studentIds;
  final DateTime timestamp;

  AttendanceRecord({
    required this.date,
    required this.studentIds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'studentIds': studentIds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: json['date'] as String,
        studentIds: List<String>.from(json['studentIds'] as List),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Service for storing attendance locally (no database/Firebase)
class AttendanceService {
  static const String _fileName = 'attendance_records.json';

  Future<File> _getAttendanceFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<AttendanceRecord>> getAllRecords() async {
    try {
      final file = await _getAttendanceFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final records = await getAllRecords();
    records.add(record);
    await _writeRecords(records);
  }

  Future<void> _writeRecords(List<AttendanceRecord> records) async {
    final file = await _getAttendanceFile();
    final jsonList = records.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<List<AttendanceRecord>> getRecordsByDate(String date) async {
    final all = await getAllRecords();
    return all.where((r) => r.date == date).toList();
  }

  Future<void> clearAllRecords() async {
    await _writeRecords([]);
  }
}
