import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;

  final nameController = TextEditingController();
  final birthdayController = TextEditingController();
  final genderController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final nidController = TextEditingController();
  final passportController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_profileImage != null) {
        try {
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');

          final uploadTask = await storageRef.putFile(_profileImage!);
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          imageUrl = '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image upload failed: $e")),
          );
        }
      }


      final profileData = {
        'name': nameController.text,
        'birthday': birthdayController.text,
        'gender': genderController.text,
        'address': addressController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'nid': nidController.text,
        'passport': passportController.text,
        'imageUrl': imageUrl ?? '',
        'verifiedEmail': user.emailVerified,
        'uid': user.uid,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData);



      if (!user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (date != null) {
      birthdayController.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  @override
  void initState() {
    emailController.text = user.email ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(nameController, "Full Name"),
              _buildTextField(birthdayController, "Birthday",
                  readOnly: true, onTap: _pickDate),
              _buildDropdown(genderController),
              _buildTextField(addressController, "Address"),
              _buildTextField(phoneController, "Phone"),
              _buildTextField(emailController, "Email", readOnly: true),
              _buildTextField(nidController, "NID Number"),
              _buildTextField(passportController, "Passport Number"),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _submitProfile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                  "Save Profile",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildDropdown(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (val) => controller.text = val ?? '',
        decoration: const InputDecoration(
          labelText: "Gender",
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Select your gender' : null,
      ),
    );
  }
}
