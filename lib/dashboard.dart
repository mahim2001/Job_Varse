import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobvarse_bd/login.dart';
import 'package:jobvarse_bd/drawer.dart';
import 'home.dart';
import 'job_board.dart';
import 'notifications.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text("CV Page Content")),
    const Center(child: Text("Settings Page Content")),
  ];

  void _onDrawerItemTapped(int index) {
    Navigator.pop(context); // Close drawer
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out")),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  Future<int> _getAppliedJobsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('applicants', arrayContains: user!.uid)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getShortlistedCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('shortlisted', arrayContains: user!.uid)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getConfirmedJobsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('confirmed', arrayContains: user!.uid)
        .get();
    return snapshot.docs.length;
  }

  Widget _buildCountCard(String title, IconData icon, int count, Color color) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          "$count",
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  IconButton(
                    iconSize: 35,
                    icon: const Icon(Icons.notifications, color: Colors.black,),
                    onPressed: () {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(userId: userId),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You must be logged in to view notifications")),
                        );
                      }
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],

      ),
      drawer: AppDrawer(onItemTapped: _onDrawerItemTapped),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Image.asset(
                  'assets/images/jvbd.png',
                  width: 400,
                  height: 500,
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobBoardPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.list, color: Colors.white),
              label: const Text(
                "Job Board",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: Future.wait([
                _getAppliedJobsCount(),
                _getShortlistedCount(),
                _getConfirmedJobsCount(),
              ]),
              builder: (context, AsyncSnapshot<List<int>> snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  );
                }

                final applied = snapshot.data![0];
                final shortlisted = snapshot.data![1];
                final confirmed = snapshot.data![2];

                return Column(
                  children: [
                    _buildCountCard("Applied Jobs", Icons.work, applied, Colors.indigo),
                    _buildCountCard("Shortlisted", Icons.star, shortlisted, Colors.teal),
                    _buildCountCard("Job Confirmed", Icons.verified, confirmed, Colors.green),
                  ],
                );
              },
            ),


          ],
        ),
      ),
    );
  }
}
