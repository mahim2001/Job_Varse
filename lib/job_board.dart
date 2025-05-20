import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

    final matchesSearch = title.contains(searchQuery) || company.contains(searchQuery);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Board'), centerTitle: true,backgroundColor: Colors.blue,),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search by title or company',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _dropdown("Type", jobTypes, selectedType, (val) {
                      setState(() => selectedType = val!);
                    }),
                    const SizedBox(width: 5),
                    _dropdown("Exp", experienceLevels, selectedExperience, (val) {
                      setState(() => selectedExperience = val!);
                    }),
                    const SizedBox(width: 5),
                    _dropdown("Salary", salaryRanges, selectedSalary, (val) {
                      setState(() => selectedSalary = val!);
                    }),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final jobs = snapshot.data!.docs
                    .where((doc) => _matchesFilters(doc.data() as Map<String, dynamic>))
                    .toList();

                if (jobs.isEmpty) {
                  return const Center(child: Text("No jobs found."));
                }

                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final data = job.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _infoRow("Company", data['company']),
                              _infoRow("Location", data['location']),
                              _infoRow("Type", data['type']),
                              _infoRow("Deadline", data['deadline']),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JobDetailsPage(jobId: job.id),
                                      ),
                                    );
                                  },
                                  child: const Text("View Details"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: const OutlineInputBorder(),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      ),
    );
  }
}
