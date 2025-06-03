import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminJobPostPage extends StatefulWidget {
  const AdminJobPostPage({super.key, required Map<String, dynamic> initialData, required String jobId});

  @override
  State<AdminJobPostPage> createState() => _AdminJobPostPageState();
}

class _AdminJobPostPageState extends State<AdminJobPostPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final requirementsController = TextEditingController();
  final deadlineController = TextEditingController();

  String selectedType = 'Full-Time';
  String selectedExperience = 'Entry';
  String selectedSalary = 'Below 20k';

  final List<String> jobTypes = ['Full-Time', 'Part-Time', 'Remote', 'Contract'];
  final List<String> experienceLevels = ['Entry', 'Mid', 'Senior'];
  final List<String> salaryRanges = ['Below 20k', '20k-50k', '50k-100k', 'Above 100k'];

  bool _isSubmitting = false;

  Future<void> _submitJobPost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) throw Exception("Admin not logged in.");

      await FirebaseFirestore.instance.collection('jobs').add({
        'title': titleController.text.trim(),
        'company': companyController.text.trim(),
        'location': locationController.text.trim(),
        'type': selectedType,
        'salary': selectedSalary,
        'experience': selectedExperience,
        'description': descriptionController.text.trim(),
        'requirements': requirementsController.text.trim(),
        'deadline': deadlineController.text.trim(),
        'createdAt': Timestamp.now(),
        'adminId': adminId,
        'applicants': [],
        'shortlisted': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job posted successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDeadlineDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (selectedDate != null) {
      deadlineController.text =
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Job"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(titleController, "Job Title"),
              _buildField(companyController, "Company Name"),
              _buildField(locationController, "Location"),
              _buildDropdown("Job Type", jobTypes, selectedType, (val) => setState(() => selectedType = val!)),
              _buildDropdown("Experience Level", experienceLevels, selectedExperience, (val) => setState(() => selectedExperience = val!)),
              _buildDropdown("Salary Range", salaryRanges, selectedSalary, (val) => setState(() => selectedSalary = val!)),
              _buildField(descriptionController, "Job Description", maxLines: 6),
              _buildField(requirementsController, "Requirements", maxLines: 3),
              TextFormField(
                controller: deadlineController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Application Deadline",
                  border: OutlineInputBorder(),
                ),
                onTap: _pickDeadlineDate,
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter deadline date' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: _isSubmitting ? null : _submitJobPost,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text("Post Job", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {int maxLines = 1, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Please enter $label' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      ),
    );
  }
}
