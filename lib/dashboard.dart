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

  void _onDrawerItemTapped(int index) {
    Navigator.pop(context); // Close drawer
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
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

  Widget _buildStatCard(String title, IconData icon, int count, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_none, size: 28),
              if (hasUnread)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            if (user?.uid != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(userId: user!.uid),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [_buildNotificationButton()],
      ),
      drawer: AppDrawer(onItemTapped: _onDrawerItemTapped),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with logo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Image.asset(
                'assets/images/jvbd.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),

            // Welcome message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "User",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Job Board Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JobBoardPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Explore Job Board",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Stats Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Your Job Applications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            FutureBuilder(
              future: Future.wait([
                _getAppliedJobsCount(),
                _getShortlistedCount(),
                _getConfirmedJobsCount(),
              ]),
              builder: (context, AsyncSnapshot<List<int>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Couldn't load application data"),
                  );
                }

                final applied = snapshot.data![0];
                final shortlisted = snapshot.data![1];
                final confirmed = snapshot.data![2];

                return Column(
                  children: [
                    _buildStatCard(
                        "Applied Jobs",
                        Icons.work_outline,
                        applied,
                        Colors.blue
                    ),
                    _buildStatCard(
                        "Shortlisted",
                        Icons.star_outline,
                        shortlisted,
                        Colors.orange
                    ),
                    _buildStatCard(
                        "Confirmed",
                        Icons.verified_outlined,
                        confirmed,
                        Colors.green
                    ),
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