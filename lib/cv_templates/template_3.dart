import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CVTemplate3 extends StatefulWidget {
  final Map<String, dynamic> data;

  const CVTemplate3({super.key, required this.data});

  @override
  State<CVTemplate3> createState() => _CVTemplate3State();
}

class _CVTemplate3State extends State<CVTemplate3> {
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
          build: (pw.Context context) => pw.Center(child: pw.Image(imageProvider)),
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'cv_template3.pdf');
    } catch (e) {
      print("Error while printing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CV Template 3 - Clean Two-Column"),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (data['image'] != null && data['image'].isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(data['image']),
                          radius: 50,
                        ),
                      const SizedBox(height: 10),
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("Email: ${data['email']}"),
                      Text("Phone: ${data['phone']}"),
                      Text("DOB: ${data['dob']}"),
                      Text("Address: ${data['address']}"),
                      const Divider(),
                      const Text("Skills", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['skills'] ?? ''),
                      const SizedBox(height: 6),
                      const Text("Languages", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['languages'] ?? ''),
                      const SizedBox(height: 6),
                      const Text("Certifications", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['certifications'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right Column
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Education", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("SSC: ${data['ssc_school']}, ${data['ssc_board']} (${data['ssc_year']}) - ${data['ssc_result']}"),
                      Text("HSC: ${data['hsc_college']}, ${data['hsc_board']} (${data['hsc_year']}) - ${data['hsc_result']}"),
                      Text("Bachelor: ${data['bachelor_subject']}, ${data['bachelor_university']} (${data['bachelor_year']}) - ${data['bachelor_result']}"),
                      if (data['masters_subject'] != null && data['masters_subject'] != '')
                        Text("Masters: ${data['masters_subject']}, ${data['masters_university']} (${data['masters_year']}) - ${data['masters_result']}"),
                      const Divider(),
                      const Text("Work Experience", style: TextStyle(fontWeight: FontWeight.bold)),
                      if (data['workExperiences'] != null)
                        ...List.generate(data['workExperiences'].length, (index) {
                          final exp = data['workExperiences'][index];
                          if ((exp['title'] ?? '').isEmpty) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text("${exp['title']} at ${exp['company']} (${exp['duration']})"),
                          );
                        }),
                      Text("Total Experience: ${data['experienceYears']} years"),
                      const Divider(),
                      const Text("Projects / Achievements", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['projects'] ?? ''),
                      const SizedBox(height: 6),
                      const Text("Reference", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['reference'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
