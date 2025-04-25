import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobvarse_bd/login.dart';
import 'package:jobvarse_bd/profile.dart';

import 'change_pw.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isEmailVerified = false;
  bool isSendingVerification = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    await user?.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });
  }

  void _sendVerificationEmail() async {
    if (user != null && !user!.emailVerified) {
      setState(() => isSendingVerification = true);
      await user!.sendEmailVerification();
      setState(() => isSendingVerification = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent")),
      );
    }
  }

  void _changePassword(BuildContext context) {
    if (user != null && user!.email != null) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent to your email")),
      );
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Account Settings"),
            subtitle: const Text("Manage your profile and personal details"),
            leading: const Icon(Icons.person),
            trailing: const Icon(Icons.arrow_forward_ios),
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
            title: const Text("Change Password"),
            subtitle: const Text("New Password"),
            leading: const Icon(Icons.lock),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),

          ListTile(
            title: const Text("Email Verification"),
            subtitle: Text(
              isEmailVerified
                  ? "Your email is verified"
                  : "Your email is not verified",
            ),
            leading: const Icon(Icons.verified_user),
            trailing: isEmailVerified
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
              onPressed: isSendingVerification ? null : _sendVerificationEmail,
              child: isSendingVerification
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Verify"),
            ),
          ),

          ListTile(
            title: const Text("Language"),
            subtitle: const Text("Select preferred language"),
            leading: const Icon(Icons.language),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Select Language"),
                  content: const Text("This feature will be available soon."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const ListTile(
            title: Text("About App"),
            subtitle: Text("Version 1.0.0"),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}