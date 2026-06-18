// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'screens/home_screen.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//       systemNavigationBarColor: Color(0xFF1B5E20),
//       systemNavigationBarIconBrightness: Brightness.light,
//     ),
//   );
//   runApp(const SchoolAttendanceApp());
// }

// class SchoolAttendanceApp extends StatelessWidget {
//   const SchoolAttendanceApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'School Attendance',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF1B5E20),
//           brightness: Brightness.light,
//         ),
//         useMaterial3: true,
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

import 'package:ai_face_detection/firebase_options.dart';
import 'package:ai_face_detection/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Attendance',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xffF7F8FC),
        fontFamily: 'Poppins',
      ),
      home: const HomeScreen(),
    );
  }
}

