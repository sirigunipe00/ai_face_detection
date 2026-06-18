import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/face_service.dart';
import '../services/firestore_service.dart';
import '../services/student_storage_service.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final _faceService = FaceService();
  final _studentStorage = StudentStorageService();
  final _firestore = FirestoreService.instance;
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _studentStorage.getAllStudents();
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _deleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Remove ${student.name}? They will need to be re-registered for face recognition.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _faceService.deleteStudent(student.id);
      await _studentStorage.deleteStudent(student.id);
      try {
        await _firestore.deleteStudent(student.id).timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {
        // Local delete already succeeded; cloud delete failure is non-fatal
        // here (e.g. offline) - the record will be stale in Firestore but
        // won't block the local UI from reflecting the removal.
      }
      _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} removed')),
        );
      }
    }
  }

  /// Formats the registration timestamp for display, falling back
  /// gracefully if the stored value can't be parsed.
  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (_) {
      return iso;
    }
  }

  /// Builds a short human-readable preview of the embedding vector, e.g.
  /// "[0.12, -0.45, 0.08, ...] (128-d)". Returns null if no embedding is
  /// stored (e.g. for students registered before this field existed).
  String? _formatEmbeddingPreview(List<double> embedding) {
    if (embedding.isEmpty) return null;
    final previewCount = embedding.length < 3 ? embedding.length : 3;
    final preview = embedding
        .take(previewCount)
        .map((v) => v.toStringAsFixed(2))
        .join(', ');
    final suffix = embedding.length > previewCount ? ', ...' : '';
    return '[$preview$suffix] (${embedding.length}-d)';
  }

  void _showEmbeddingDetail(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final embedding = student.embedding;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'ID: ${student.id}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    'Added: ${_formatDate(student.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Face Embedding',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (embedding.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${embedding.length} values',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (embedding.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          tooltip: 'Copy as JSON',
                          onPressed: () =>
                              _copyEmbeddingToClipboard(context, embedding),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: embedding.isEmpty
                        ? Center(
                            child: Text(
                              'No embedding stored for this student.\n'
                              'They were likely registered before this '
                              'feature was added.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: scrollController,
                            child: SelectableText(
                              _formatFullEmbedding(embedding),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Formats the entire embedding vector as a readable, indexed list -
  /// easier to scan than one giant comma-separated line, e.g.:
  /// [0]  0.1234
  /// [1] -0.4521
  String _formatFullEmbedding(List<double> embedding) {
    final buffer = StringBuffer();
    for (int i = 0; i < embedding.length; i++) {
      final index = '[$i]'.padRight(6);
      final value = embedding[i].toStringAsFixed(6).padLeft(10);
      buffer.writeln('$index$value');
    }
    return buffer.toString();
  }

  void _copyEmbeddingToClipboard(BuildContext context, List<double> embedding) {
    final jsonString = embedding.map((v) => v.toStringAsFixed(6)).toList().toString();
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Embedding copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students List'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No students registered yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add students from the home screen',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final embeddingPreview =
                          _formatEmbeddingPreview(student.embedding);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: File(student.imagePath).existsSync()
                                ? FileImage(File(student.imagePath))
                                : null,
                            child: !File(student.imagePath).existsSync()
                                ? const Icon(Icons.person, size: 32)
                                : null,
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${student.id}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Added: ${_formatDate(student.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      embeddingPreview ?? 'Embedding: not available',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (embeddingPreview != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.open_in_full,
                                      size: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () => _deleteStudent(student),
                          ),
                          onTap: () => _showEmbeddingDetail(student),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}