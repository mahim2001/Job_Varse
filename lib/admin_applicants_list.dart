import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminViewApplicantsPage extends StatelessWidget {
  final String jobId;
  const AdminViewApplicantsPage({super.key, required this.jobId});

  Future<List<Map<String, dynamic>>> _fetchApplicants(String jobId) async {
    final jobSnapshot = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final applicantIds = List<String>.from(jobSnapshot['applicants']);
    final shortlistedIds = List<String>.from(jobSnapshot['shortlisted']);

    List<Map<String, dynamic>> applicants = [];

    for (final uid in applicantIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data()!;
      data['uid'] = uid;
      data['shortlisted'] = shortlistedIds.contains(uid);
      applicants.add(data);
    }

    return applicants;
  }

  Future<void> shortlistUser(String jobId, String userId, String jobTitle) async {
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
    final notificationRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').doc();

    await jobRef.update({
      'shortlisted': FieldValue.arrayUnion([userId])
    });

    await notificationRef.set({
      'title': 'You have been shortlisted!',
      'message': 'Congratulations! You have been shortlisted for the job: $jobTitle',
      'jobId': jobId,
      'isRead': false,
      'timestamp': Timestamp.now(),
    });

    // Send email (see step 3)
  }


  Future<void> _shortlistApplicant(String jobId, String userId) async {
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
    await jobRef.update({
      'shortlisted': FieldValue.arrayUnion([userId])
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants")),
      body: FutureBuilder(
        future: _fetchApplicants(jobId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final applicants = snapshot.data!;

          if (applicants.isEmpty) {
            return const Center(child: Text("No applicants yet."));
          }

          return ListView.builder(
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(applicant['name'] ?? "No name"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${applicant['email']}"),
                      Text("Phone: ${applicant['phone']}"),
                      Text("Experience: ${applicant['experience'] ?? 'N/A'}"),
                    ],
                  ),
                  trailing: applicant['shortlisted']
                      ? const Chip(label: Text("Shortlisted"))
                      : ElevatedButton(
                    onPressed: () async {
                      await _shortlistApplicant(jobId, applicant['uid']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Applicant shortlisted!")),
                      );
                      // Force refresh
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminViewApplicantsPage(jobId: jobId),
                        ),
                      );
                    },
                    child: const Text("Shortlist"),
                  ),
                  onTap: () {
                    // Optional: Show full profile or download CV
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
