import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

class ViewUploadedCVPage extends StatelessWidget {
  const ViewUploadedCVPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace this with your actual uploaded file path (from Firebase or local).
    final String? filePath = "/path/to/your/uploaded/cv.pdf"; // Replace with real path

    return Scaffold(
      appBar: AppBar(title: const Text("Your Uploaded CV")),
      body: filePath == null
          ? const Center(child: Text("No CV uploaded yet."))
          : PDFView(
        filePath: filePath,
        autoSpacing: true,
        enableSwipe: true,
        swipeHorizontal: false,
        pageSnap: true,
        pageFling: true,
        onError: (error) {
          debugPrint(error.toString());
        },
        onRender: (_pages) {},
        onViewCreated: (PDFViewController pdfViewController) {},
      ),
    );
  }
}
