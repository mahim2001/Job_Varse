import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminJobBoard extends StatelessWidget {
  const AdminJobBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Job Board"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No job posts available."));
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(job['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Company: ${job['company']}"),
                      Text("Location: ${job['location']}"),
                      Text("Type: ${job['type']}"),
                      Text("Deadline: ${job['deadline']}"),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsPage(jobData: job),
                      ),
                    );
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

class JobDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot jobData;
  const JobDetailsPage({super.key, required this.jobData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(jobData['title'] ?? "Job Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _info("Company", jobData['company']),
            _info("Location", jobData['location']),
            _info("Type", jobData['type']),
            _info("Salary", jobData['salary']),
            _info("Experience", jobData['experience']),
            _info("Deadline", jobData['deadline']),
            _info("Description", jobData['description']),
            _info("Requirements", jobData['requirements']),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const Divider(),
        ],
      ),
    );
  }
}
