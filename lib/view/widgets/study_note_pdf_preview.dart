import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../../data/network/network_api_services.dart';
import '../../utils/app_url.dart';

Future<Uint8List> loadStudyNotePdf(Uri uri) async {
  final Uint8List bytes;
  if (uri.origin == Uri.parse(AppUrl.baseUrl).origin) {
    bytes = await NetworkApiService().getPdfBytes(uri.toString());
  } else {
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw StateError('PDF unavailable');
    bytes = response.bodyBytes;
  }
  if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
    throw const FormatException('Attachment is not a PDF');
  }
  return bytes;
}

class StudyNotePdfPreview extends StatefulWidget {
  final Uri uri;
  final String fileName;
  final bool allowDownload;
  final Future<Uint8List> Function(Uri)? loader;
  const StudyNotePdfPreview({
    super.key,
    required this.uri,
    required this.fileName,
    this.allowDownload = true,
    this.loader,
  });

  @override
  State<StudyNotePdfPreview> createState() => _StudyNotePdfPreviewState();
}

class _StudyNotePdfPreviewState extends State<StudyNotePdfPreview> {
  late Future<Uint8List> _pdf;
  @override
  void initState() {
    super.initState();
    _pdf = (widget.loader ?? loadStudyNotePdf)(widget.uri);
  }

  void _retry() => setState(() {
    _pdf = (widget.loader ?? loadStudyNotePdf)(widget.uri);
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .7,
    child: FutureBuilder<Uint8List>(
      future: _pdf,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load PDF. Please try again.'),
                TextButton(onPressed: _retry, child: const Text('Retry PDF')),
              ],
            ),
          );
        }
        return PdfPreview(
          build: (_) async => snapshot.data!,
          pdfFileName: widget.fileName,
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowPrinting: false,
          allowSharing: widget.allowDownload,
        );
      },
    ),
  );
}
