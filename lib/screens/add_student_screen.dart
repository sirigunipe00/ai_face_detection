// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/student.dart';
// import '../services/face_service.dart';
// import '../services/student_storage_service.dart';

// class AddStudentScreen extends StatefulWidget {
//   const AddStudentScreen({super.key});

//   @override
//   State<AddStudentScreen> createState() => _AddStudentScreenState();
// }

// class _AddStudentScreenState extends State<AddStudentScreen> {
//   final _nameController = TextEditingController();
//   final _idController = TextEditingController();
//   final _faceService = FaceService();
//   final _studentStorage = StudentStorageService();
//   final _imagePicker = ImagePicker();

//   String? _imagePath;
//   bool _isLoading = false;
//   String? _error;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _idController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final picked = await _imagePicker.pickImage(
//         source: source,
//         maxWidth: 1024,
//         imageQuality: 85,
//       );
//       if (picked != null) {
//         setState(() {
//           _imagePath = picked.path;
//           _error = null;
//         });
//       }
//     } catch (e) {
//       setState(() => _error = 'Failed to pick image: $e');
//     }
//   }

//   Future<void> _registerStudent() async {
//     final name = _nameController.text.trim();
//     final id = _idController.text.trim().isEmpty
//         ? 'student_${DateTime.now().millisecondsSinceEpoch}'
//         : _idController.text.trim();

//     if (name.isEmpty) {
//       setState(() => _error = 'Please enter student name');
//       return;
//     }
//     if (_imagePath == null) {
//       setState(() => _error = 'Please add a photo');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       await _faceService.registerStudent(
//         studentId: id,
//         studentName: name,
//         imagePath: _imagePath!,
//       );
//       await _studentStorage.saveStudent(Student(
//         id: id,
//         name: name,
//         imagePath: _imagePath!,
//       ));

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('$name registered successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         _nameController.clear();
//         _idController.clear();
//         setState(() {
//           _imagePath = null;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Registration failed: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add Student'),
//         backgroundColor: const Color(0xFF1B5E20),
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'Register a student with their photo for face recognition',
//               style: TextStyle(color: Colors.grey, fontSize: 14),
//             ),
//             const SizedBox(height: 24),
//             GestureDetector(
//               onTap: () => _showImageSourceDialog(),
//               child: Container(
//                 height: 200,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.grey.shade400),
//                 ),
//                 child: _imagePath != null
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(16),
//                         child: Image.file(
//                           File(_imagePath!),
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                         ),
//                       )
//                     : Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Tap to add photo',
//                             style: TextStyle(color: Colors.grey.shade600),
//                           ),
//                           Text(
//                             'Camera or Gallery',
//                             style: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(
//                 labelText: 'Student Name *',
//                 hintText: 'e.g. Ravi Kumar',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.person),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _idController,
//               decoration: const InputDecoration(
//                 labelText: 'Student ID (optional)',
//                 hintText: 'Auto-generated if empty',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.badge),
//               ),
//             ),
//             if (_error != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.error_outline, color: Colors.red.shade700),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         _error!,
//                         style: TextStyle(color: Colors.red.shade700),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//             const SizedBox(height: 32),
//             FilledButton(
//               onPressed: _isLoading ? null : _registerStudent,
//               style: FilledButton.styleFrom(
//                 backgroundColor: const Color(0xFF1B5E20),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: _isLoading
//                   ? const SizedBox(
//                       height: 24,
//                       width: 24,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : const Text('Register Student'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showImageSourceDialog() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.camera);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Gallery'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.gallery);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student.dart';
import '../services/face_service.dart';
import '../services/student_storage_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _faceService = FaceService();
  final _studentStorage = StudentStorageService();
  final _imagePicker = ImagePicker();

  String? _imagePath;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _registerStudent() async {
    final name = _nameController.text.trim();
    final id = _idController.text.trim().isEmpty
        ? 'student_${DateTime.now().millisecondsSinceEpoch}'
        : _idController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter student name');
      return;
    }
    if (_imagePath == null) {
      setState(() => _error = 'Please add a photo');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _faceService.registerStudent(
        studentId: id,
        studentName: name,
        imagePath: _imagePath!,
      );
      await _studentStorage.saveStudent(Student(
        id: id,
        name: name,
        imagePath: _imagePath!,
        embedding: result.embedding,
        createdAt: DateTime.now().toIso8601String(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _idController.clear();
        setState(() {
          _imagePath = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Register a student with their photo for face recognition',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            'Camera or Gallery',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name *',
                hintText: 'e.g. Ravi Kumar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Student ID (optional)',
                hintText: 'Auto-generated if empty',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _registerStudent,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Register Student'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}