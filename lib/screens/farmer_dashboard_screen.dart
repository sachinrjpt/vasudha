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
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class FarmerDashboardScreen extends StatefulWidget {
  final int farmerId;
  const FarmerDashboardScreen({Key? key, required this.farmerId})
    : super(key: key);

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic>? farmer;
  Map<String, dynamic>? metrics;
  Map<String, dynamic>? environmental;
  Map<String, dynamic>? soilHealth;
  Map<String, dynamic>? climateChange;

  final ScreenshotController _screenshotController = ScreenshotController();
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
          const SnackBar(content: Text('No token found. Please log in again.')),
        );
        setState(() => _loading = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://vasudha.app/api/farmers/${widget.farmerId}/dashboard',
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
              if (metricVal is Map) {
                out[metricName.toString()] = [
                  metricVal['current'] ?? '-',
                  metricVal['year1'] ?? '-',
                  metricVal['year2'] ?? '-',
                  metricVal['year3'] ?? '-',
                ];
              } else if (metricVal is List) {
                // Handles [30, 27, 30, 31.5]
                out[metricName.toString()] = List.from(metricVal);
              } else {
                // Handles single numbers or strings
                out[metricName.toString()] = [metricVal, '-', '-', '-'];
              }
            });
            return out;
          }

          setState(() {
            farmer = Map<String, dynamic>.from(jsonData['farmer'] ?? {});
            metrics = parseMetricSection(jsonData['metrics']);

            // ✅ Restore missing "Yield (Farmer’s Unit/acre)" row if absent
            if (metrics != null &&
                !metrics!.containsKey('Yield (Farmer’s Unit/acre)') &&
                metrics!.containsKey('Yield (kg/acre)')) {
              metrics!['Yield (Farmer’s Unit/acre)'] = List.from(
                metrics!['Yield (kg/acre)'],
              );
            }

            environmental = parseMetricSection(
              jsonData['environmental_metrics'],
            );
            soilHealth = Map<String, dynamic>.from(
              jsonData['soil_health_metrics'] ?? {},
            );
            climateChange = Map<String, dynamic>.from(
              jsonData['climate_change_metrics'] ?? {},
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load dashboard data')),
          );
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized. Please log in again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch dashboard: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching dashboard: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _exportToPdf() async {
    try {
      setState(() => _saving = true);
      await Future.delayed(const Duration(milliseconds: 300)); // wait for UI

      final boundary =
          _dashboardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Dashboard not ready yet. Please try again.");
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Unable to get image bytes.");
      final imageBytes = byteData.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(pdfImage))));

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'dashboard.pdf',
        );
      } else {
        await Printing.layoutPdf(onLayout: (_) async => pdf.save());
      }
    } catch (e, st) {
      debugPrint("❌ PDF export failed: $e\n$st");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ PDF export failed: $e")));
      }
    } finally {
      if (context.mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final name = farmer?['name'] ?? 'Farmer';
    final phone = farmer?['phone'] ?? '-';
    final msg =
        '''
👨‍🌾 Farmer Dashboard - $name
📞 Mobile: $phone
🔗 View Dashboard in App
''';

    final encodedMsg = Uri.encodeComponent(msg);
    final url = Uri.parse("https://wa.me/?text=$encodedMsg");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp')));
    }
  }

  // helper used above
  // ✅ Web-style metrics handle both list and object types
  String _metricCurrentAsString(Map<String, dynamic>? map, String key) {
    if (map == null) return '';
    final val = map[key];
    if (val == null) return '';
    if (val is List && val.isNotEmpty) return val[0]?.toString() ?? '';
    if (val is Map) {
      if (val.containsKey('current')) return val['current'].toString();
      if (val.containsKey('Current')) return val['Current'].toString();
    }
    return val.toString();
  }

  Future<void> _saveFieldToServer() async {
    if (farmer == null) return;
    setState(() => _saving = true);

    try {
      final farmerId = farmer!['id'];
      if (farmerId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Farmer ID not found.')));
        setState(() => _saving = false);
        return;
      }

      final result = await ApiService.updateFarmerAnalysis(
        farmerId: farmerId,
        cropId: farmer?['cropp'] ?? 0,
        irrigationMethodId: farmer?['irrigationn_method'] ?? 0,
        waterUsageInMm:
            double.tryParse(_waterUsageMmController.text.trim()) ?? 0,
        landSize: farmer?['land_size']?.toString() ?? "1",
        waterUsageInLtr:
            double.tryParse(farmer?['water_usage_in_ltr']?.toString() ?? "0") ??
            0,
        irrigationEfficiency:
            double.tryParse(_irrigationEffController.text.trim()) ?? 0,
        totalYield: double.tryParse(_totalYieldController.text.trim()) ?? 0,
        salePricePerUnit:
            double.tryParse(_salePriceController.text.trim()) ?? 0,
        farmGatePrice:
            double.tryParse(_farmGatePriceController.text.trim()) ?? 0,
        totalValue:
            double.tryParse(
              _netIncomeChangeController.text.trim().replaceAll('%', ''),
            ) ??
            0,
        machineryIds:
            (farmer?['machinery_id'] != null &&
                farmer!['machinery_id'].toString().isNotEmpty)
            ? farmer!['machinery_id']
                  .toString()
                  .split(',')
                  .map((e) => int.tryParse(e.trim()) ?? 0)
                  .where((e) => e > 0)
                  .toList()
            : [],
      );

      if (result['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Analysis updated successfully'),
          ),
        );

        // ✅ Optimistically update local UI
        setState(() {
          void updateMetric(String key, String newVal) {
            if (metrics == null) metrics = {};
            if (metrics![key] == null) {
              metrics![key] = [newVal, '-', '-', '-'];
            } else {
              (metrics![key] as List)[0] = newVal;
            }
          }

          updateMetric(
            'Intercropping Income (10% of the main crop) (₹/acre)',
            _intercroppingIncomeController.text.trim(),
          );
          updateMetric(
            'Total Input Cost Reduction %',
            _inputCostReductionController.text.trim(),
          );
          updateMetric(
            'Net Income Change %',
            _netIncomeChangeController.text.trim(),
          );

          farmer!['total_yield'] = _totalYieldController.text.trim();
          farmer!['price_per_kg'] = _salePriceController.text.trim();
          farmer!['farm_gate_price'] = _farmGatePriceController.text.trim();
          farmer!['irrigation_efficiency'] = _irrigationEffController.text
              .trim();
          farmer!['water_usage_in_mm'] = _waterUsageMmController.text.trim();
        });

        // Refresh data
        await _fetch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }

    setState(() => _saving = false);
  }

  // ✅ Auto recalc all dependent metrics instantly (like web)
  void _recalculateDerivedMetrics() {
    if (metrics == null) return;

    double yield = double.tryParse(_totalYieldController.text) ?? 0;
    double pricePerKg = double.tryParse(_salePriceController.text) ?? 0;
    double labourCost = _getMetricValue('Labour & Ops Cost (₹/acre)');
    double inputCost = _getMetricValue('Input cost (except labour)');
    double prevTotalInput = _getMetricValue(
      'Total Input Cost (inclusive inputs and labour) (₹/acre)',
    );

    // Calculations
    double grossIncome = yield * pricePerKg;
    double intercroppingIncome = grossIncome * 0.10;
    double totalGrossIncome = grossIncome + intercroppingIncome;
    double totalInputCost = labourCost + inputCost;
    double netIncome = totalGrossIncome - totalInputCost;

    // Percent reduction vs previous
    double reductionPercent = 0;
    if (prevTotalInput > 0) {
      reductionPercent =
          ((prevTotalInput - totalInputCost) / prevTotalInput) * 100;
    }

    // Update metrics instantly
    void setMetric(String name, dynamic val) {
      if (metrics![name] == null)
        metrics![name] = [val, '-', '-', '-'];
      else
        (metrics![name] as List)[0] = val;
    }

    setState(() {
      setMetric(
        'Gross Income (Main Crop) (₹/acre)',
        grossIncome.toStringAsFixed(2),
      );
      setMetric(
        'Intercropping Income (10% of the main crop) (₹/acre)',
        intercroppingIncome.toStringAsFixed(2),
      );
      setMetric(
        'Total Gross Income (₹/acre)',
        totalGrossIncome.toStringAsFixed(2),
      );
      setMetric(
        'Total Input Cost (inclusive inputs and labour) (₹/acre)',
        totalInputCost.toStringAsFixed(2),
      );
      setMetric(
        'Total Input Cost Reduction %',
        '${reductionPercent.toStringAsFixed(2)}%',
      );
      setMetric('Net Income (₹/acre)', netIncome.toStringAsFixed(2));
    });
  }

  // helper to get current numeric value of a metric
  double _getMetricValue(String key) {
    try {
      final val = metrics?[key];
      if (val is List && val.isNotEmpty) {
        return double.tryParse(
              val[0].toString().replaceAll(RegExp(r'[^\d\.\-]'), ''),
            ) ??
            0;
      }
    } catch (_) {}
    return 0;
  }

  void _showEditDialog({
    required String title,
    required TextEditingController controller,
    required int farmerId,
  }) {
    final editableMetrics = [
      'Intercropping Income (10% of the main crop) (₹/acre)',
      'Total Input Cost Reduction %',
      'Net Income Change %',
      'Water Use Reduction (%)',
    ];

    if (!editableMetrics.contains(title)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This field is not editable.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter new value',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newValue = controller.text.trim();
                if (newValue.isEmpty) return;
                Navigator.pop(context);

                // ✅ Update locally first
                setState(() {
                  if (metrics == null) metrics = {};
                  if (metrics![title] == null) {
                    metrics![title] = [newValue, '-', '-', '-'];
                  } else {
                    (metrics![title] as List)[0] = newValue;
                  }
                });

                // ✅ Send to server using existing method
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saving...')));

                // Assign controller values properly
                if (title ==
                    'Intercropping Income (10% of the main crop) (₹/acre)') {
                  _intercroppingIncomeController.text = newValue;
                } else if (title == 'Total Input Cost Reduction %') {
                  _inputCostReductionController.text = newValue;
                } else if (title == 'Net Income Change %') {
                  _netIncomeChangeController.text = newValue;
                } else if (title == 'Water Use Reduction (%)') {
                  // optional future metric
                }

                await _saveFieldToServer();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ $title updated successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Small helper to display numeric with rupee if needed
  String _formatAny(dynamic v) {
    if (v == null) return '-';
    if (v is num) return '₹${v.toStringAsFixed(2)}';
    if (v.toString().contains('₹')) return v.toString();
    return v.toString();
  }

  // ✅ Convert numeric string or null safely to double
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^\d\.\-]'), '')) ??
        0;
  }

  // Build line chart (fl_chart)
  Widget _lineChartCard(String title, List<double> vals, Color color) {
    final spots = vals
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
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
                          return Text(
                            labels[idx < labels.length ? idx : 0],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
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

  Widget _farmerHeaderSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  (farmer?['profile_image'] != null &&
                      farmer!['profile_image'].toString().isNotEmpty)
                  ? NetworkImage(
                      'https://vasudha.app/${farmer!['profile_image']}',
                    )
                  : const AssetImage('assets/logo.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer?['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('📞 ${farmer?['phone'] ?? '-'}'),
                  Text(
                    '🌍 ${farmer?['state'] ?? '-'} , ${farmer?['district'] ?? '-'}',
                  ),
                  Text('Plot ID: ${farmer?['plot_id'] ?? '-'}'),
                ],
              ),
            ),
            SizedBox(
              width: 140,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _share,
                    icon: const Icon(FontAwesomeIcons.whatsapp),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _exportToPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export'),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          return Text(
                            labels[idx < labels.length ? idx : 0],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
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

  // share
  void _share() {
    final name = farmer?['name'] ?? 'Farmer';
    final phone = farmer?['phone'] ?? '';
    final msg =
        '👨‍🌾 Farmer Dashboard - $name\n📞 $phone\nOpen app to view details.';
    Share.share(msg);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Chart arrays
    final yieldArr = _toList(
      metrics?['Yield (kg/acre)'] ?? metrics?['Yield'] ?? 0,
    );
    final priceArr = _toList(
      metrics?['Price per KG (₹)'] ?? metrics?['Price per KG'] ?? 0,
    );
    // net income might not exist in metrics (your sample didn't include - web had it); attempt to compute or fall back
    final netIncomeArr = _toList(
      metrics?['Net Income (₹/acre)'] ?? metrics?['Net Income'] ?? [0, 0, 0, 0],
    );

    final waterSavedRaw =
        environmental?['Water Saved per acre'] ??
        environmental?['Water Saved (liters/acre)'] ??
        environmental?['Water Saved (liters)'] ??
        environmental?['Water Saved'];

    List<double> waterSavedArr = [];
    if (waterSavedRaw is num)
      waterSavedArr = [
        0,
        waterSavedRaw.toDouble(),
        waterSavedRaw.toDouble(),
        waterSavedRaw.toDouble(),
      ];
    else
      waterSavedArr = _toList(waterSavedRaw);

    final socArr = _toList(
      soilHealth?['Soil Organic Carbon (SOC) Gain (kg/acre)'],
    );
    final co2Arr = _toList(climateChange?['CO₂e Sequestered (kg/acre)']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Impact Dashboard - ${farmer?['name'] ?? ''}'),
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
        child: Screenshot(
          controller: _screenshotController,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Farmer Card
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              (farmer?['profile_image'] != null &&
                                  farmer!['profile_image']
                                      .toString()
                                      .isNotEmpty)
                              ? NetworkImage(
                                  'https://vasudha.app/${farmer!['profile_image']}',
                                )
                              : const AssetImage('assets/logo.png')
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmer?['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('📞 ${farmer?['phone'] ?? '-'}'),
                              Text(
                                '🌍 ${farmer?['state'] ?? '-'} , ${farmer?['district'] ?? '-'}',
                              ),
                              Text('Plot ID: ${farmer?['plot_id'] ?? '-'}'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _share,
                                icon: const Icon(FontAwesomeIcons.whatsapp),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _exportToPdf,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Export'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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

                buildEditableTable(
                  title: "Farmer Metrics",
                  data: metrics ?? {},
                  isEditable: true,
                ),
                buildEditableTable(
                  title: "Environmental Metrics",
                  data: environmental ?? {},
                  isEditable: true,
                ),
                buildEditableTable(
                  title: "Soil Health",
                  data: soilHealth ?? {},
                  isEditable: false,
                ),
                buildEditableTable(
                  title: "Climate Change Mitigation",
                  data: climateChange ?? {},
                  isEditable: false,
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Tip: Double-tap a cell to edit & auto-save',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledNumberField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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

  // ✅ Common editable table for each metric category
  Widget buildEditableTable({
    required String title,
    required Map<String, dynamic> data,
    required bool isEditable,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    // detect how many columns (years) we need dynamically
    int maxCols = 0;
    for (var v in data.values) {
      if (v is List && v.length > maxCols) maxCols = v.length;
    }
    if (maxCols == 0) maxCols = 1;

    final columns = [
      'Current',
      ...List.generate(maxCols - 1, (i) => 'Year ${i + 1}'),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.green.shade100,
                ),
                border: TableBorder.all(color: Colors.grey.shade300),
                columns: [
                  const DataColumn(label: Text('Metric')),
                  ...columns.map((c) => DataColumn(label: Text(c))),
                ],
                rows: data.entries.map((entry) {
                  final metric = entry.key;
                  final vals = entry.value;
                  final List<dynamic> cells = vals is List ? vals : [vals];

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          metric,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...List.generate(columns.length, (i) {
                        final v = (i < cells.length)
                            ? cells[i].toString()
                            : '-';

                        // ✅ Only allow double-tap edit for these specific metrics
                        final editableMetrics = [
                          'Intercropping Income (10% of the main crop) (₹/acre)',
                          'Total Input Cost Reduction %',
                          'Net Income Change %',
                          'Water Use Reduction (%)',
                        ];

                        final canEdit =
                            isEditable &&
                            i == 0 &&
                            editableMetrics.contains(metric);

                        return DataCell(
                          canEdit
                              ? GestureDetector(
                                  onDoubleTap: () => _showEditDialog(
                                    title: metric,
                                    controller: TextEditingController(text: v),
                                    farmerId: widget
                                        .farmerId, // ✅ use farmerId from widget
                                  ),

                                  child: Text(
                                    v,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              : Text(v),
                        );
                      }),
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
}
