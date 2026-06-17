import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../services/face_service.dart';
import '../services/attendance_service.dart';
import '../services/student_storage_service.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;
  List<String> _detectedStudentIds = [];
  List<String> _detectedNames = [];
  Timer? _detectionTimer;
  int _autoRecordCountdown = 0;
  bool _hasRecordedThisSession = false;
  final _faceService = FaceService();
  final _studentStorage = StudentStorageService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _error = 'No camera available');
        return;
      }
      final frontIndex = _cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      final camera = frontIndex >= 0 ? _cameras![frontIndex] : _cameras!.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
        _startContinuousDetection();
      }
    } catch (e) {
      setState(() => _error = 'Camera error: $e');
    }
  }

  void _startContinuousDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (_) => _detectFaces());
  }

  Future<void> _detectFaces() async {
    // once we have detected a face we no longer need to continue
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing || _detectedStudentIds.isNotEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy(imagePath);

      final studentIds = await _faceService.identifyStudentsInPhoto(imagePath);
      final allStudents = await _studentStorage.getAllStudents();
      final studentMap = {for (var s in allStudents) s.id: s.name};
      final names = studentIds.map((id) => studentMap[id] ?? id).toList();

      if (mounted) {
        // cancel further detection once we have any face to avoid repeating
        if (studentIds.isNotEmpty) {
          _detectionTimer?.cancel();
        }

        final shouldAutoRecord = studentIds.isNotEmpty &&
            _autoRecordCountdown >= 1 &&
            !_hasRecordedThisSession;
        setState(() {
          _detectedStudentIds = studentIds;
          _detectedNames = names;
          _isProcessing = false;
          if (studentIds.isNotEmpty) {
            _autoRecordCountdown++;
            if (_autoRecordCountdown >= 2) {
              _autoRecordCountdown = 0;
              _hasRecordedThisSession = true;
            }
          } else {
            _autoRecordCountdown = 0;
          }
        });
        if (shouldAutoRecord) {
          Future.microtask(() => _recordAttendance());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _recordAttendance() async {
    if (_detectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No faces detected. Point camera at students first.')),
      );
      return;
    }

    // stop detection while saving and showing result
    _detectionTimer?.cancel();

    final allStudents = await _studentStorage.getAllStudents();
    final studentMap = {for (var s in allStudents) s.id: s.name};

    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    await AttendanceService().saveRecord(AttendanceRecord(
      date: dateStr,
      studentIds: _detectedStudentIds,
      timestamp: DateTime.now(),
    ));

    if (mounted) {
      _showResultDialog(_detectedStudentIds, studentMap);
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _showResultDialog(List<String> studentIds, Map<String, String> studentMap) {
    final names = studentIds
        .map((id) => studentMap[id] ?? id)
        .toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Expanded(child: const Text('Attendance Recorded', style: TextStyle(fontSize: 16),)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${studentIds.length} student(s) marked present:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (names.isEmpty)
              const Text('No faces recognized. Ensure students are registered.')
            else
              ...names.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(n),
                      ],
                    ),
                  )),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back from take attendance screen
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          : !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller!),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Identifying faces...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          if (_detectedNames.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detected: ${_detectedNames.length} student(s)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _detectedNames
                                        .map((n) => Chip(
                                              label: Text(n, style: const TextStyle(fontSize: 12)),
                                              backgroundColor: Colors.green.withOpacity(0.8),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  _isProcessing
                                      ? 'Detecting...'
                                      : 'Point camera at students. Detection updates automatically.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    shadows: [
                                      const Shadow(blurRadius: 4, color: Colors.black54),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _detectedStudentIds.isEmpty ? null : _recordAttendance,
                                  icon: const Icon(Icons.check_circle, size: 22),
                                  label: const Text('Record Attendance'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
