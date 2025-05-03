import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'cv_templates/template_1.dart';
import 'cv_templates/template_2.dart';
import 'cv_templates/template_3.dart';
import 'cv_templates/template_4.dart';
import 'cv_templates/template_5.dart';


class CVTemplateSelector extends StatelessWidget {
  final Map<String, dynamic> data;

  const CVTemplateSelector({Key? key, required this.data}) : super(key: key);

  // Navigate to a visual CV template screen
  void _navigateToTemplate(BuildContext context, Widget template) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => template),
    );
  }

  // Generate and print a simple formatted PDF
  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(data['name'] ?? '', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text("Email: ${data['email']}"),
              pw.Text("Phone: ${data['phone']}"),
              pw.SizedBox(height: 10),
              pw.Text("Date of Birth: ${data['dob']}"),
              pw.Text("Address: ${data['address']}"),
              pw.SizedBox(height: 10),

              pw.Text("Education", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: "SSC: ${data['ssc_school']}, ${data['ssc_board']} (${data['ssc_year']}) - ${data['ssc_result']}"),
              pw.Bullet(text: "HSC: ${data['hsc_college']}, ${data['hsc_board']} (${data['hsc_year']}) - ${data['hsc_result']}"),
              pw.Bullet(text: "Bachelor: ${data['bachelor_subject']} - ${data['bachelor_university']} (${data['bachelor_year']}) - ${data['bachelor_result']}"),
              if (data['masters_subject'] != null && data['masters_subject'].toString().isNotEmpty)
                pw.Bullet(text: "Masters: ${data['masters_subject']} - ${data['masters_university']} (${data['masters_year']}) - ${data['masters_result']}"),

              pw.SizedBox(height: 10),
              pw.Text("Experience", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (data['workExperiences'] != null)
                for (var exp in data['workExperiences'])
                  if ((exp['title'] ?? '').isNotEmpty)
                    pw.Column(children: [
                      pw.Text("${exp['title']} at ${exp['company']} (${exp['duration']})"),
                      pw.SizedBox(height: 4),
                    ]),

              pw.SizedBox(height: 10),
              pw.Text("Skills: ${data['skills']}"),
              pw.Text("Languages: ${data['languages']}"),
              pw.Text("Certifications: ${data['certifications'] ?? 'N/A'}"),
              pw.Text("Projects: ${data['projects']}"),
              pw.Text("Reference: ${data['reference']}"),
            ],
          ),
        ),
      ),
    );

    // Save to file and trigger print
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/cv.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select CV Template"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          ElevatedButton(
            onPressed: () => _navigateToTemplate(context, CVTemplate1(data: data)),
            child: const Text("Template 1 - Classic"),
          ),
          ElevatedButton(
            onPressed: () => _navigateToTemplate(context, CVTemplate2(data: data)),
            child: const Text("Template 2 - Modern"),
          ),
          ElevatedButton(
            onPressed: () => _navigateToTemplate(context, CVTemplate3(data: data)),
            child: const Text("Template 3 - Clean Two-Column"),
          ),
          ElevatedButton(
            onPressed: () => _navigateToTemplate(context, CVTemplate4(data: data)),
            child: const Text("Template 4 - Elegant"),
          ),
          ElevatedButton(
            onPressed: () => _navigateToTemplate(context, CVTemplate5(data: data)),
            child: const Text("Template 5 - Professional"),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _generatePDF(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Generate and Download CV (PDF)"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}
