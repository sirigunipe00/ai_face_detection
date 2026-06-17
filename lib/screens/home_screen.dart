import 'package:ai_face_detection/screens/add_student_screen.dart';
import 'package:ai_face_detection/screens/attendance_history_screen.dart';
import 'package:ai_face_detection/screens/dashboard_card.dart';
import 'package:ai_face_detection/screens/students_list_screen.dart';
import 'package:ai_face_detection/screens/take_attendance_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.school, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),

                  const Text(
                    "School Attendance",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),

                  const Spacer(),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// HERO SECTION
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Face Recognition",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [Color(0xff5B6CFF), Color(0xff8A6DFF)],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              "Attendance System",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Register students and mark attendance using camera",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Image.asset('assets/images/student_image.jpeg', height: 200, ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// GRID CARDS
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.8,
                children: [
                  DashboardCard(
                    title: "Add Students",
                    subtitle: "Register children with photos",
                    icon: Icons.person_add_alt,
                    iconColor: Color(0xff8B5CF6),
                    bgColor: Color(0xffF4F0FF),
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddStudentScreen(),
                          ),
                        ),
                  ),

                  DashboardCard(
                    title: "Students List",
                    subtitle: "View all registered students",
                    icon: Icons.groups,
                    iconColor: Color(0xff3B82F6),
                    bgColor: Color(0xffEEF5FF),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentsListScreen(),
                          ),
                        ),
                  ),

                  DashboardCard(
                    title: "Take Attendance",
                    subtitle: "Mark attendance using face",
                    icon: Icons.camera_alt,
                    iconColor: Color(0xff22C55E),
                    bgColor: Color(0xffEEFFF2),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TakeAttendanceScreen(),
                          ),
                        ),
                  ),

                  DashboardCard(
                    title: "Attendance History",
                    subtitle: "View attendance records",
                    icon: Icons.history,
                    iconColor: Color(0xffFB923C),
                    bgColor: Color(0xffFFF5EB),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const AttendanceHistoryScreen(),
                          ),
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// FOOTER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: const Icon(Icons.shield, color: Colors.indigo),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Secure • Fast • Accurate",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text("Powered by Face Recognition Technology"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
