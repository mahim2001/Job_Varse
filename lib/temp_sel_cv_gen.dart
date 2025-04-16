import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CVTemplateSelector extends StatelessWidget {
  final Map<String, dynamic> data;

  const CVTemplateSelector({super.key, required this.data});


  void _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(data['name'] ?? '', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text("Email: ${data['email']}"),
            pw.Text("Phone: ${data['phone']}"),
            pw.SizedBox(height: 10),
            pw.Text("Education: ${data['education']}"),
            pw.Text("Experience: ${data['experience']}"),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/cv.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Template")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _generatePDF(context),
          child: const Text("Generate and Download CV"),
        ),
      ),
    );
  }
}
