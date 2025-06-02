import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailsPage extends StatelessWidget {
  final String jobId;
  const JobDetailsPage({super.key, required this.jobId});

  Future<void> _applyForJob(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to apply.")),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final cvUrl = userDoc.data()?['cvUrl'] ?? '';

      if (cvUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload your CV first.")),
        );
        return;
      }

      final jobRef =
      FirebaseFirestore.instance.collection('jobs').doc(jobId);

      print("User ID: ${user.uid}");
      print("Job ID: $jobId");
      print("CV URL: $cvUrl");

      // Add user to job's applicant list
      await jobRef.update({
        'applicants': FieldValue.arrayUnion([user.uid])
      });

      // Save full application with CV URL
      await FirebaseFirestore.instance.collection('applications').add({
        'jobId': jobId,
        'userId': user.uid,
        'cvUrl': cvUrl,
        'appliedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application submitted with your CV!")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error applying for job: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to apply: $e")),
      );
    }
  }

  Future<void> _viewSubmittedCV(String userId, BuildContext context) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final cvUrl = userDoc.data()?['cvUrl'] ?? '';

      if (cvUrl.isNotEmpty) {
        final Uri url = Uri.parse(cvUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch CV URL.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No CV found.")),
        );
      }
    } catch (e) {
      print("Error launching CV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details'), centerTitle: true),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = snapshot.data!;
          final user = FirebaseAuth.instance.currentUser;
          final List<dynamic> applicants = job['applicants'] ?? [];
          final bool alreadyApplied =
              user != null && applicants.contains(user.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['title'],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _infoRow("Company", job['company']),
                _infoRow("Location", job['location']),
                _infoRow("Type", job['type']),
                _infoRow("Salary", job['salary']),
                _infoRow("Experience", job['experience']),
                _infoRow("Deadline", job['deadline']),
                const SizedBox(height: 12),
                const Text("Description:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(job['description']),
                const SizedBox(height: 12),
                const Text("Requirements:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(job['requirements']),
                const SizedBox(height: 30),
                Center(
                  child: alreadyApplied
                      ? Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check,
                            color: Colors.black),
                        label: const Text(
                          'Already Applied',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _viewSubmittedCV(
                            user!.uid, context), // safe because user != null
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("View Submitted CV"),
                      ),
                    ],
                  )
                      : ElevatedButton.icon(
                    onPressed: () {
                      print("Apply with CV button pressed.");
                      _applyForJob(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Apply with CV',
                        style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
