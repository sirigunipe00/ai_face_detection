import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'firestore_service.dart';

/// Result of registering a student's face - carries the computed embedding
/// back to the caller so it can be stored alongside the Student record.
class FaceRegistrationResult {
  final String studentId;
  final List<double> embedding;

  FaceRegistrationResult({required this.studentId, required this.embedding});
}

/// Custom face recognition service - handles both float32 and uint8 (quantized) models
class FaceService {
  static final FaceService _instance = FaceService._internal();
  factory FaceService() => _instance;

  FaceService._internal();

  static const String _embeddingsFile = 'face_embeddings.json';
  static const double _threshold = 0.60;

  bool _initialized = false;
  Interpreter? _interpreter;
  FaceDetector? _faceDetector;

  int _inputSize = 160;
  bool _inputIsUint8 = false;
  int _outputSize = 128;
  bool _outputIsUint8 = false;
  double _outputScale = 1.0;
  int _outputZeroPoint = 0;

  Future<void> init() async {
    if (_initialized) return;

    final modelBuffer = await rootBundle.load('assets/models/facenet.tflite');
    _interpreter = Interpreter.fromBuffer(modelBuffer.buffer.asUint8List());

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    final inputShape = inputTensor.shape;
    _inputSize = inputShape.length >= 2 ? inputShape[1] : 160;
    _inputIsUint8 = inputTensor.type == TensorType.uint8;

    final outputShape = outputTensor.shape;
    _outputSize = outputShape.last;
    _outputIsUint8 = outputTensor.type == TensorType.uint8;
    if (_outputIsUint8) {
      final params = outputTensor.params;
      _outputScale = params.scale;
      _outputZeroPoint = params.zeroPoint;
    }

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: false,
        enableContours: false,
        minFaceSize: 0.15,
      ),
    );
    _initialized = true;
  }

  Future<File> _getEmbeddingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_embeddingsFile');
  }

  Future<Map<String, List<List<double>>>> _loadEmbeddings() async {
    try {
      final file = await _getEmbeddingsFile();
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(content);
      final result = <String, List<List<double>>>{};
      for (final e in json.entries) {
        result[e.key] = (e.value as List)
            .map((l) => (l as List).map((x) => (x as num).toDouble()).toList())
            .toList();
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveEmbeddings(Map<String, List<List<double>>> embeddings) async {
    final file = await _getEmbeddingsFile();
    final json = embeddings.map((k, v) => MapEntry(k, v));
    await file.writeAsString(jsonEncode(json));
  }

  Future<img.Image?> _extractFaceRegion(File imageFile) async {
    final inputImage = Platform.isIOS
        ? InputImage.fromFilePath(imageFile.path)
        : InputImage.fromFile(imageFile);
    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) return null;

    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    final face = faces.first;
    final boundingBox = face.boundingBox;
    const marginRatio = 0.08;
    final x = (boundingBox.left - boundingBox.width * marginRatio)
        .toInt()
        .clamp(0, originalImage.width - 1);
    final y = (boundingBox.top - boundingBox.height * marginRatio)
        .toInt()
        .clamp(0, originalImage.height - 1);
    final w = (boundingBox.width * (1 + 2 * marginRatio)).toInt();
    final h = (boundingBox.height * (1 + 2 * marginRatio)).toInt();
    int size = math.max(w, h);
    size = math.min(
      size,
      math.min(originalImage.width - x, originalImage.height - y),
    );
    final cropped = img.copyCrop(originalImage, x: x, y: y, width: size, height: size);
    return img.copyResize(cropped, width: _inputSize, height: _inputSize);
  }

  List<double> _runEmbedding(img.Image image) {
    Object input;
    if (_inputIsUint8) {
      final pixels = Uint8List(1 * _inputSize * _inputSize * 3);
      int idx = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = image.getPixel(x, y);
          pixels[idx++] = pixel.r.toInt().clamp(0, 255);
          pixels[idx++] = pixel.g.toInt().clamp(0, 255);
          pixels[idx++] = pixel.b.toInt().clamp(0, 255);
        }
      }
      input = pixels;
    } else {
      input = List.generate(1, (_) => List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            ((pixel.r - 127.5) / 127.5),
            ((pixel.g - 127.5) / 127.5),
            ((pixel.b - 127.5) / 127.5),
          ];
        });
      }));
    }

    Object output;
    if (_outputIsUint8) {
      output = List.filled(1 * _outputSize, 0).reshape([1, _outputSize]);
    } else {
      output = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);
    }

    _interpreter!.run(input, output);

    if (_outputIsUint8) {
      final raw = output as List;
      return List.generate(_outputSize, (i) {
        final v = (raw[0] as List)[i] as int;
        return (v - _outputZeroPoint) * _outputScale;
      });
    } else {
      return List<double>.from((output as List)[0]);
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    return denom > 0 ? dot / denom : 0.0;
  }

  /// Registers a student's face and returns the computed embedding so the
  /// caller can persist it alongside the Student record (e.g. for display).
  Future<FaceRegistrationResult> registerStudent({
    required String studentId,
    required String studentName,
    required String imagePath,
  }) async {
    await init();
    final faceImage = await _extractFaceRegion(File(imagePath));
    if (faceImage == null) throw Exception('No face detected in image');
    final embedding = _runEmbedding(faceImage);
    final embeddings = await _loadEmbeddings();
    embeddings[studentId] = [embedding];
    await _saveEmbeddings(embeddings);
    return FaceRegistrationResult(studentId: studentId, embedding: embedding);
  }

  /// Builds the in-memory matching set: studentId -> list of embeddings,
  /// plus a parallel studentId -> name map. Firestore is the primary
  /// source (so recognition works across devices, per requirement), with
  /// the local `face_embeddings.json` cache used as a fallback if the
  /// device is offline or the Firestore read fails.
  Future<
      (
        Map<String, List<List<double>>> embeddingsByStudent,
        Map<String, String> namesByStudent
      )> _buildMatchingSet() async {
    try {
      final students =
          await FirestoreService.instance.getAllStudents().timeout(
        const Duration(seconds: 8),
      );
      if (students.isNotEmpty) {
        final embeddingsByStudent = <String, List<List<double>>>{};
        final namesByStudent = <String, String>{};
        for (final student in students) {
          if (student.embedding.isEmpty) continue; // Skip incomplete records.
          embeddingsByStudent[student.id] = [student.embedding];
          namesByStudent[student.id] = student.name;
        }
        // Refresh the local cache so offline recognition still works later.
        if (embeddingsByStudent.isNotEmpty) {
          await _saveEmbeddings(embeddingsByStudent);
        }
        return (embeddingsByStudent, namesByStudent);
      }
    } catch (_) {
      // Firestore unreachable (offline, etc.) - fall through to local cache.
    }

    // Fallback: local cache has no names attached, so reuse studentId as
    // a last resort label (better than crashing, worse than a real name).
    final localEmbeddings = await _loadEmbeddings();
    final namesByStudent = {
      for (final id in localEmbeddings.keys) id: id,
    };
    return (localEmbeddings, namesByStudent);
  }

  Future<List<String>> identifyStudentsInPhoto(String imagePath) async {
    await init();
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) return [];

    final imageBytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return [];

    final (storedEmbeddings, namesByStudent) = await _buildMatchingSet();
    if (storedEmbeddings.isEmpty) return [];

    final identifiedIds = <String>{};
    for (final face in faces) {
      final rect = face.boundingBox;
      final x = rect.left.clamp(0, image.width - 1).toInt();
      final y = rect.top.clamp(0, image.height - 1).toInt();
      final w = rect.width.clamp(1, image.width - x).toInt();
      final h = rect.height.clamp(1, image.height - y).toInt();
      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      final resized = img.copyResize(cropped, width: _inputSize, height: _inputSize);
      try {
        final embedding = _runEmbedding(resized);
        for (final entry in storedEmbeddings.entries) {
          for (final stored in entry.value) {
            if (_cosineSimilarity(embedding, stored) >= _threshold) {
              identifiedIds.add(entry.key);
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (identifiedIds.isNotEmpty) {
      await _markAttendanceForIdentified(identifiedIds, namesByStudent);
    }

    return identifiedIds.toList();
  }

  /// Marks attendance in Firestore for each recognized student. Failures
  /// (e.g. device offline) are swallowed per-student so one network error
  /// doesn't block recognition results from reaching the caller - the
  /// scan/identify flow should still show "Employee Detected" even if the
  /// cloud write fails.
  Future<void> _markAttendanceForIdentified(
    Set<String> identifiedIds,
    Map<String, String> namesByStudent,
  ) async {
    for (final studentId in identifiedIds) {
      final studentName = namesByStudent[studentId] ?? studentId;
      try {
        await FirestoreService.instance
            .markAttendanceIfNeeded(
              studentId: studentId,
              studentName: studentName,
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Attendance sync failure shouldn't break face identification.
      }
    }
  }

  Future<List<String>> getAllRegisteredStudents() async {
    final embeddings = await _loadEmbeddings();
    return embeddings.keys.toList();
  }

  Future<void> deleteStudent(String studentId) async {
    final embeddings = await _loadEmbeddings();
    embeddings.remove(studentId);
    await _saveEmbeddings(embeddings);
  }

  Future<bool> isStudentRegistered(String studentId) async {
    final embeddings = await _loadEmbeddings();
    return embeddings.containsKey(studentId);
  }

  void dispose() {
    _faceDetector?.close();
    _interpreter?.close();
  }
}