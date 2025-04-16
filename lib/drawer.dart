import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobvarse_bd/cv_page.dart';
import 'home.dart';
import 'login.dart';
import 'profile.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onItemTapped;

  const AppDrawer({Key? key, required this.onItemTapped}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> fetchProfile() async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    return doc.data();
  }

  void _logout(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: fetchProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                accountName: Text(profile?['name'] ?? 'Name not set'),
                accountEmail: Text(profile?['email'] ?? 'Email not set'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: profile?['imageUrl'] != null && profile!['imageUrl'].toString().isNotEmpty
                      ? NetworkImage(profile['imageUrl'])
                      : null,
                  child: profile?['imageUrl'] == null || profile!['imageUrl'].toString().isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.blue)
                      : null,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Profile"),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateProfilePage()),
                  );
                  setState(() {}); // Refresh drawer after profile update
                },
              ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text("Your CV"),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CVPage()),
                  );
                  setState(() {}); // Refresh drawer after profile update
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.pop(context);
                  widget.onItemTapped(3);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () => _logout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
