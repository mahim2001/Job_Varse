import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_applicants_list.dart';

class AdminJobBoardPage extends StatelessWidget {
  const AdminJobBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Job Posts",)),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('adminId', isEqualTo: adminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final jobs = snapshot.data!.docs;

          if (jobs.isEmpty) {
            return const Center(child: Text("No job posts found."));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(job['title']),
                  subtitle: Text("Applicants: ${job['applicants'].length}"),
                  trailing: ElevatedButton(
                    child: const Text("View Applicants"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminApplicantManagementPage(jobId: job.id),
                        ),
                      );
                    },
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
