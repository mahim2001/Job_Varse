import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CVTemplate5 extends StatefulWidget {
  final Map<String, dynamic> data;

  const CVTemplate5({Key? key, required this.data}) : super(key: key);

  @override
  State<CVTemplate5> createState() => _CVTemplate5State();
}

class _CVTemplate5State extends State<CVTemplate5> {
  final GlobalKey _previewContainer = GlobalKey();

  Future<void> _captureAndPrintWidget() async {
    try {
      RenderRepaintBoundary boundary =
      _previewContainer.currentContext!.findRenderObject()
      as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Center(child: pw.Image(imageProvider)),
        ),
      );

      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'cv_template5.pdf');
    } catch (e) {
      print("Error while printing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CV Template 5 - Professional"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _captureAndPrintWidget,
          )
        ],
      ),
      body: RepaintBoundary(
        key: _previewContainer,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar
              Container(
                width: 150,
                color: Colors.blueGrey.shade50,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (data['profileImage'] != null &&
                        data['profileImage'].toString().isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(data['profileImage']),
                        radius: 40,
                      )
                    else
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      data['name'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text("📧 ${data['email']}"),
                    Text("📞 ${data['phone']}"),
                    const SizedBox(height: 10),
                    Text("🎂 DOB: ${data['dob']}"),
                    Text("🏠 ${data['address']}"),
                    const SizedBox(height: 10),
                    const Text("Skills",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['skills'] ?? ''),
                    const SizedBox(height: 8),
                    const Text("Languages",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['languages'] ?? ''),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🎓 Education",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          "SSC: ${data['ssc_school']}, ${data['ssc_board']} (${data['ssc_year']}) - ${data['ssc_result']}"),
                      Text(
                          "HSC: ${data['hsc_college']}, ${data['hsc_board']} (${data['hsc_year']}) - ${data['hsc_result']}"),
                      Text(
                          "Bachelor: ${data['bachelor_subject']}, ${data['bachelor_university']} (${data['bachelor_year']}) - ${data['bachelor_result']}"),
                      if (data['masters_subject'] != null &&
                          data['masters_subject'].toString().isNotEmpty)
                        Text(
                            "Masters: ${data['masters_subject']}, ${data['masters_university']} (${data['masters_year']}) - ${data['masters_result']}"),
                      const SizedBox(height: 10),
                      const Text("💼 Experience",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (data['workExperiences'] != null)
                        ...List.generate(data['workExperiences'].length,
                                (index) {
                              final exp = data['workExperiences'][index];
                              if ((exp['title'] ?? '').isEmpty) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                    "${exp['title']} at ${exp['company']} (${exp['duration']})"),
                              );
                            }),
                      Text("Total Experience: ${data['experienceYears']} years"),
                      const SizedBox(height: 10),
                      const Text("📜 Certifications",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['certifications'] ?? 'N/A'),
                      const SizedBox(height: 6),
                      const Text("🏆 Projects / Achievements",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['projects'] ?? ''),
                      const SizedBox(height: 6),
                      const Text("📞 Reference",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
