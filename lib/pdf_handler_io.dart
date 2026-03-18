import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

// This function runs on Android/iOS
Future<void> generateAndPrintPDF(String htmlContent) async {
  // 1. Convert HTML to PDF data
  final pdf = await Printing.convertHtml(
    format: PdfPageFormat.a4,
    html: htmlContent,
  );

  // 2. Use the correct method to show the system share dialogue
  // OLD: await Printing.share(bytes: pdf, filename: 'advisory.pdf');
  // NEW:
  await Printing.sharePdf(bytes: pdf, filename: 'advisory.pdf');
}
