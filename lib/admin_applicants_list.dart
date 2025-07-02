import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

class AdminApplicantManagementPage extends StatefulWidget {
  final String jobId;
  const AdminApplicantManagementPage({Key? key, required this.jobId}) : super(key: key);

  @override
  State<AdminApplicantManagementPage> createState() => _AdminApplicantManagementPageState();
}

class _AdminApplicantManagementPageState extends State<AdminApplicantManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Applicant> _applicants = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _jobTitle;
  String? _jobCompany;

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

      // Get job details
      final jobDoc = await _firestore.collection('jobs').doc(widget.jobId).get();
      if (!jobDoc.exists) {
        throw Exception('Job not found');
      }

      _jobTitle = jobDoc['title'];
      _jobCompany = jobDoc['company'];

      // Get all applications for this job
      final applications = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .orderBy('appliedAt', descending: true)
          .get();

      // Get shortlisted applicants
      final shortlistedIds = List<String>.from(jobDoc['shortlisted'] ?? []);

      // Process each application
      final List<Applicant> applicants = [];
      for (final doc in applications.docs) {
        final appData = doc.data();
        final userId = appData['userId'];

        // Get user profile
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;

        applicants.add(Applicant(
          applicationId: doc.id,
          userId: userId,
          name: userData['name'] ?? 'No name',
          email: userData['email'] ?? 'No email',
          phone: userData['phone'] ?? 'No phone',
          experience: userData['experience'] ?? 'Not specified',
          cvUrl: appData['cvUrl'],
          cvName: appData['cvName'],
          cvType: appData['cvType'],
          appliedAt: (appData['appliedAt'] as Timestamp).toDate(),
          isShortlisted: shortlistedIds.contains(userId),
          status: appData['status'] ?? 'submitted',
        ));
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

  Future<void> _toggleShortlist(Applicant applicant) async {
    try {
      setState(() => _isProcessing = true);

      final jobRef = _firestore.collection('jobs').doc(widget.jobId);
      final applicationRef = _firestore.collection('applications').doc(applicant.applicationId);
      final userNotificationsRef = _firestore
          .collection('users')
          .doc(applicant.userId)
          .collection('notifications');

      if (applicant.isShortlisted) {
        // Remove from shortlist
        await jobRef.update({
          'shortlisted': FieldValue.arrayRemove([applicant.userId])
        });

        // Update application status
        await applicationRef.update({
          'status': 'submitted',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Remove any existing shortlist notification
        final notificationQuery = await userNotificationsRef
            .where('jobId', isEqualTo: widget.jobId)
            .where('type', isEqualTo: 'shortlist')
            .limit(1)
            .get();

        if (notificationQuery.docs.isNotEmpty) {
          await userNotificationsRef.doc(notificationQuery.docs.first.id).delete();
        }
      } else {
        // Add to shortlist
        await jobRef.update({
          'shortlisted': FieldValue.arrayUnion([applicant.userId])
        });

        // Update application status
        await applicationRef.update({
          'status': 'shortlisted',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create notification for the applicant
        await userNotificationsRef.add({
          'title': 'Shortlisted for $_jobTitle',
          'message': '$_jobCompany has shortlisted you for: $_jobTitle',
          'jobId': widget.jobId,
          'type': 'shortlist',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Refresh the list
      await _loadApplicants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(applicant.isShortlisted
                ? 'Removed from shortlist'
                : 'Applicant shortlisted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _viewCV(Applicant applicant) async {
    if (applicant.cvUrl == null || applicant.cvUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No CV available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (applicant.cvType == 'pdf') {
      // Open in PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: applicant.cvUrl!,
            applicantName: applicant.name,
            jobTitle: _jobTitle ?? 'Job Application',
          ),
        ),
      );
    } else {
      // Open in external app for non-PDF files
      await _launchExternalViewer(applicant.cvUrl!);
    }
  }

  Future<void> _launchExternalViewer(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open CV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'shortlisted':
        color = Colors.blue;
        icon = Icons.star;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'hired':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default: // submitted
        color = Colors.grey;
        icon = Icons.hourglass_empty;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: color),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildApplicantCard(Applicant applicant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    applicant.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusIndicator(applicant.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Email: ${applicant.email}'),
            const SizedBox(height: 4),
            Text('Phone: ${applicant.phone}'),
            const SizedBox(height: 4),
            Text('Experience: ${applicant.experience}'),
            const SizedBox(height: 4),
            Text('Applied: ${DateFormat('MMM dd, yyyy - hh:mm a').format(applicant.appliedAt)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text('View CV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _viewCV(applicant),
                ),
                const Spacer(),
                IconButton(
                  icon: applicant.isShortlisted
                      ? const Icon(Icons.star, color: Colors.amber)
                      : const Icon(Icons.star_border),
                  color: applicant.isShortlisted ? Colors.amber : Colors.grey,
                  tooltip: applicant.isShortlisted
                      ? 'Remove from shortlist'
                      : 'Shortlist applicant',
                  onPressed: _isProcessing
                      ? null
                      : () => _toggleShortlist(applicant),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleStatusChange(applicant, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'shortlisted',
                      child: Text('Mark as Shortlisted'),
                    ),
                    const PopupMenuItem(
                      value: 'rejected',
                      child: Text('Mark as Rejected'),
                    ),
                    const PopupMenuItem(
                      value: 'hired',
                      child: Text('Mark as Hired'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(Applicant applicant, String newStatus) async {
    try {
      setState(() => _isProcessing = true);

      final applicationRef = _firestore.collection('applications').doc(applicant.applicationId);
      final jobRef = _firestore.collection('jobs').doc(widget.jobId);
      final userNotificationsRef = _firestore
          .collection('users')
          .doc(applicant.userId)
          .collection('notifications');

      // Update application status
      await applicationRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Handle shortlist status changes
      if (newStatus == 'shortlisted') {
        await jobRef.update({
          'shortlisted': FieldValue.arrayUnion([applicant.userId])
        });
      } else if (applicant.status == 'shortlisted') {
        await jobRef.update({
          'shortlisted': FieldValue.arrayRemove([applicant.userId])
        });
      }

      // Create notification for the applicant
      await userNotificationsRef.add({
        'title': 'Application Update for $_jobTitle',
        'message': 'Your application status has changed to: ${newStatus.toUpperCase()}',
        'jobId': widget.jobId,
        'type': 'status_update',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await _loadApplicants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_jobTitle != null
            ? 'Applicants for $_jobTitle'
            : 'Applicants Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadApplicants,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplicants,
              child: const Text('Try Again'),
            ),
          ],
        ),
      )
          : _applicants.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No applicants yet',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadApplicants,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          itemCount: _applicants.length,
          itemBuilder: (context, index) {
            return _buildApplicantCard(_applicants[index]);
          },
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String applicantName;
  final String jobTitle;

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.applicantName,
    required this.jobTitle,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 1;
  int? _totalPages;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load PDF: HTTP ${response.statusCode}');
      }

      // Create a Future<PdfDocument> as expected by PdfControllerPinch
      final pdfDocumentFuture = PdfDocument.openData(response.bodyBytes);

      // Get total pages by awaiting the future first
      final document = await pdfDocumentFuture;
      _totalPages = document.pagesCount;

      _pdfController = PdfControllerPinch(
        document: pdfDocumentFuture, // Pass the Future, not the resolved document
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.applicantName}\'s CV'),
        actions: [
          if (_totalPages != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '$_currentPage/$_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load PDF',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdf,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _pdfController != null
          ? Column(
        children: [
          Expanded(
            child: PdfViewPinch(
              controller: _pdfController!,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page + 1;
                });
              },
            ),
          ),
        ],
      )
          : const Center(child: Text('PDF controller not initialized')),
    );
  }
}

extension on PdfControllerPinch {
  get future => null;
}

class Applicant {
  final String applicationId;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String experience;
  final String? cvUrl;
  final String? cvName;
  final String? cvType;
  final DateTime appliedAt;
  final bool isShortlisted;
  final String status;

  Applicant({
    required this.applicationId,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.experience,
    this.cvUrl,
    this.cvName,
    this.cvType,
    required this.appliedAt,
    required this.isShortlisted,
    required this.status,
  });
}