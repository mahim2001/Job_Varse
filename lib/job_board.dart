import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_details.dart';

class JobBoardPage extends StatefulWidget {
  const JobBoardPage({super.key});

  @override
  State<JobBoardPage> createState() => _JobBoardPageState();
}

class _JobBoardPageState extends State<JobBoardPage> {
  String searchQuery = '';
  String selectedType = 'All';
  String selectedExperience = 'All';
  String selectedSalary = 'All';

  final List<String> jobTypes = ['All', 'Full-Time', 'Part-Time', 'Remote', 'Contract'];
  final List<String> experienceLevels = ['All', 'Entry', 'Mid', 'Senior'];
  final List<String> salaryRanges = ['All', 'Below 20k', '20k-50k', '50k-100k', 'Above 100k'];

  bool _matchesFilters(Map<String, dynamic> job) {
    final title = job['title'].toString().toLowerCase();
    final company = job['company'].toString().toLowerCase();

    final matchesSearch = searchQuery.isEmpty ||
        title.contains(searchQuery.toLowerCase()) ||
        company.contains(searchQuery.toLowerCase());
    final matchesType = selectedType == 'All' || job['type'] == selectedType;
    final matchesExperience = selectedExperience == 'All' || job['experience'] == selectedExperience;

    final salaryStr = job['salary'].toString().replaceAll(RegExp(r'[^\d]'), '');
    final salary = int.tryParse(salaryStr) ?? 0;

    bool matchesSalary = true;
    switch (selectedSalary) {
      case 'Below 20k':
        matchesSalary = salary < 20000;
        break;
      case '20k-50k':
        matchesSalary = salary >= 20000 && salary <= 50000;
        break;
      case '50k-100k':
        matchesSalary = salary > 50000 && salary <= 100000;
        break;
      case 'Above 100k':
        matchesSalary = salary > 100000;
        break;
    }

    return matchesSearch && matchesType && matchesExperience && matchesSalary;
  }

  Color _getJobTypeColor(String type) {
    switch (type) {
      case 'Full-Time':
        return Colors.blue.shade100;
      case 'Part-Time':
        return Colors.green.shade100;
      case 'Remote':
        return Colors.purple.shade100;
      case 'Contract':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Job Board', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Type', selectedType, jobTypes),
                      const SizedBox(width: 2),
                      _buildFilterChip('Experience', selectedExperience, experienceLevels),
                      const SizedBox(width: 2),
                      _buildFilterChip('Salary', selectedSalary, salaryRanges),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Job Listings
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final jobs = snapshot.data!.docs
                    .where((doc) => _matchesFilters(doc.data() as Map<String, dynamic>))
                    .toList();

                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              selectedType = 'All';
                              selectedExperience = 'All';
                              selectedSalary = 'All';
                            });
                          },
                          child: const Text('Reset filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final data = job.data() as Map<String, dynamic>;
                    return _buildJobCard(data, job.id, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedValue, List<String> options) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          if (label == 'Type') selectedType = value;
          if (label == 'Experience') selectedExperience = value;
          if (label == 'Salary') selectedSalary = value;
        });
      },
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: ListTile(
            title: Text(option),
            trailing: selectedValue == option
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${selectedValue == 'All' ? 'Any' : selectedValue}',
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> data, String jobId, BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailsPage(jobId: jobId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Company Logo Placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['company'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.work_outline,
                    data['type'],
                    _getJobTypeColor(data['type']),
                  ),
                  _buildInfoChip(
                    Icons.star_outline,
                    data['experience'],
                    Colors.amber.shade100,
                  ),
                  _buildInfoChip(
                    Icons.attach_money,
                    data['salary'],
                    Colors.green.shade100,
                  ),
                  _buildInfoChip(
                    Icons.location_on_outlined,
                    data['location'],
                    Colors.blue.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deadline: ${data['deadline']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsPage(jobId: jobId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}