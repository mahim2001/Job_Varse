import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_post.dart';
import 'admin_login.dart';
import 'andmin_job_list.dart';
import 'current_admin_job_board.dart';
import 'job_board_admin.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final user = FirebaseAuth.instance.currentUser;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Admin Dashboard"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome Admin!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? 'No email',
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminJobPostPage(initialData: {}, jobId: '',)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,

              ),
              icon: const Icon(Icons.work,color: Colors.white,),
              label: const Text("Post A New Job",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminJobListPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              icon: const Icon(Icons.edit_note,color: Colors.white,),
              label: const Text("Manage Job Posts",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminJobBoardPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,

              ),
              icon: const Icon(Icons.group,color: Colors.white,),
              label: const Text("View Applicants",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminJobBoard()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              icon: const Icon(Icons.list,color: Colors.white,),
              label: const Text("All Available Jobs",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _logout,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              icon: const Icon(Icons.logout,color: Colors.white,),
              label: const Text("Log out",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
