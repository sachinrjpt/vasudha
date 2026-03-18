import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vasudha/widgets/auto_text.dart';
import 'package:file_saver/src/utils/mime_types.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:saf/saf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart'; // For file saving
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
// import 'dart:html' as html;
import '../services/api_service.dart'; // ✅ apne service file ka sahi path
import 'package:html/parser.dart' as htmlParser;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
// import 'dart:js' as js;
import 'package:vasudha/pdf_handler.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  String proxyUrl(String original) {
    return "https://vasudha.app/api/image-proxy?url=${Uri.encodeComponent(original)}";
  }

  int? selectedStateId;
  int? selectedZoneId;
  int? selectedCropId;

  Map<int, String> states = {};
  Map<int, String> zones = {};
  Map<int, String> crops = {};

  bool loading = true;
  List<dynamic> advisoryList = [];

  String extractImageUrl(String htmlString) {
    try {
      final doc = htmlParser.parse(htmlString);
      final img = doc.querySelector("img");

      if (img == null) return "";

      String? url = img.attributes['src'];
      if (url == null || url.trim().isEmpty) return "";

      url = url.trim();

      // CASE 1: //example.com/image.jpg
      if (url.startsWith("//")) return "https:$url";

      // CASE 2: /uploads/image.jpg
      if (url.startsWith("/")) return "https://vasudha.app$url";

      // CASE 3: Already full URL with http/https
      if (url.startsWith("http://") || url.startsWith("https://")) {
        return url; // 🔥 DO NOT encode!
      }

      // CASE 4: Unknown relative URL
      return "https://vasudha.app/$url";
    } catch (e) {
      return "";
    }
  }

  String cleanHTMLForPDF(String html) {
    final doc = htmlParser.parse(html);

    // Remove nested <html>, <head>, <body>
    for (var tag in ["html", "head", "body"]) {
      doc.getElementsByTagName(tag).forEach((e) {
        e.replaceWith(dom.Element.tag("div")..innerHtml = e.innerHtml);
      });
    }

    // Remove <figure> wrapper
    for (var figure in doc.getElementsByTagName("figure")) {
      if (figure.children.isNotEmpty) {
        figure.replaceWith(figure.children.first);
      } else {
        figure.remove();
      }
    }

    // Fix all <img> tags
    for (var img in doc.getElementsByTagName("img")) {
      String? src = img.attributes["src"];

      if (src == null) continue;

      // If URL incomplete
      if (src.startsWith("/")) {
        src = "https://vasudha.app$src";
      }

      final newImg = dom.Element.tag("img")
        ..attributes["src"] = src
        ..attributes["style"] =
            "max-width:500px;width:100%;height:auto;display:block;margin:14px 0;"
            "page-break-inside:avoid;page-break-before:auto;page-break-after:auto;";

      img.replaceWith(newImg);
    }

    return doc.body?.innerHtml ?? doc.outerHtml;
  }

  String? extractImage(String? htmlString) {
    if (htmlString == null) return null;

    final document = htmlParser.parse(htmlString);
    final img = document.querySelector("img"); // Extracts the first <img> tag

    return img != null
        ? img.attributes['src']
        : null; // Return the image source URL
  }

  Future<Uint8List> loadImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      print("Image Load Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Check the image size
        print("Image Size: ${response.bodyBytes.lengthInBytes}");
        return response.bodyBytes;
      } else {
        print("ERROR loading image: ${response.statusCode}");
        return Uint8List(0); // Return empty if not successful
      }
    } catch (e) {
      print("IMAGE LOAD ERROR: $e");
      return Uint8List(0); // Return empty bytes on error
    }
  }

  Future<bool> requestStoragePermissionAndroid11() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    var status = await Permission.manageExternalStorage.request();

    return status.isGranted;
  }

  Future<String> networkImageToBase64(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final base64Data = base64Encode(response.bodyBytes);
        return "data:image/jpeg;base64,$base64Data";
      }
    } catch (e) {
      print("Base64 ERROR: $e");
    }
    return "";
  }

  Future<String> convertHTMLImagesToBase64(String htmlContent) async {
    final document = htmlParser.parse(htmlContent);

    final imgs = document.getElementsByTagName("img");

    for (var img in imgs) {
      final src = img.attributes["src"];
      if (src == null || src.isEmpty) continue;

      final absoluteUrl = src.startsWith("http")
          ? src
          : "https://vasudha.app$src"; // अगर relative हो तो complete कर देंगे

      final base64Src = await networkImageToBase64(absoluteUrl);

      if (base64Src.isNotEmpty) {
        img.attributes["src"] = base64Src;
        img.attributes["style"] =
            "max-width:500px;width:100%;height:auto;display:block;margin:14px 0;"
            "page-break-inside:avoid;page-break-before:auto;page-break-after:auto;";
      }
    }

    return document.body?.innerHtml ?? htmlContent;
  }

  @override
  void initState() {
    super.initState();
    loadMasterData();
  }

  Future<void> loadMasterData() async {
    final res = await ApiService.getAdvisoryFilters();

    setState(() {
      states = {for (var s in res["states"]) s["id"]: s["name"]};
      zones = {for (var z in res["zones"]) z["id"]: z["name"]};
      crops = {for (var c in res["crops"]) c["id"]: c["crops"]};
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: AutoText("Advisory"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoText(
              "Search Advisory",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // STATE
                  _dropdownMap(
                    label: "State",
                    value: selectedStateId,
                    data: states,
                    isMobile: isMobile,
                    onChanged: (v) {
                      setState(() {
                        selectedStateId = v;
                      });
                    },
                  ),

                  // ZONE (Flat list)
                  _dropdownMap(
                    label: "Zone",
                    value: selectedZoneId,
                    data: zones,
                    isMobile: isMobile,
                    onChanged: (v) {
                      setState(() {
                        selectedZoneId = v;
                      });
                    },
                  ),

                  // CROP
                  _dropdownMap(
                    label: "Crop",
                    value: selectedCropId,
                    data: crops,
                    isMobile: isMobile,
                    onChanged: (v) {
                      setState(() {
                        selectedCropId = v;
                      });
                    },
                  ),
                ],
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedStateId == null ||
                        selectedZoneId == null ||
                        selectedCropId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: AutoText("Please select State, Zone & Crop"),
                        ),
                      );
                      return;
                    }

                    setState(() => loading = true);

                    final res = await ApiService.filterAdvisories(
                      stateId: selectedStateId!,
                      zoneId: selectedZoneId!,
                      cropId: selectedCropId!,
                    );

                    setState(() {
                      advisoryList = res["advisories"] ?? [];
                      loading = false;
                    });
                  },
                  child: AutoText(
                    "Show Advisory",
                    style: TextStyle(
                      color: Colors.white, // 👈 extra safety
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedStateId = null;
                      selectedZoneId = null;
                      selectedCropId = null;
                    });
                  },
                  child: AutoText("Reset"),
                ),
              ],
            ),

            const SizedBox(height: 25),
            AutoText(
              "Advisory Results",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // EXPORT BUTTONS UPDATED
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _exportBtn("Copy", Colors.green, onTap: _copyData),
                  _exportBtn("CSV", Colors.blueGrey, onTap: _exportCSV),
                  _exportBtn("Excel", Colors.blue, onTap: _exportExcel),
                  // _exportBtn(
                  //   "PDF (Text + Images)",
                  //   Colors.red,
                  //   onTap: _exportPDF,
                  // ),
                  _exportBtn("Pdf+Print", Colors.red, onTap: _printData),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (advisoryList.isEmpty)
              AutoText("No Advisory Found")
            else
              advisoryTable(),
          ],
        ),
      ),
    );
  }

  // ------------------ WIDGETS ------------------

  Widget _dropdownMap({
    required String label,
    required int? value,
    required Map<int, String> data,
    required bool isMobile,
    required Function(int?) onChanged,
  }) {
    return SizedBox(
      width: isMobile ? double.infinity : 250,
      child: DropdownButtonFormField<int>(
        value: value,
        items: data.entries
            .map(
              (e) => DropdownMenuItem(value: e.key, child: AutoText(e.value)),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          label: AutoText(label),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // UPDATED EXPORT BUTTON (Clickable)
  Widget _exportBtn(String text, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: AutoText(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget advisoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
        border: TableBorder.all(color: Colors.grey.shade400),
        columns: const [
          DataColumn(label: AutoText("S.No.")),
          DataColumn(label: AutoText("Title")),
          DataColumn(label: AutoText("Status")),
          DataColumn(label: AutoText("Descriptions")),
        ],
        rows: List<DataRow>.generate(advisoryList.length, (index) {
          final a = advisoryList[index];
          final descList = [
            a["description1"] ?? "",
            a["description2"] ?? "",
            a["description3"] ?? "",
            a["description4"] ?? "",
            a["description5"] ?? "",
          ].where((e) => e.isNotEmpty).toList();

          return DataRow(
            cells: [
              DataCell(AutoText("${index + 1}")),
              DataCell(AutoText(a["title"] ?? "")),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AutoText(
                    a["status"] ?? "Active",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 350, // Mobile + Web दोनों में responsive
                    minWidth: 200,
                    maxHeight: 250, // Height fixed so list won't overflow
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var d in descList)
                          Html(
                            data: d,
                            style: {
                              "p": Style(
                                fontSize: FontSize(14),
                                margin: Margins.only(bottom: 6),
                              ),
                              "img": Style(
                                width: Width.auto(),
                                height: Height.auto(),
                              ),
                              "figure": Style(
                                padding: HtmlPaddings.zero,
                                margin: Margins.zero,
                              ),
                            },

                            extensions: [
                              TagExtension(
                                tagsToExtend: {"img"},
                                builder: (extensionContext) {
                                  final element = extensionContext.element;
                                  if (element == null)
                                    return const SizedBox.shrink();

                                  final src = element.attributes["src"] ?? "";
                                  if (src.isEmpty)
                                    return const SizedBox.shrink();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        src,
                                        width: 300,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            AutoText("Image not loaded"),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ------------------ EXPORT METHODS ------------------

  void _copyData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AutoText("Copied")));
  }

  void _exportCSV() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AutoText("CSV Exported")));
  }

  void _exportExcel() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AutoText("Excel Exported")));
  }

  // ------------------ REAL PDF EXPORT ------------------

  void _exportPDF() async {
    if (advisoryList.isEmpty) return;

    String htmlContent = "";

    for (var a in advisoryList) {
      String combinedDesc =
          """
      ${a["description1"] ?? ""}
      ${a["description2"] ?? ""}
      ${a["description3"] ?? ""}
      ${a["description4"] ?? ""}
      ${a["description5"] ?? ""}
    """;

      combinedDesc = cleanHTMLForPDF(combinedDesc);
      combinedDesc = await convertHTMLImagesToBase64(combinedDesc);

      String onlyDate = a["created_at"].toString().split("T")[0];

      htmlContent +=
          """
      <div style="padding:18px; border:1px solid #ccc; margin-bottom:20px;">
        <h1>${a["title"]}</h1>
        <p><b>Status:</b> ${a["status"]}</p>
        <p><b>Date:</b> $onlyDate</p>
        $combinedDesc
      </div>
    """;
    }

    if (kIsWeb) {
      await generateAndPrintPDF(htmlContent);
      return;
    }

    // For mobile: Convert HTML to PDF
    final pdfBytes = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: htmlContent,
    );

    try {
      // Saving to device (platform-specific code)
      if (Platform.isAndroid || Platform.isIOS) {
        // Android/iOS saving, let's check for permission first
        bool isPermissionGranted = await requestStoragePermissionAndroid11();
        if (isPermissionGranted) {
          // Get directory path (on Android/iOS) to save PDF file
          final directory = await getExternalStorageDirectory();
          String filePath = "${directory?.path}/Advisory_Report.pdf";

          final file = File(filePath);
          await file.writeAsBytes(pdfBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AutoText("PDF Saved Successfully at $filePath")),
          );

          // Optionally, open the file after saving
          OpenFilex.open(filePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AutoText("Permission Denied! Unable to save PDF"),
            ),
          );
        }
      } else {
        // Web Save using FileSaver
        await FileSaver.instance.saveFile(
          name: "Advisory_Report.pdf",
          bytes: pdfBytes,
          mimeType: MimeType.pdf,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AutoText("PDF Saved Successfully in Downloads")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AutoText("Failed to save PDF: $e")));
    }
  }

  void _printData() async {
    if (advisoryList.isEmpty) return;

    String htmlContent = "";

    for (var a in advisoryList) {
      String combinedDesc =
          """
      ${a["description1"] ?? ""}
      ${a["description2"] ?? ""}
      ${a["description3"] ?? ""}
      ${a["description4"] ?? ""}
      ${a["description5"] ?? ""}
    """;

      // clean + base64 image
      combinedDesc = cleanHTMLForPDF(combinedDesc);
      combinedDesc = await convertHTMLImagesToBase64(combinedDesc);

      String onlyDate = a["created_at"].toString().split("T")[0];

      htmlContent +=
          """
      <div style="padding:18px; border:1px solid #ccc; margin-bottom:20px;">
        <h1>${a["title"]}</h1>
        <p><b>Status:</b> ${a["status"]}</p>
        <p><b>Date:</b> $onlyDate</p>
        $combinedDesc
      </div>
    """;
    }

    // Web Print
    if (kIsWeb) {
      await generateAndPrintPDF(htmlContent);
      return;
    }

    // Mobile/Windows/Mac Print Dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await Printing.convertHtml(format: format, html: htmlContent);
      },
    );
  }
}
