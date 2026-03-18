import 'dart:js' as js;

// This function runs on Web
Future<void> generateAndPrintPDF(String htmlContent) async {
  // Fix the 'Undefined name context' error by using 'js.context' as imported
  js.context.callMethod("generatePDFfromHTML", [htmlContent]);
  js.context.callMethod("printPDF", [
    htmlContent,
  ]); // Assuming this was your original print call
}
