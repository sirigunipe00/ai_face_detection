import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/student.dart';

/// Local storage for student list (no database)
class StudentStorageService {
  static const String _fileName = 'students.json';

  Future<File> _getStudentsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Student>> getAllStudents() async {
    try {
      final file = await _getStudentsFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStudent(Student student) async {
    final students = await getAllStudents();
    final index = students.indexWhere((s) => s.id == student.id);
    if (index >= 0) {
      students[index] = student;
    } else {
      students.add(student);
    }
    await _writeStudents(students);
  }

  Future<void> deleteStudent(String id) async {
    final students = await getAllStudents();
    students.removeWhere((s) => s.id == id);
    await _writeStudents(students);
  }

  Future<void> _writeStudents(List<Student> students) async {
    final file = await _getStudentsFile();
    final jsonList = students.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}
