import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminViewApplicantsPage extends StatefulWidget {
  final String jobId;
  const AdminViewApplicantsPage({super.key, required this.jobId});

  @override
  State<AdminViewApplicantsPage> createState() => _AdminViewApplicantsPageState();
}

class _AdminViewApplicantsPageState extends State<AdminViewApplicantsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _jobTitle;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final jobSnapshot = await _firestore.collection('jobs').doc(widget.jobId).get();

      if (!jobSnapshot.exists) {
        throw Exception('Job not found');
      }

      _jobTitle = jobSnapshot['title'];
      final applicantIds = List<String>.from(jobSnapshot['applicants'] ?? []);
      final shortlistedIds = List<String>.from(jobSnapshot['shortlisted'] ?? []);

      final List<Map<String, dynamic>> applicants = [];

      for (final uid in applicantIds) {
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final cvDoc = await _firestore.collection('cvUploads').doc(uid).get();

          applicants.add({
            'uid': uid,
            'name': userData['name'] ?? 'No name',
            'email': userData['email'] ?? 'No email',
            'phone': userData['phone'] ?? 'No phone',
            'experience': userData['experience'] ?? 'N/A',
            'shortlisted': shortlistedIds.contains(uid),
            'cvUrl': cvDoc.data()?['cvUrl'],
          });
        }
      }

      setState(() {
        _applicants = applicants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load applicants: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _shortlistApplicant(String userId) async {
    try {
      setState(() => _isProcessing = true);

      // Update job document
      await _firestore.collection('jobs').doc(widget.jobId).update({
        'shortlisted': FieldValue.arrayUnion([userId])
      });

      // Create notification
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Shortlisted for $_jobTitle',
        'message': 'Congratulations! You\'ve been shortlisted for: $_jobTitle',
        'jobId': widget.jobId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await _loadApplicants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applicant shortlisted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to shortlist: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _viewCV(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CV available for this applicant')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch the URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open CV: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              applicant['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${applicant['email']}'),
            Text('Phone: ${applicant['phone']}'),
            Text('Experience: ${applicant['experience']}'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text('View CV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _viewCV(applicant['cvUrl']),
                ),
                const Spacer(),
                if (applicant['shortlisted'])
                  const Chip(
                    label: Text('Shortlisted'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                else
                  ElevatedButton.icon(
                    icon: _isProcessing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.star, size: 20),
                    label: const Text('Shortlist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _shortlistApplicant(applicant['uid']),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplicants,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _applicants.isEmpty
          ? const Center(child: Text('No applicants yet'))
          : RefreshIndicator(
        onRefresh: _loadApplicants,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: _applicants.length,
          itemBuilder: (context, index) {
            return _buildApplicantCard(_applicants[index]);
          },
        ),
      ),
    );
  }
}