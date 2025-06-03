import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSignUpPage extends StatefulWidget {
  const AdminSignUpPage({super.key});

  @override
  State<AdminSignUpPage> createState() => _AdminSignUpPageState();
}

class _AdminSignUpPageState extends State<AdminSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isSigningUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailSent = false;

  Future<void> _signUpAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isSigningUp = true);

    try {

      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': nameController.text,
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': 'admin',
        'emailVerified': false,
        'createdAt': Timestamp.now(),
      });

      await _sendVerificationEmail(userCredential.user!);

      setState(() => _emailSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent! Please check your inbox.")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error during sign-up')),
      );
    } finally {
      setState(() => _isSigningUp = false);
    }
  }

  Future<void> _sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
    }
  }

  Future<void> _checkEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .update({'emailVerified': true});

        Navigator.pop(context); // Go back to login or dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email not yet verified. Please check your inbox.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking verification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Sign Up"),centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_emailSent) ...[
                _buildVerificationBanner(),
                const SizedBox(height: 20),
              ],
              _buildTextField(nameController, "Full Name"),
              _buildTextField(emailController, "Email"),
              _buildTextField(phoneController, "Phone Number",
                  keyboardType: TextInputType.phone),
              _buildTextField(passwordController, "Password",
                  isPassword: true, isConfirm: false),
              _buildTextField(confirmPasswordController, "Confirm Password",
                  isPassword: true, isConfirm: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSigningUp ? null : _signUpAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSigningUp
                    ? const CircularProgressIndicator()
                    : const Text(
                  "Create Admin Account",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verification Email Sent",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please check your email and click the verification link to activate your account.",
            style: TextStyle(color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: _checkEmailVerification,
                child: const Text("I've verified my email"),
              ),
              TextButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await _sendVerificationEmail(user);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Verification email resent!")),
                    );
                  }
                },
                child: const Text("Resend email"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false,
        bool isConfirm = false,
        TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword
            ? (isConfirm ? _obscureConfirmPassword : _obscurePassword)
            : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              (isConfirm ? _obscureConfirmPassword : _obscurePassword)
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              });
            },
          )
              : null,
        ),
        validator: (val) {
          if (val == null || val.isEmpty) return 'Enter $label';
          if (label == "Email" && !val.contains('@')) {
            return 'Enter a valid email';
          }
          if (isPassword && val.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }
}