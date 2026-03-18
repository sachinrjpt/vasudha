import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:html' as html;
import 'package:vasudha/widgets/auto_text.dart';
import 'package:flutter/services.dart';

class KsReceiptViewScreen extends StatelessWidget {
  final int orderId;

  const KsReceiptViewScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoText('KS Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context, orderId),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context, orderId),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.showKsSale(orderId: orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final order = data['order'];
          final ks = data['ks'];
          final crops = data['crops'] as List;
          final inputNames = data['input_names'] as List;
          final lines = order['lines'] as List;

          // crop name
          String cropName = '-';
          for (final c in crops) {
            if (c['id'] == order['crop_id']) {
              cropName = c['crops'];
              break;
            }
          }

          final gross = double.parse(order['gross_sales']);
          final received = double.parse(order['amount_received']);
          final balance = gross - received;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: AutoText(
                    'VASUDHA – KS RECEIPT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                _kv('Order No', order['order_no']),
                _kv('Order Date', formatDateTime(order['created_at'])),
                _kv(
                  'Delivery',
                  '${order['delivery_date']} • ${order['time_window']} • ${order['place']}',
                ),
                const Divider(),

                _kv('KS', '${ks['name']} (${ks['phone']})'),
                const Divider(),

                _kv('Customer', order['farmer']['name']),
                _kv('Mobile', order['farmer']['phone']),
                _kv('Village', order['farmer']['village']),
                _kv('Crop / Area', '$cropName • ${order['area']} Acre'),

                const SizedBox(height: 16),

                // Table Header
                Row(
                  children: const [
                    _T('Type', 2),
                    _T('Item', 3),
                    _T('Qty', 1),
                    _T('Unit', 1),
                    _T('Rate', 1),
                    _T('Total', 1),
                  ],
                ),
                const Divider(),

                ...lines.map((l) {
                  return Row(
                    children: [
                      _T(l['type'], 2),
                      _T(resolveItemName(l['item_id'], inputNames), 3),
                      _T(l['qty'], 1),
                      _T(l['unit'], 1),
                      _T(l['rate'], 1),
                      _T(l['line_total'], 1),
                    ],
                  );
                }),

                const Divider(),
                _kv('Notes', order['notes'] ?? '-'),
                const SizedBox(height: 8),

                _kv('Received', '₹ $received'),
                _kv('Mode', order['payment_mode']),
                _kv('Balance', '₹ $balance'),
                _kv('Gross Sales', '₹ $gross'),
              ],
            ),
          );
        },
      ),
    );
  }
}

// helpers
Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: AutoText(k, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: AutoText(v)),
      ],
    ),
  );
}

class _T extends StatelessWidget {
  final String text;
  final int flex;
  const _T(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: AutoText(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

String formatDateTime(String raw) {
  try {
    final utcDate = DateTime.parse(raw).toUtc();
    final localDate = utcDate.toLocal();

    return DateFormat('dd/MM/yyyy, hh:mm:ss a').format(localDate);
  } catch (e) {
    return raw;
  }
}

Future<pw.Document> _buildPdf(
  BuildContext context,
  Map<String, dynamic> order,
  Map<String, dynamic> ks,
  List lines,
  Map<String, dynamic> farmer,
  String cropName,
  double gross,
  double received,
  double balance,
  List inputNames,
) async {
  final lang = Provider.of<LanguageProvider>(context, listen: false);

  // 🔤 Translations
  final title = await lang.translate("VASUDHA – KS RECEIPT");
  final orderNo = await lang.translate("Order No");
  final orderDate = await lang.translate("Order Date");
  final delivery = await lang.translate("Delivery");
  final ksText = await lang.translate("KS");
  final customer = await lang.translate("Customer");
  final mobile = await lang.translate("Mobile");
  final village = await lang.translate("Village");
  final cropArea = await lang.translate("Crop / Area");
  final notes = await lang.translate("Notes");
  final receivedT = await lang.translate("Received");
  final mode = await lang.translate("Mode");
  final balanceT = await lang.translate("Balance");
  final grossSales = await lang.translate("Gross Sales");

  final typeT = await lang.translate("Type");
  final itemT = await lang.translate("Item");
  final qtyT = await lang.translate("Qty");
  final unitT = await lang.translate("Unit");
  final rateT = await lang.translate("Rate");
  final totalT = await lang.translate("Total");

  final pdf = pw.Document();

  // 🔤 Load Unicode Fonts
  final regularFontData = await rootBundle.load(
    "assets/fonts/NotoSans-Regular.ttf",
  );
  final boldFontData = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");

  final ttf = pw.Font.ttf(regularFontData);
  final ttfBold = pw.Font.ttf(boldFontData);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),

      build: (context) {
        return [
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text('$orderNo: ${order['order_no']}'),
          pw.Text('$orderDate: ${formatDateTime(order['created_at'])}'),

          pw.Text(
            '$delivery: ${order['delivery_date']} • ${order['time_window']} • ${order['place']}',
          ),

          pw.Divider(),

          pw.Text('$ksText: ${ks['name']} (${ks['phone']})'),

          pw.Divider(),

          pw.Text('$customer: ${farmer['name']}'),
          pw.Text('$mobile: ${farmer['phone']}'),
          pw.Text('$village: ${farmer['village']}'),
          pw.Text('$cropArea: $cropName • ${order['area']} Acre'),

          pw.SizedBox(height: 15),

          pw.Table.fromTextArray(
            headers: [typeT, itemT, qtyT, unitT, rateT, totalT],
            data: lines.map((l) {
              return [
                l['type'],
                resolveItemName(l['item_id'], inputNames),
                l['qty'].toString(),
                l['unit'],
                l['rate'].toString(),
                l['line_total'].toString(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),

          pw.Divider(),

          pw.Text('$notes: ${order['notes'] ?? '-'}'),

          pw.SizedBox(height: 8),

          pw.Text('$receivedT: ₹ $received'),
          pw.Text('$mode: ${order['payment_mode']}'),
          pw.Text('$balanceT: ₹ $balance'),

          pw.Text(
            '$grossSales: ₹ $gross',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ];
      },
    ),
  );

  return pdf;
}

Future<void> _printReceipt(BuildContext context, int orderId) async {
  final data = await ApiService.showKsSale(orderId: orderId);

  final order = data['order'];
  final ks = data['ks'];
  final lines = order['lines'];
  final farmer = order['farmer'];
  final crops = data['crops'];
  final inputNames = data['input_names'];

  String cropName = '-';
  for (final c in crops) {
    if (c['id'] == order['crop_id']) cropName = c['crops'];
  }

  final gross = double.parse(order['gross_sales']);
  final received = double.parse(order['amount_received']);
  final balance = gross - received;

  final pdf = await _buildPdf(
    context,
    order,
    ks,
    lines,
    farmer,
    cropName,
    gross,
    received,
    balance,
    inputNames,
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

Future<void> _downloadPdf(BuildContext context, int orderId) async {
  final data = await ApiService.showKsSale(orderId: orderId);

  final order = data['order'];
  final ks = data['ks'];
  final lines = order['lines'];
  final farmer = order['farmer'];
  final crops = data['crops'];
  final inputNames = data['input_names'];

  String cropName = '-';
  for (final c in crops) {
    if (c['id'] == order['crop_id']) cropName = c['crops'];
  }

  final gross = double.parse(order['gross_sales']);
  final received = double.parse(order['amount_received']);
  final balance = gross - received;

  final pdf = await _buildPdf(
    context,
    order,
    ks,
    lines,
    farmer,
    cropName,
    gross,
    received,
    balance,
    inputNames,
  );
  final bytes = await pdf.save();

  // if (kIsWeb) {

  //   final blob = html.Blob([bytes], 'application/pdf');
  //   final url = html.Url.createObjectUrlFromBlob(blob);

  //   html.AnchorElement(href: url)
  //     ..setAttribute('download', 'ks_receipt_$orderId.pdf')
  //     ..click();

  //   html.Url.revokeObjectUrl(url);
  // } else {
  // 📱 MOBILE DOWNLOAD
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/ks_receipt_$orderId.pdf');
  await file.writeAsBytes(bytes);

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: AutoText('PDF saved at ${file.path}')));
  // }
}

String resolveItemName(dynamic id, List items) {
  for (final i in items) {
    if (i['id'] == id) return i['input_name'];
  }
  return '-';
}
