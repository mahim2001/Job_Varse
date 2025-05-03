import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jobvarse_bd/temp_sel_cv_gen.dart';

class GenerateCVPage extends StatefulWidget {
  const GenerateCVPage({super.key});

  @override
  State<GenerateCVPage> createState() => _GenerateCVPageState();
}

class _GenerateCVPageState extends State<GenerateCVPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _cvData = {};
  List<Map<String, String>> workExperiences = [{}];
  bool showMastersFields = false;

  final ImagePicker picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;

  final User user = FirebaseAuth.instance.currentUser!;

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Upload profile image if available
      String? imageUrl;
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref('profile_images/${user.uid}.jpg');
        await storageRef.putFile(_profileImage!);
        imageUrl = await storageRef.getDownloadURL();
        _cvData['profileImage'] = imageUrl;
      }

      _cvData['workExperiences'] = workExperiences;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CVTemplateSelector(data: _cvData),
        ),
      );
    }
  }

  Widget buildTextField(String label, String key, {int maxLines = 1}) {
    TextEditingController controller = TextEditingController(
      text: key == "dob" && _cvData[key] != null ? _cvData[key] : '',
    );

    if (key == "dob") {
      return TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(labelText: label),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            String formattedDate =
                "${picked.day}/${picked.month}/${picked.year}";
            setState(() {
              _cvData[key] = formattedDate;
              controller.text = formattedDate;
            });
          }
        },
      );
    } else {
      return TextFormField(
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        onSaved: (val) => _cvData[key] = val!,
      );
    }
  }

  Widget buildExperienceFields(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Experience ${index + 1}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          decoration: const InputDecoration(labelText: "Job Title"),
          onSaved: (val) => workExperiences[index]['title'] = val ?? '',
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: "Company"),
          onSaved: (val) => workExperiences[index]['company'] = val ?? '',
        ),
        TextFormField(
          decoration: const InputDecoration(
              labelText: "Duration (e.g., Jan 2020 - Dec 2022)"),
          onSaved: (val) => workExperiences[index]['duration'] = val ?? '',
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  void addExperience() {
    setState(() {
      workExperiences.add({});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Your CV Information")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
            ),
              const SizedBox(height: 16),
              const Text("🔹 Personal Information",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              buildTextField("Full Name", "name"),
              buildTextField("Email", "email"),
              buildTextField("Phone", "phone"),
              buildTextField("Date of Birth", "dob"),
              buildTextField("Address", "address"),
              const SizedBox(height: 16),

              const Text("🔹 Education",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("SSC",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              buildTextField("School Name", "ssc_school"),
              buildTextField("Group", "ssc_group"),
              buildTextField("Board", "ssc_board"),
              buildTextField("Passing Year", "ssc_year"),
              buildTextField("Result", "ssc_result"),

              const SizedBox(height: 8),
              const Text("HSC",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              buildTextField("College Name", "hsc_college"),
              buildTextField("Group", "hsc_group"),
              buildTextField("Board", "hsc_board"),
              buildTextField("Passing Year", "hsc_year"),
              buildTextField("Result", "hsc_result"),

              const SizedBox(height: 8),
              const Text("Bachelor’s",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              buildTextField("Subject", "bachelor_subject"),
              buildTextField("University", "bachelor_university"),
              buildTextField("Passing Year", "bachelor_year"),
              buildTextField("Result", "bachelor_result"),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Master’s (Optional)",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Switch(
                    value: showMastersFields,
                    onChanged: (val) {
                      setState(() => showMastersFields = val);
                    },
                  )
                ],
              ),
              if (showMastersFields) ...[
                buildTextField("Subject", "masters_subject"),
                buildTextField("University", "masters_university"),
                buildTextField("Passing Year", "masters_year"),
                buildTextField("Result", "masters_result"),
              ],
              const SizedBox(height: 16),

              const Text("🔹 Work Experience",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (int i = 0; i < workExperiences.length; i++)
                buildExperienceFields(i),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: addExperience,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Experience"),
                ),
              ),
              buildTextField("Total Years of Experience", "experienceYears"),
              const SizedBox(height: 16),

              const Text("🔹 Skills & Others",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              buildTextField("Skills (e.g., Programming, Communication)", "skills"),
              buildTextField("Languages", "languages"),
              buildTextField("Certifications (Optional)", "certifications"),
              buildTextField("Projects or Achievements", "projects", maxLines: 3),
              const SizedBox(height: 16),

              const Text("🔹 Reference",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              buildTextField("Reference Name, Designation, Contact", "reference",
                  maxLines: 2),
              const SizedBox(height: 20),

              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text("Next: Select Template"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
