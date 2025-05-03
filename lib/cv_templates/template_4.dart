import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CVTemplate4 extends StatefulWidget {
  final Map<String, dynamic> data;

  const CVTemplate4({super.key, required this.data});

  @override
  State<CVTemplate4> createState() => _CVTemplate4State();
}

class _CVTemplate4State extends State<CVTemplate4> {
  final GlobalKey _previewContainer = GlobalKey();

  Future<void> _captureAndPrintWidget() async {
    try {
      RenderRepaintBoundary boundary =
      _previewContainer.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Center(child: pw.Image(imageProvider)),
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'cv_template4.pdf');
    } catch (e) {
      print("Error while printing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CV Template 4 - Elegant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _captureAndPrintWidget,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _previewContainer,
          child: Container(
            color: Colors.white,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (data['image'] != null && data['image'].isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(data['image']),
                    radius: 50,
                  ),
                const SizedBox(height: 10),
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(data['email'] ?? ''),
                Text(data['phone'] ?? ''),
                const SizedBox(height: 6),
                Text("DOB: ${data['dob']}  |  ${data['address']}"),
                const Divider(thickness: 1.5),

                sectionTitle("🎓 Education"),
                Text("SSC: ${data['ssc_school']} (${data['ssc_year']}) - ${data['ssc_result']}"),
                Text("HSC: ${data['hsc_college']} (${data['hsc_year']}) - ${data['hsc_result']}"),
                Text("Bachelor: ${data['bachelor_subject']} - ${data['bachelor_university']} (${data['bachelor_year']})"),
                if (data['masters_subject'] != null && data['masters_subject'] != '')
                  Text("Masters: ${data['masters_subject']} - ${data['masters_university']} (${data['masters_year']})"),

                const SizedBox(height: 10),
                sectionTitle("💼 Work Experience"),
                if (data['workExperiences'] != null)
                  ...List.generate(data['workExperiences'].length, (index) {
                    final exp = data['workExperiences'][index];
                    if ((exp['title'] ?? '').isEmpty) return const SizedBox();
                    return Text("• ${exp['title']} at ${exp['company']} (${exp['duration']})");
                  }),
                Text("Total Experience: ${data['experienceYears']} years"),

                const SizedBox(height: 10),
                sectionTitle("🛠 Skills & Languages"),
                Text("Skills: ${data['skills']}"),
                Text("Languages: ${data['languages']}"),

                const SizedBox(height: 10),
                sectionTitle("📜 Certifications & Projects"),
                Text("Certifications: ${data['certifications'] ?? 'N/A'}"),
                Text("Projects: ${data['projects']}"),

                const SizedBox(height: 10),
                sectionTitle("📞 Reference"),
                Text(data['reference'] ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}
