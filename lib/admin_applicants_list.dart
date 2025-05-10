import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this for opening URLs

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

    await jobRef.update({
      'shortlisted': FieldValue.arrayUnion([userId])
    });

    await notificationRef.set({
      'title': 'You have been shortlisted!',
      'message': '🎉 Congratulations! You’ve been shortlisted for the job: $jobTitle',
      'jobId': jobId,
      'isRead': false,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _launchCV(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants"), centerTitle: true),
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
              final cvUrl = applicant['cvUrl'] ?? '';

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
                      const SizedBox(height: 8),
                      if (cvUrl.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _launchCV(cvUrl),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("View CV"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        )
                      else
                        const Text("No CV uploaded."),
                      const SizedBox(height: 6),
                      if (!applicant['shortlisted'])
                        ElevatedButton(
                          onPressed: () async {
                            await _shortlistAndNotify(
                              jobId,
                              applicant['uid'],
                              applicant['jobTitle'],
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Applicant shortlisted!")),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminViewApplicantsPage(jobId: jobId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text("Shortlist",style: TextStyle(color: Colors.black),),
                        )
                      else
                        const Chip(label: Text("Shortlisted")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
