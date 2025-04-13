import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JobDetailsPage extends StatelessWidget {
  final String jobId;
  const JobDetailsPage({super.key, required this.jobId});

  Future<void> _applyForJob(BuildContext context, String jobId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);

    await jobRef.update({
      'applicants': FieldValue.arrayUnion([user.uid])
    });

    // Optional: Save the application in a separate collection
    await FirebaseFirestore.instance.collection('applications').add({
      'jobId': jobId,
      'userId': user.uid,
      'appliedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Application submitted!")),
    );
    Navigator.pop(context);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final job = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _infoRow("Company", job['company']),
                _infoRow("Location", job['location']),
                _infoRow("Type", job['type']),
                _infoRow("Salary", job['salary']),
                _infoRow("Experience", job['experience']),
                _infoRow("Deadline", job['deadline']),
                const SizedBox(height: 12),
                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(job['description']),
                const SizedBox(height: 12),
                const Text("Requirements:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(job['requirements']),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _applyForJob(context, jobId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Apply', style: TextStyle(color: Colors.white)),
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
