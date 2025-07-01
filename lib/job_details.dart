import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailsPage extends StatefulWidget {
  final String jobId;
  const JobDetailsPage({super.key, required this.jobId});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  bool _isApplying = false;
  bool _isViewingCV = false;

  Future<void> _applyForJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("You must be logged in to apply");
      return;
    }

    setState(() => _isApplying = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final cvUrl = userDoc.data()?['cvUrl'] ?? '';

      if (cvUrl.isEmpty) {
        _showSnackBar("Please upload your CV first");
        return;
      }

      // Add to applicants list
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({
        'applicants': FieldValue.arrayUnion([user.uid])
      });

      // Create application record
      await FirebaseFirestore.instance.collection('applications').add({
        'jobId': widget.jobId,
        'userId': user.uid,
        'cvUrl': cvUrl,
        'appliedAt': Timestamp.now(),
      });

      _showSnackBar("Application submitted successfully!");
      if (mounted) setState(() {});
    } catch (e) {
      _showSnackBar("Failed to apply: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _viewSubmittedCV() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isViewingCV = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final cvUrl = userDoc.data()?['cvUrl'] ?? '';
      if (cvUrl.isEmpty) {
        _showSnackBar("No CV found");
        return;
      }

      final uri = Uri.parse(cvUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Could not open CV");
      }
    } catch (e) {
      _showSnackBar("Error viewing CV: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isViewingCV = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Job not found'));
          }

          final job = snapshot.data!;
          final user = FirebaseAuth.instance.currentUser;
          final applicants = List<String>.from(job['applicants'] ?? []);
          final alreadyApplied = user != null && applicants.contains(user.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Header
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company'],
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(job['type']),
                              backgroundColor: Colors.blue.shade100,
                            ),
                            Chip(
                              label: Text(job['experience']),
                              backgroundColor: Colors.green.shade100,
                            ),
                            Chip(
                              label: Text(job['salary']),
                              backgroundColor: Colors.amber.shade100,
                            ),
                            Chip(
                              label: Text(job['location']),
                              backgroundColor: Colors.purple.shade100,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Deadline
                _buildInfoCard(
                  '',
                  job['deadline'],
                ),

                // Job Description
                _buildSectionTitle('Job Description'),
                _buildInfoCard(
                  '',
                  job['description']
                ),

                // Requirements
                _buildSectionTitle('Requirements'),
                _buildInfoCard(
                  '',
                  job['requirements'],
                ),

                // Apply Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: alreadyApplied
                        ? Column(
                      children: [
                        ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Already Applied',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isViewingCV ? null : _viewSubmittedCV,
                          icon: _isViewingCV
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.picture_as_pdf),
                          label: const Text('View Submitted CV'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    )
                        : ElevatedButton.icon(
                      onPressed: _isApplying ? null : _applyForJob,
                      icon: _isApplying
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send),
                      label: Text(
                        _isApplying ? 'Applying...' : 'Apply with CV',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}