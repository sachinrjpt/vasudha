import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert'; // ✅ Added
import 'package:http/http.dart' as http;
import '../services/api_service.dart'; // <- adjust path to your ApiService
import '../services/storage_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:collection/collection.dart';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart'; // ✅ Add this line
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'package:vasudha/widgets/auto_text.dart';

class FarmerDashboardScreen extends StatefulWidget {
  final int auditId;
  const FarmerDashboardScreen({Key? key, required this.auditId})
    : super(key: key);

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  bool _loading = true;
  bool _saving = false;
  String? profileImageUrl; // 👈 Add this line

  Map<String, dynamic>? farmer;
  Map<String, dynamic>? metrics;
  Map<String, dynamic>? environmental;
  Map<String, dynamic>? soilHealth;
  Map<String, dynamic>? climateChange;

  final GlobalKey _dashboardKey = GlobalKey();

  // Editable fields we allow to push to server
  late TextEditingController _totalYieldController;
  late TextEditingController _salePriceController;
  late TextEditingController _farmGatePriceController;
  late TextEditingController _irrigationEffController;
  late TextEditingController _waterUsageMmController;

  // New controllers for web fields
  late TextEditingController _intercroppingIncomeController;
  late TextEditingController _inputCostReductionController;
  late TextEditingController _netIncomeChangeController;

  @override
  void initState() {
    super.initState();
    _totalYieldController = TextEditingController();
    _salePriceController = TextEditingController();
    _farmGatePriceController = TextEditingController();
    _irrigationEffController = TextEditingController();
    _waterUsageMmController = TextEditingController();
    _intercroppingIncomeController = TextEditingController();
    _inputCostReductionController = TextEditingController();
    _netIncomeChangeController = TextEditingController();
    _fetch();
  }

  @override
  void dispose() {
    _totalYieldController.dispose();
    _salePriceController.dispose();
    _farmGatePriceController.dispose();
    _irrigationEffController.dispose();
    _waterUsageMmController.dispose();
    _intercroppingIncomeController.dispose();
    _inputCostReductionController.dispose();
    _netIncomeChangeController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final token = await StorageService.getToken();

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AutoText('No token found. Please log in again.')),
        );
        setState(() => _loading = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://vasudha.app/api/farmer-audit/${widget.auditId}/dashboard',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          Map<String, dynamic> parseMetricSection(dynamic section) {
            if (section is! Map) return {};

            final Map<String, dynamic> out = {};

            section.forEach((metricName, metricVal) {
              if (metricVal is List) {
                out[metricName.toString()] = List.from(metricVal);
              } else {
                out[metricName.toString()] = [metricVal, '-', '-', '-'];
              }
            });

            return out;
          }

          setState(() {
            farmer = Map<String, dynamic>.from(jsonData['farmer'] ?? {});
            metrics = parseMetricSection(jsonData['metrics']);

            environmental = parseMetricSection(
              jsonData['environmentalMetrics'],
            );

            soilHealth = parseMetricSection(jsonData['soilHealthMetrics']);

            climateChange = parseMetricSection(
              jsonData['climateChangeMetrics'],
            );
            profileImageUrl = farmer?['profile_image']?.toString();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AutoText('Failed to load dashboard data')),
          );
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AutoText('Unauthorized. Please log in again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AutoText(
              'Failed to fetch dashboard: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText('Error fetching dashboard: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();

      // ✅ Load Unicode fonts (Noto Sans)
      final regularFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
      );

      // ✅ Load emoji-supporting font (to render 📞 🌍 📈 etc.)
      final emojiFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoColorEmoji.ttf"),
      );

      // ✅ Combine fonts with emoji fallback
      final theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [emojiFont],
      );

      // ✅ Load farmer image (if available)
      pw.ImageProvider? farmerImage;
      final imageUrl =
          farmer?['profile_image'] != null &&
              farmer!['profile_image'].toString().isNotEmpty
          ? farmer!['profile_image']
                .toString() // <- ✅ remove 'https://vasudha.app/' prefix
          : null;

      if (imageUrl != null) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            farmerImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }

      // ✅ Capture chart widgets as images
      final charts = await _captureChartsAsImages();

      // ✅ Build multi-page PDF (unchanged layout, but emoji-capable now)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: theme, // 👈 apply emoji fallback theme here
          build: (context) => [
            _buildPdfHeader(farmerImage, boldFont),
            _buildPdfGreeting(boldFont),
            _buildPdfReward(boldFont),
            _buildPdfEnvironment(boldFont),
            pw.SizedBox(height: 20),

            // pw.Column(
            //   crossAxisAlignment: pw.CrossAxisAlignment.start,
            //   children: [
            pw.NewPage(),
            pw.Text(
              "📈 Dashboard Charts",
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 10),

            for (var img in charts)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                height: 200,
                child: pw.Image(
                  pw.MemoryImage(img),
                  fit: pw.BoxFit.contain,
                  alignment: pw.Alignment.center,
                ),
              ),

            // ],
            // ),
            pw.Divider(),

            // ✅ Tables (same as before)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                pw.NewPage(),
                _buildPdfTable('Farmer Metrics', metrics, boldFont),
              ],
            ),
            pw.SizedBox(height: 15),
            _buildPdfTable('Environmental Metrics', environmental, boldFont),
            pw.SizedBox(height: 15),
            _buildPdfTable('Soil Health', soilHealth, boldFont),
            pw.SizedBox(height: 15),
            _buildPdfTable(
              'Climate Change Mitigation',
              climateChange,
              boldFont,
            ),
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: regularFont, fontSize: 9),
            ),
          ),
        ),
      );

      // ✅ Save PDF bytes
      final pdfBytes = await pdf.save();

      // ✅ Save locally & trigger download/share
      final fileName = "Farmer_Report_${farmer?['name'] ?? 'Unknown'}.pdf";

      // For Mobile/Desktop
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: AutoText('❌ PDF export failed: $e')));
      }
    }
  }

  Future<List<Uint8List>> _captureChartsAsImages() async {
    final List<Uint8List> chartImages = [];

    try {
      // ✅ Get your real chart data (same logic as in _chartsSection)
      final yieldArr = _toList(
        metrics?['Yield (kg/acre)'] ?? metrics?['Yield'] ?? 0,
      );
      final priceArr = _toList(
        metrics?['Price per KG (₹)'] ?? metrics?['Price per KG'] ?? 0,
      );
      final netIncomeArr = _toList(
        metrics?['Net Income (₹/acre)'] ??
            metrics?['Net Income'] ??
            [0, 0, 0, 0],
      );

      final waterSavedRaw =
          environmental?['Water Saved per acre'] ??
          environmental?['Water Saved (liters/acre)'] ??
          environmental?['Water Saved (liters)'] ??
          environmental?['Water Saved'];

      List<double> waterSavedArr = [];
      if (waterSavedRaw is num) {
        waterSavedArr = [
          0,
          waterSavedRaw.toDouble(),
          waterSavedRaw.toDouble(),
          waterSavedRaw.toDouble(),
        ];
      } else {
        waterSavedArr = _toList(waterSavedRaw);
      }

      final socArr = _toList(
        soilHealth?['Soil Organic Carbon (SOC) Gain (kg/acre)'],
      );
      final co2Arr = _toList(climateChange?['CO₂e Sequestered (kg/acre)']);

      // ✅ Create same chart widgets used in the dashboard
      final chartWidgets = <Widget>[
        _lineChartCard('Yield (kg/acre)', yieldArr, Colors.orange),
        _lineChartCard('Price per KG (₹)', priceArr, Colors.pink),
        _lineChartCard('Net Income (₹/acre)', netIncomeArr, Colors.teal),
        _barChartCard(
          'Water Saved (liters/acre)',
          waterSavedArr,
          Colors.lightBlue,
        ),
        _barChartCard(
          'Soil Organic Carbon (SOC) Gain (kg/acre)',
          socArr,
          Colors.purple,
        ),
        _barChartCard('CO₂e Sequestered (kg/acre)', co2Arr, Colors.redAccent),
      ];

      // ✅ Capture each chart as an image
      for (var chart in chartWidgets) {
        final bytes = await _captureWidgetAsImage(chart);
        if (bytes != null) chartImages.add(bytes);
      }
    } catch (e) {}

    return chartImages;
  }

  Future<Uint8List?> _captureWidgetAsImage(Widget widget) async {
    try {
      final controller = ScreenshotController();

      final bytes = await controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(), // 👈 required for fl_chart
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min, // 👈 no extra height
                children: [widget],
              ),
            ),
          ),
        ),
        pixelRatio: 2.0,
      );

      return bytes;
    } catch (e) {
      return null;
    }
  }

  pw.Widget _buildPdfHeader(pw.ImageProvider? image, pw.Font boldFont) {
    final titleStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.green800,
    );
    final normalStyle = const pw.TextStyle(fontSize: 10);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (image != null)
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover),
            ),
          ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(farmer?['name'] ?? 'N/A', style: titleStyle),
              pw.Text('📞 ${farmer?['phone'] ?? '-'}', style: normalStyle),
              pw.Text(
                '🌍 ${farmer?['state'] ?? '-'}, ${farmer?['district'] ?? '-'}',
                style: normalStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfGreeting(pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Namaste ${farmer?['name'] ?? 'Farmer'},",
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          "Thank you for your hard work for your land and family. "
          "Our Vasudha tool shows you the rewards your dedication will bring "
          "when you choose sustainable farming.",
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          "This is a picture of the journey ahead for your farm in the "
          "${metrics?['Season']?[0] ?? ''} season.",
        ),
      ],
    );
  }

  pw.Widget _buildPdfReward(pw.Font boldFont) {
    final netIncomeArr = _toList(metrics?['Net Income (₹/acre)'] ?? []);
    final yieldArr = _toList(metrics?['Yield (kg/acre)'] ?? []);
    final percArr = _toList(metrics?['Net Income Change (%)'] ?? []);

    if (netIncomeArr.length < 4) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text(
          "The Rewards for Your Family",
          style: pw.TextStyle(font: boldFont, fontSize: 13),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          "Your dedication to sustainable farming will make your land stronger "
          "and increase your income. This will bring more security and a better future for your family.",
        ),
        pw.SizedBox(height: 12),

        pw.Text(
          "In the first season of change, your Net Income is set to be "
          "₹${netIncomeArr[1].toStringAsFixed(2)} per acre. "
          "This is a big step forward, with a ${percArr[1].toStringAsFixed(2)}% increase from your current earnings. "
          "We'll see a small dip in your yield to ${yieldArr[1]} kg/acre.",
        ),
        pw.SizedBox(height: 8),

        pw.Text(
          "By the second season, your net income will grow to "
          "₹${netIncomeArr[2].toStringAsFixed(2)} per acre, "
          "a wonderful ${percArr[2].toStringAsFixed(2)}% increase from today. "
          "Your yield will be ${yieldArr[2]} kg/acre.",
        ),
        pw.SizedBox(height: 8),

        pw.Text(
          "By the third season, your farm will be thriving! "
          "Net income will reach ₹${netIncomeArr[3].toStringAsFixed(2)} per acre, "
          "a stunning ${percArr[3].toStringAsFixed(2)}% jump. "
          "Yield will be ${yieldArr[3]} kg/acre.",
        ),
      ],
    );
  }

  pw.Widget _buildPdfEnvironment(pw.Font boldFont) {
    final waterSavedArr = environmental?['Water Saved per acre'] ?? [];
    final waterRequirementArr =
        environmental?['Water Requirement (liters) per acre'] ?? [];
    final socArr =
        soilHealth?['Soil Organic Carbon (SOC) Gain (kg/acre)'] ?? [];
    final co2Arr = _toList(climateChange?['CO₂e Sequestered (kg/acre)'] ?? []);

    double waterSaved = _extractNumber(waterSavedArr[1]);
    double waterRequired = _extractNumber(waterRequirementArr[1]);
    double soc = double.tryParse(socArr[3].toString()) ?? 0;
    double co2 = co2Arr.length > 3 ? co2Arr[3] : 0;

    int familyYears = (waterSaved / 5840).floor();
    int carDistance = (co2 / 0.12).floor();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text(
          "The Health of Your Land and Our Earth",
          style: pw.TextStyle(font: boldFont, fontSize: 13),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          "Your hard work helps your family and also makes your land stronger. "
          "It makes our planet healthier.",
        ),
        pw.SizedBox(height: 12),

        if (waterSaved > 0 && waterRequired > 0)
          pw.Text(
            "Water: Your farm will save ${waterSaved.toStringAsFixed(0)} liters. "
            "Enough drinking water for a family of four for over $familyYears years. "
            "Total requirement: ${waterRequired.toStringAsFixed(0)} liters per acre.",
          ),

        if (soc > 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              "Soil Health: Your soil will gain ${soc.toStringAsFixed(0)} kg/acre of organic carbon.",
            ),
          ),

        if (co2 > 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              "Climate Change Mitigation: Your farm will capture "
              "${co2.toStringAsFixed(0)} kg of CO₂. "
              "Equivalent to a car driving $carDistance kilometers.",
            ),
          ),
      ],
    );
  }

  pw.Widget _buildPdfTable(
    String title,
    Map<String, dynamic>? data,
    pw.Font boldFont,
  ) {
    if (data == null || data.isEmpty) {
      return pw.Container();
    }

    final headers = ['Metric', 'Current', 'Year 1', 'Year 2', 'Year 3'];
    final rows = data.entries.map((entry) {
      final values = entry.value is List
          ? (entry.value as List)
          : [entry.value?.toString() ?? '-', '-', '-', '-'];
      return [entry.key, ...values.map((v) => v?.toString() ?? '-')];
    }).toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
            headerStyle: pw.TextStyle(
              font: boldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            border: null,
          ),
        ],
      ),
    );
  }

  Future<void> _shareOnWhatsApp() async {
    try {
      final name = farmer?['name'] ?? 'Farmer';
      final phone = farmer?['phone'] ?? '-';

      // 🧱 Step 1: Generate PDF
      final pdf = pw.Document();

      final regularFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
      );
      final emojiFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoColorEmoji.ttf"),
      );

      final theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [emojiFont],
      );

      pw.ImageProvider? farmerImage;

      final imageUrl =
          farmer?['profile_image'] != null &&
              farmer!['profile_image'].toString().isNotEmpty
          ? farmer!['profile_image'].toString()
          : null;

      if (imageUrl != null) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            farmerImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }

      final charts = await _captureChartsAsImages();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: theme,
          build: (context) => [
            _buildPdfHeader(farmerImage, boldFont),
            _buildPdfGreeting(boldFont),
            _buildPdfReward(boldFont),
            _buildPdfEnvironment(boldFont),
            pw.SizedBox(height: 20),
            pw.NewPage(),
            pw.Text(
              "📈 Dashboard Charts",
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 10),
            for (var img in charts)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                height: 200,
                child: pw.Image(pw.MemoryImage(img), fit: pw.BoxFit.contain),
              ),
            pw.NewPage(),
            _buildPdfTable('Farmer Metrics', metrics, boldFont),
            pw.SizedBox(height: 15),
            _buildPdfTable('Environmental Metrics', environmental, boldFont),
            pw.SizedBox(height: 15),
            _buildPdfTable('Soil Health', soilHealth, boldFont),
            pw.SizedBox(height: 15),
            _buildPdfTable(
              'Climate Change Mitigation',
              climateChange,
              boldFont,
            ),
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: regularFont, fontSize: 9),
            ),
          ),
        ),
      );

      // 💾 Save PDF
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/Farmer_Report_$name.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final msg =
          '''
👨‍🌾 Farmer Dashboard - $name
📞 Mobile: $phone
📄 Please find attached your latest report.
''';

      // ✅ Share using share_plus
      await Share.shareXFiles([XFile(file.path)], text: msg);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Share failed: $e')));
      }
    }
  }

  // Build line chart (fl_chart)
  Widget _lineChartCard(String title, List<double> vals, Color color) {
    final spots = vals
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    double minVal = vals.reduce((a, b) => a < b ? a : b);
    double maxVal = vals.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;

    // prevent zero range issue
    if (range == 0) {
      range = maxVal == 0 ? 10 : maxVal.abs() * 0.2;
    }

    double interval = range / 4;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            AutoText(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minVal - interval,
                  maxY: maxVal + interval,

                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                    drawVerticalLine: false,
                  ),

                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(), // full number
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final labels = [
                            'Current',
                            'Year 1',
                            'Year 2',
                            'Year 3',
                          ];

                          if (v.toInt() >= 0 && v.toInt() < labels.length) {
                            return SideTitleWidget(
                              meta: meta,
                              child: AutoText(
                                labels[v.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),

                  borderData: FlBorderData(show: true),

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _greetingSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoText(
              "Namaste ${farmer?['name'] ?? 'Farmer'},",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const AutoText(
              "Thank you for your hard work for your land and family. "
              "Our Vasudha tool shows you the rewards your dedication will bring "
              "when you choose sustainable farming.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            AutoText(
              "This is a picture of the journey ahead for your farm in the "
              "${metrics?['Season']?[0] ?? ''} season.",
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardSection() {
    final netIncomeArr = _toList(metrics?['Net Income (₹/acre)'] ?? []);
    final yieldArr = _toList(metrics?['Yield (kg/acre)'] ?? []);
    final percArr = _toList(metrics?['Net Income Change (%)'] ?? []);

    if (netIncomeArr.length < 4) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AutoText(
              "The Rewards for Your Family",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const AutoText(
              "Your dedication to sustainable farming will make your land stronger and increase your income. "
              "This will bring more security and a better future for your family.",
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 16),
            AutoText(
              "In the first season of change, your Net Income is set to be "
              "₹${netIncomeArr[1].toStringAsFixed(2)} per acre. "
              "This is a big step forward, with a ${percArr[1].toStringAsFixed(2)}% increase from your current earnings. "
              "We'll see a small dip in your yield to ${yieldArr[1]} kg/acre, but your costs for expensive chemicals drop, "
              "and you will get a better price for your good quality crop.",
            ),
            const SizedBox(height: 12),
            AutoText(
              "By the second season, your efforts will truly show. Your net income will grow to "
              "₹${netIncomeArr[2].toStringAsFixed(2)} per acre, a wonderful ${percArr[2].toStringAsFixed(2)}% increase from today. "
              "Your land will have healed, bringing your yield back up to a strong ${yieldArr[2]} kg/acre.",
            ),
            const SizedBox(height: 12),
            AutoText(
              "By the third season, your farm will be thriving! We expect your net income to reach "
              "₹${netIncomeArr[3].toStringAsFixed(2)} per acre, a stunning ${percArr[3].toStringAsFixed(2)}% jump. "
              "Your land will be giving you its best, with a yield of ${yieldArr[3]} kg/acre "
              "and the highest price for your trusted produce.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _environmentSection() {
    final waterSavedArr = environmental?['Water Saved per acre'] ?? [];
    final waterRequirementArr =
        environmental?['Water Requirement (liters) per acre'] ?? [];
    final socArr =
        soilHealth?['Soil Organic Carbon (SOC) Gain (kg/acre)'] ?? [];
    final co2Arr = _toList(climateChange?['CO₂e Sequestered (kg/acre)'] ?? []);

    double waterSaved = _extractNumber(waterSavedArr[1]);
    double waterRequired = _extractNumber(waterRequirementArr[1]);
    double soc = double.tryParse(socArr[3].toString()) ?? 0;
    double co2 = co2Arr[3];

    int familyYears = (waterSaved / 5840).floor();
    int carDistance = (co2 / 0.12).floor();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AutoText(
              "The Health of Your Land and Our Earth",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const AutoText(
              "Your hard work helps your family and also makes your land stronger. "
              "It makes our planet healthier.",
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 16),

            if (waterSaved > 0 && waterRequired > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AutoText(
                    "Water: ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Expanded(
                    child: AutoText(
                      "Your farm will save ${waterSaved.toStringAsFixed(0)} liters of water each season. "
                      "This is enough drinking water for a family of four for over $familyYears years. "
                      "Your total water requirement will be ${waterRequired.toStringAsFixed(0)} liters per acre.",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            if (soc > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AutoText(
                    "Soil Health: ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Expanded(
                    child: AutoText(
                      "You are giving life back to your soil. By the end of the transition, "
                      "your soil will have gained a total of ${soc.toStringAsFixed(0)} kg/acre of rich soil organic carbon, "
                      "making it fertile for generations to come.",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            if (co2 > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AutoText(
                    "Climate Change Mitigation: ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Expanded(
                    child: AutoText(
                      "Your farm will become a friend to the earth. "
                      "By the third season, your farm will capture a total of ${co2.toStringAsFixed(0)} kg of CO₂ from the air. "
                      "This is like removing the pollution from a car driving for approximately $carDistance kilometers.",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildMetricSection(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoText(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),

            /// MOBILE SCROLL
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 14,
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade300,
                ),
                columns: const [
                  DataColumn(label: AutoText("Metric")),
                  DataColumn(label: AutoText("Current")),
                  DataColumn(label: AutoText("Year 1")),
                  DataColumn(label: AutoText("Year 2")),
                  DataColumn(label: AutoText("Year 3")),
                ],

                rows: data.entries.map((entry) {
                  List vals = entry.value is List ? entry.value : [entry.value];

                  String format(val) {
                    final rupeeFields = [
                      "Intercropping Income",
                      "Agricultural Input cost",
                      "Total Input Cost",
                      "Gross Income",
                      "Net Income",
                      "Labour and machinery cost",
                      "Price per KG",
                    ];

                    final percentFields = ["Change", "Reduction"];

                    if (percentFields.any((f) => entry.key.contains(f))) {
                      return "${val ?? 0}%";
                    }

                    if (rupeeFields.any((f) => entry.key.contains(f))) {
                      return "₹${val ?? 0}";
                    }

                    return val.toString();
                  }

                  Color getColor(val) {
                    double numVal = double.tryParse(val.toString()) ?? 0;
                    if (entry.key.contains("Net Income")) {
                      return numVal < 0 ? Colors.red : Colors.green;
                    }
                    if (entry.key.contains("Change")) {
                      return numVal < 0 ? Colors.red : Colors.green;
                    }
                    return Colors.black87;
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 200,
                            maxWidth: 260,
                          ),
                          child: AutoText(entry.key, softWrap: true),
                        ),
                      ),

                      for (int i = 0; i < 4; i++)
                        DataCell(
                          AutoText(
                            format(i < vals.length ? vals[i] : 0),
                            style: TextStyle(
                              color: getColor(i < vals.length ? vals[i] : 0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmerHeaderSection() {
    final name = farmer?['name'] ?? 'N/A';
    final phone = farmer?['phone'] ?? '-';
    final state = farmer?['state'] ?? '-';
    final district = farmer?['district'] ?? '-';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👤 Farmer Image
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/logo.png') as ImageProvider,
            ),

            const SizedBox(width: 12),

            /// 📄 Farmer Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoText(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),

                  AutoText('📞 $phone'),

                  /// 🌍 Location (State + District safely)
                  AutoText(
                    '🌍 ${state != '-' ? state : ''}'
                    '${(state != '-' && district != '-') ? ', ' : ''}'
                    '${district != '-' ? district : ''}'
                    '${(state == '-' && district == '-') ? '-' : ''}',
                  ),
                ],
              ),
            ),

            /// 📤 Buttons
            SizedBox(
              width: 130,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _shareOnWhatsApp,
                    icon: const Icon(Icons.share),
                    label: const AutoText('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _exportToPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const AutoText('Export'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartsSection() {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    final yieldArr = _toList(
      metrics?['Yield (kg/acre)'] ?? metrics?['Yield'] ?? 0,
    );
    final priceArr = _toList(
      metrics?['Price per KG (₹)'] ?? metrics?['Price per KG'] ?? 0,
    );
    final netIncomeArr = _toList(
      metrics?['Net Income (₹/acre)'] ?? metrics?['Net Income'] ?? [0, 0, 0, 0],
    );
    final waterSavedArr = _toList(
      environmental?['Water Saved (liters/acre)'] ??
          environmental?['Water Saved'] ??
          0,
    );
    final socArr = _toList(
      soilHealth?['Soil Organic Carbon (SOC) Gain (kg/acre)'],
    );
    final co2Arr = _toList(climateChange?['CO₂e Sequestered (kg/acre)']);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: isWide ? (width - 64) / 3 : double.infinity,
          child: _lineChartCard('Yield (kg/acre)', yieldArr, Colors.orange),
        ),
        SizedBox(
          width: isWide ? (width - 64) / 3 : double.infinity,
          child: _lineChartCard('Price per KG (₹)', priceArr, Colors.pink),
        ),
        SizedBox(
          width: isWide ? (width - 64) / 3 : double.infinity,
          child: _lineChartCard(
            'Net Income (₹/acre)',
            netIncomeArr,
            Colors.teal,
          ),
        ),
        SizedBox(
          width: isWide ? (width - 64) / 3 : double.infinity,
          child: _barChartCard(
            'Water Saved (liters/acre)',
            waterSavedArr,
            Colors.lightBlue,
          ),
        ),
        SizedBox(
          width: isWide ? (width - 64) / 3 : double.infinity,
          child: _barChartCard(
            'Soil Organic Carbon (SOC) Gain (kg/acre)',
            socArr,
            Colors.purple,
          ),
        ),
        SizedBox(
          width: isWide ? (width - 64) / 3 : double.infinity,
          child: _barChartCard(
            'CO₂e Sequestered (kg/acre)',
            co2Arr,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  // Build bar chart
  Widget _barChartCard(String title, List<double> vals, Color color) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            AutoText(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: vals.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(toY: e.value, color: color, width: 18),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final labels = [
                            'Current',
                            'Year 1',
                            'Year 2',
                            'Year 3',
                          ];
                          final idx = v.toInt();
                          return AutoText(
                            labels[idx < labels.length ? idx : 0],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value
                                .toInt()
                                .toString(), // ✅ 100000 instead of 100K
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Chart arrays
    final yieldArr = _toList(metrics?['Yield (kg/acre)'] ?? []);
    final priceArr = _toList(metrics?['Price per KG (₹)'] ?? []);
    final netIncomeArr = _toList(metrics?['Net Income (₹/acre)'] ?? []);

    final waterSavedArr = _toList(environmental?['Water Saved per acre'] ?? []);
    final socArr = _toList(
      soilHealth?['Soil Organic Carbon (SOC) Gain (kg/acre)'] ?? [],
    );
    final co2Arr = _toList(climateChange?['CO₂e Sequestered (kg/acre)'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: AutoText(
          'Farmer Impact Dashboard - ${farmer?['name'] ?? ''}', // yahan text
          style: TextStyle(
            fontSize: 16.0, // desired chhota size
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
          IconButton(
            icon: const Icon(FontAwesomeIcons.whatsapp),
            onPressed: _shareOnWhatsApp,
          ),
        ],
      ),

      body: RepaintBoundary(
        key: _dashboardKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Farmer Card
              _farmerHeaderSection(),
              _greetingSection(),
              _rewardSection(),
              _environmentSection(),

              // Charts group (3 on top row)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: isWide ? (width - 64) / 3 : double.infinity,
                    child: _lineChartCard(
                      'Yield (kg/acre)',
                      yieldArr,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (width - 64) / 3 : double.infinity,
                    child: _lineChartCard(
                      'Price per KG (₹)',
                      priceArr,
                      Colors.pink,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (width - 64) / 3 : double.infinity,
                    child: _lineChartCard(
                      'Net Income (₹/acre)',
                      netIncomeArr,
                      Colors.teal,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (width - 64) / 3 : double.infinity,
                    child: _barChartCard(
                      'Water Saved (liters/acre)',
                      waterSavedArr,
                      Colors.lightBlue,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (width - 64) / 3 : double.infinity,
                    child: _barChartCard(
                      'Soil Organic Carbon (SOC) Gain (kg/acre)',
                      socArr,
                      Colors.purple,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (width - 64) / 3 : double.infinity,
                    child: _barChartCard(
                      'CO₂e Sequestered (kg/acre)',
                      co2Arr,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),

              // ✅ Replace old metric blocks with new editable table layout
              const SizedBox(height: 8),

              buildMetricSection("Farmer Metrics", metrics ?? {}),
              buildMetricSection("Environmental Metrics", environmental ?? {}),
              buildMetricSection("Soil Health", soilHealth ?? {}),
              buildMetricSection(
                "Climate Change Mitigation",
                climateChange ?? {},
              ),

              const SizedBox(height: 40),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledNumberField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoText(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  double _extractNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  // ✅ Helper to safely convert any dynamic input into a 4-length List<double>
  List<double> _toList(dynamic value) {
    // default 4 zeros
    List<double> zeros = [0.0, 0.0, 0.0, 0.0];
    try {
      if (value == null) return zeros;

      // If value is already a list (strings/numbers) -> parse to double and pad to 4
      if (value is List) {
        final parsed = value.map((e) {
          if (e == null) return 0.0;
          if (e == null) return 0.0;
          if (e is num) return e.toDouble();
          if (e.toString().trim() == '-' || e.toString().isEmpty) return 0.0;
          return double.tryParse(
                e.toString().replaceAll(RegExp(r'[^\d\.\-]'), ''),
              ) ??
              0.0;
        }).toList();
        while (parsed.length < 4)
          parsed.add(parsed.isNotEmpty ? parsed.last : 0.0);
        return parsed.sublist(0, 4);
      }

      // If value is a Map with keys current/year1/year2/year3, extract
      if (value is Map) {
        List<double> out = [];
        final order = [
          'current',
          'year1',
          'year2',
          'year3',
          'year_1',
          'year_2',
          'year_3',
        ];
        for (var k in ['current', 'year1', 'year2', 'year3']) {
          if (value.containsKey(k)) {
            final v = value[k];
            if (v is num)
              out.add(v.toDouble());
            else
              out.add(
                double.tryParse(
                      v.toString().replaceAll(RegExp(r'[^\d\.\-]'), ''),
                    ) ??
                    0.0,
              );
          } else {
            out.add(0.0);
          }
        }
        return out;
      }

      // If single number-like value: replicate across 4
      if (value is num)
        return [
          value.toDouble(),
          value.toDouble(),
          value.toDouble(),
          value.toDouble(),
        ];
      final parsed = double.tryParse(
        value.toString().replaceAll(RegExp(r'[^\d\.\-]'), ''),
      );
      if (parsed != null) return [parsed, parsed, parsed, parsed];
    } catch (_) {}
    return zeros;
  }
}
