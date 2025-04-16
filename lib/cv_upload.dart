import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    final file = result.files.first;
    final user = FirebaseAuth.instance.currentUser;

    final ref = FirebaseStorage.instance.ref('cv/${user!.uid}.pdf');
    await ref.putData(file.bytes!);

    setState(() {
      uploadStatus = "CV Uploaded Successfully";
    });
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
                child: Text(uploadStatus!, style: const TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}
