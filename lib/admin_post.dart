import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminJobPostPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String jobId;

  const AdminJobPostPage({
    super.key,
    required this.initialData,
    required this.jobId
  });

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
  bool get _isEditing => widget.jobId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.initialData.isNotEmpty) {
      titleController.text = widget.initialData['title'] ?? '';
      companyController.text = widget.initialData['company'] ?? '';
      locationController.text = widget.initialData['location'] ?? '';
      descriptionController.text = widget.initialData['description'] ?? '';
      requirementsController.text = widget.initialData['requirements'] ?? '';
      deadlineController.text = widget.initialData['deadline'] ?? '';
      selectedType = widget.initialData['type'] ?? 'Full-Time';
      selectedExperience = widget.initialData['experience'] ?? 'Entry';
      selectedSalary = widget.initialData['salary'] ?? 'Below 20k';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    companyController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    requirementsController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

  Future<void> _submitJobPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) throw Exception("Admin not logged in");

      final jobData = {
        'title': titleController.text.trim(),
        'company': companyController.text.trim(),
        'location': locationController.text.trim(),
        'type': selectedType,
        'salary': selectedSalary,
        'experience': selectedExperience,
        'description': descriptionController.text.trim(),
        'requirements': requirementsController.text.trim(),
        'deadline': deadlineController.text.trim(),
        'updatedAt': Timestamp.now(),
        'adminId': adminId,
      };

      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .update(jobData);
      } else {
        jobData['createdAt'] = Timestamp.now();
        jobData['applicants'] = [];
        jobData['shortlisted'] = [];
        await FirebaseFirestore.instance.collection('jobs').add(jobData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? "Job updated!" : "Job posted!"),
        ),
      );
      Navigator.pop(context, jobData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDeadlineDate() async {
    final initialDate = deadlineController.text.isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(deadlineController.text)
        : DateTime.now().add(const Duration(days: 30));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      deadlineController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Job" : "Post New Job"),centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(titleController, "Job Title"),
              _buildField(companyController, "Company Name"),
              _buildField(locationController, "Location"),
              _buildDropdown("Job Type", jobTypes, selectedType,
                      (val) => setState(() => selectedType = val!)),
              _buildDropdown("Experience", experienceLevels, selectedExperience,
                      (val) => setState(() => selectedExperience = val!)),
              _buildDropdown("Salary", salaryRanges, selectedSalary,
                      (val) => setState(() => selectedSalary = val!)),
              _buildField(descriptionController, "Description", maxLines: 5),
              _buildField(requirementsController, "Requirements", maxLines: 3),
              TextFormField(
                controller: deadlineController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Deadline",
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: _pickDeadlineDate,
                validator: (val) =>
                val == null || val.isEmpty ? 'Select deadline' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJobPost,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : Text(_isEditing ? "Update Job" : "Post Job",
                  style: TextStyle(fontSize: 16, color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (val) =>
        val == null || val.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
      ),
    );
  }
}