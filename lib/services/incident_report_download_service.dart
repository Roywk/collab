import 'package:file_saver/file_saver.dart';

import '../models/incident_report_models.dart';

class IncidentReportDownloadService {
  Future<String> download(GeneratedIncidentPdf pdf) {
    return FileSaver.instance.saveFile(
      name: pdf.fileName,
      bytes: pdf.bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
