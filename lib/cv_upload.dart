import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

class UploadCVPage extends StatefulWidget {
  const UploadCVPage({super.key});

  @override
  State<UploadCVPage> createState() => _UploadCVPageState();
}

class _UploadCVPageState extends State<UploadCVPage> {
  String? uploadStatus;
  bool isUploading = false;
  double? uploadProgress;
  PlatformFile? selectedFile;
  UploadTask? _uploadTask;
  final user = FirebaseAuth.instance.currentUser!;
  final cvCollection = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    _uploadTask?.cancel();
    super.dispose();
  }

  Future<void> uploadCV() async {
    try {
      setState(() {
        uploadStatus = null;
        isUploading = true;
        uploadProgress = 0;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          uploadStatus = "No file selected";
          isUploading = false;
        });
        return;
      }

      final file = result.files.first;
      setState(() => selectedFile = file);

      if (file.size > 5 * 1024 * 1024) {
        setState(() {
          uploadStatus = "File too large (max 5MB)";
          isUploading = false;
        });
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExt = file.extension ?? 'pdf';
      final fileName = 'cv_${user.uid}_$timestamp.$fileExt';
      final storageRef = FirebaseStorage.instance.ref().child('cvs/$fileName');

      _uploadTask = storageRef.putData(file.bytes!, SettableMetadata(
        contentType: 'application/$fileExt',
        customMetadata: {'uploadedBy': user.uid},
      ));

      _uploadTask!.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          uploadProgress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        });
      });

      final taskSnapshot = await _uploadTask!;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      if (downloadUrl.isNotEmpty) {
        await cvCollection.doc(user.uid).collection('cvs').add({
          'url': downloadUrl,
          'name': file.name,
          'size': file.size,
          'uploadedAt': Timestamp.now(),
          'storagePath': storageRef.fullPath,
          'fileType': fileExt,
        });
      }


      setState(() {
        uploadStatus = "Upload successful!";
        isUploading = false;
        selectedFile = null;
        uploadProgress = null;
      });
    } catch (e) {
      setState(() {
        uploadStatus = "Error: ${e.toString()}";
        isUploading = false;
      });
    }
  }

  Future<void> deleteCV(String docId, String storagePath) async {
    await FirebaseStorage.instance.ref(storagePath).delete();
    await cvCollection.doc(user.uid).collection('cvs').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CV deleted")));
  }

  void openCV(String url) {
    OpenFile.open(url); // Requires internet or PDF viewer on device
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Manage CV")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.upload_file, size: 60, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text("Upload Your Resume", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text("Allowed: PDF, DOC, DOCX (Max: 5MB)", style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: Icon(Icons.upload),
              label: Text(isUploading ? "Uploading..." : "Select & Upload CV"),
              onPressed: isUploading ? null : uploadCV,
            ),
            if (uploadProgress != null)
              Column(
                children: [
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 10),
                  Text("Uploading ${(uploadProgress! * 100).toStringAsFixed(0)}%"),
                ],
              ),
            if (uploadStatus != null) ...[
              const SizedBox(height: 10),
              Text(uploadStatus!, style: TextStyle(
                color: uploadStatus!.contains("success") ? Colors.green : Colors.red,
              )),
            ],
            const Divider(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Your Uploaded CVs", style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: cvCollection.doc(user.uid).collection('cvs')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return Text("No CV uploaded yet.");

                return ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: Icon(Icons.insert_drive_file),
                      title: Text(data['name']),
                      subtitle: Text("Size: ${(data['size'] / 1024).toStringAsFixed(1)} KB"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                            onPressed: data['url'] != null
                                ? () => openCV(data['url'])
                                : null,
                          ),

                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCV(doc.id, data['storagePath']),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
