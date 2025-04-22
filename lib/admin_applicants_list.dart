import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminViewApplicantsPage extends StatelessWidget {
  final String jobId;
  const AdminViewApplicantsPage({super.key, required this.jobId});

  Future<List<Map<String, dynamic>>> _fetchApplicants(String jobId) async {
    final jobSnapshot = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final applicantIds = List<String>.from(jobSnapshot['applicants']);
    final shortlistedIds = List<String>.from(jobSnapshot['shortlisted']);
    final jobTitle = jobSnapshot['title'];

    List<Map<String, dynamic>> applicants = [];

    for (final uid in applicantIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data()!;
      data['uid'] = uid;
      data['shortlisted'] = shortlistedIds.contains(uid);
      data['jobTitle'] = jobTitle;
      applicants.add(data);
    }

    return applicants;
  }

  Future<void> _shortlistAndNotify(String jobId, String userId, String jobTitle) async {
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();

    // Update job shortlist
    await jobRef.update({
      'shortlisted': FieldValue.arrayUnion([userId])
    });

    // Send in-app notification
    await notificationRef.set({
      'title': 'You have been shortlisted!',
      'message': '🎉 Congratulations! You’ve been shortlisted for the job: $jobTitle',
      'jobId': jobId,
      'isRead': false,
      'timestamp': Timestamp.now(),
    });

    // TODO: Optionally trigger email notification via backend or Firebase Function
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants"),centerTitle: true,),
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
                      await _shortlistAndNotify(
                        jobId,
                        applicant['uid'],
                        applicant['jobTitle'],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Applicant shortlisted!")),
                      );
                      // Refresh the page by rebuilding
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminViewApplicantsPage(jobId: jobId),
                        ),
                      );
                    },
                    child: const Text("Shortlist"),
                  ),
                  onTap: () {
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
