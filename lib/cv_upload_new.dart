import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class CvUploadPage extends StatefulWidget {
  const CvUploadPage({super.key});

  @override
  State<CvUploadPage> createState() => _CvUploadPageState();
}

class _CvUploadPageState extends State<CvUploadPage> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _cvRef = FirebaseFirestore.instance.collection('cv_uploads');

  Future<void> _pickAndUploadCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = path.basename(file.path);
      String userId = _user.uid;
      String storagePath = 'cv_uploads/$userId/$fileName';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(file);

      // Get download URL
      final downloadURL = await ref.getDownloadURL();

      // Save metadata in Firestore
      await _cvRef.add({
        'userId': userId,
        'fileName': fileName,
        'downloadURL': downloadURL,
        'uploadTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CV uploaded successfully")));
    }
  }

  Future<void> _deleteCV(String docId, String storagePath) async {
    await FirebaseStorage.instance.ref(storagePath).delete();
    await _cvRef.doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CV deleted")));
  }

  void _openCV(String url) {
    OpenFile.open(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload CV")),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadCV,
        child: Icon(Icons.upload_file),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cvRef.where('userId', isEqualTo: _user.uid).orderBy('uploadTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return Center(child: Text("No CVs uploaded"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final downloadURL = data['downloadURL'];
              final fileName = data['fileName'];
              final uploadTime = (data['uploadTime'] as Timestamp?)?.toDate().toString().split(".").first ?? "Unknown";

              final storagePath = 'cv_uploads/${_user.uid}/$fileName';

              return ListTile(
                title: Text(fileName),
                subtitle: Text("Uploaded: $uploadTime"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.open_in_new),
                      onPressed: () => _openCV(downloadURL),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteCV(doc.id, storagePath),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
