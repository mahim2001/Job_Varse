import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadCVPage extends StatefulWidget {
  const UploadCVPage({super.key});

  @override
  State<UploadCVPage> createState() => _UploadCVPageState();
}

class _UploadCVPageState extends State<UploadCVPage> {
  String? uploadStatus;

  Future<void> uploadCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = result.files.first;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => uploadStatus = "User not logged in");
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref('cv/${user.uid}.pdf');
      final uploadTask = await storageRef.putData(file.bytes!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save the CV URL to user's profile in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'cvUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
      }, SetOptions(merge: true)); // keep existing data

      setState(() => uploadStatus = "✅ CV Uploaded Successfully");
    } catch (e) {
      setState(() => uploadStatus = "❌ Upload failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Your CV")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text("Select and Upload CV"),
              onPressed: uploadCV,
            ),
            if (uploadStatus != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  uploadStatus!,
                  style: TextStyle(
                    color: uploadStatus!.startsWith("✅") ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
