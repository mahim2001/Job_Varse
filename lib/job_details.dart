import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class JobDetailsPage extends StatefulWidget {
  final String jobId;
  const JobDetailsPage({super.key, required this.jobId});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  bool _isApplying = false;
  bool _isViewingCV = false;

  Future<void> _showApplyConfirmation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("You must be logged in to apply");
      return;
    }

    setState(() => _isApplying = true);

    try {
      final cvSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cvs')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();

      if (cvSnapshot.docs.isEmpty) {
        _showSnackBar("Please upload your CV before applying");
        return;
      }

      final cvData = cvSnapshot.docs.first.data();
      final cvName = cvData['name'] ?? 'your CV';

      setState(() => _isApplying = false);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Application"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("You are about to apply with:"),
              const SizedBox(height: 8),
              Text(
                cvName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text("Are you sure you want to apply?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: const Text("Apply Now"),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _applyForJob(cvData);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
      setState(() => _isApplying = false);
    }
  }

  Future<void> _applyForJob(Map<String, dynamic> cvData) async {
    final user = FirebaseAuth.instance.currentUser!;

    setState(() => _isApplying = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final jobRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) throw Exception("Job no longer exists");

        transaction.update(jobRef, {
          'applicants': FieldValue.arrayUnion([user.uid])
        });

        transaction.set(
          FirebaseFirestore.instance.collection('applications').doc(),
          {
            'jobId': widget.jobId,
            'userId': user.uid,
            'cvUrl': cvData['url'],
            'cvName': cvData['name'],
            'cvType': cvData['fileType'],
            'cvSize': cvData['size'],
            'appliedAt': Timestamp.now(),
            'status': 'submitted',
          },
        );
      });

      _showSnackBar("Application submitted successfully!");
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
      final cvSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cvs')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();

      if (cvSnapshot.docs.isEmpty) {
        _showSnackBar("No uploaded CV found");
        return;
      }

      final cvUrl = cvSnapshot.docs.first['url'];
      if (await canLaunchUrl(Uri.parse(cvUrl))) {
        await launchUrl(
          Uri.parse(cvUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception("Could not launch URL");
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: Colors.grey.shade800),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  DateTime _parseDeadline(dynamic deadline) {
    if (deadline is Timestamp) {
      return deadline.toDate();
    } else if (deadline is String) {
      return DateTime.parse(deadline);
    } else {
      return DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Job not found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Jobs'),
                  ),
                ],
              ),
            );
          }

          final job = snapshot.data!;
          final user = FirebaseAuth.instance.currentUser;
          final applicants = List<String>.from(job['applicants'] ?? []);
          final alreadyApplied = user != null && applicants.contains(user.uid);
          final deadline = _parseDeadline(job['deadline']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Header
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company'],
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildDetailChip(
                              Icons.work_outline,
                              job['type'],
                              Colors.blue,
                            ),
                            _buildDetailChip(
                              Icons.star_outline,
                              job['experience'],
                              Colors.orange,
                            ),
                            _buildDetailChip(
                              Icons.attach_money,
                              job['salary'],
                              Colors.green,
                            ),
                            _buildDetailChip(
                              Icons.location_on_outlined,
                              job['location'],
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Deadline
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Application Deadline:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(deadline),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Job Description
                _buildInfoSection('Job Description', job['description']),

                // Requirements
                _buildInfoSection('Requirements', job['requirements']),

                // Apply Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: alreadyApplied
                        ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade100,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Application Submitted',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
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
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : const Icon(Icons.picture_as_pdf),
                          label: const Text('View Submitted CV'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                                color: Colors.blue.shade400),
                          ),
                        ),
                      ],
                    )
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isApplying ? null : _showApplyConfirmation,
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
                          _isApplying ? 'Applying...' : 'Apply Now',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
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