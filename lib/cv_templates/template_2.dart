import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CVTemplate2 extends StatefulWidget {
  final Map<String, dynamic> data;

  const CVTemplate2({super.key, required this.data});

  @override
  State<CVTemplate2> createState() => _CVTemplate2State();
}

class _CVTemplate2State extends State<CVTemplate2> {
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

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'cv_template2.pdf');
    } catch (e) {
      print("Error while printing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CV Template 2 - Modern Sidebar"),
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
          child: Row(
            children: [
              // Sidebar
              Container(
                width: 140,
                color: Colors.blueGrey.shade50,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (data['image'] != null && data['image'].isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(data['image']),
                        radius: 40,
                      ),
                    const SizedBox(height: 10),
                    Text(data['name'] ?? '', textAlign: TextAlign.center),
                    const Divider(),
                    Text("📧 ${data['email']}"),
                    Text("📞 ${data['phone']}"),
                    Text("📍 ${data['address']}"),
                    Text("🎂 ${data['dob']}"),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🎓 Education", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("SSC: ${data['ssc_school']}, ${data['ssc_board']} (${data['ssc_year']}) - ${data['ssc_result']}"),
                      Text("HSC: ${data['hsc_college']}, ${data['hsc_board']} (${data['hsc_year']}) - ${data['hsc_result']}"),
                      Text("Bachelor: ${data['bachelor_subject']}, ${data['bachelor_university']} (${data['bachelor_year']}) - ${data['bachelor_result']}"),
                      if (data['masters_subject'] != null && data['masters_subject'] != '')
                        Text("Masters: ${data['masters_subject']}, ${data['masters_university']} (${data['masters_year']}) - ${data['masters_result']}"),

                      const Divider(),
                      const Text("💼 Experience", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...List.generate(data['workExperiences']?.length ?? 0, (index) {
                        final exp = data['workExperiences'][index];
                        if ((exp['title'] ?? '').isEmpty) return const SizedBox();
                        return Text("${exp['title']} at ${exp['company']} (${exp['duration']})");
                      }),
                      Text("Total Experience: ${data['experienceYears']} years"),

                      const Divider(),
                      const Text("🛠 Skills", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['skills'] ?? ''),
                      const Text("🌐 Languages", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['languages'] ?? ''),
                      const Text("📜 Certifications", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['certifications'] ?? 'N/A'),
                      const Text("🏆 Projects", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['projects'] ?? ''),
                      const Text("📞 Reference", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['reference'] ?? ''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
