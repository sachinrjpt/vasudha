import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/ks_receipt_view.dart';
import 'package:vasudha/widgets/auto_text.dart';

class KsOrderViewScreen extends StatefulWidget {
  final int orderId;
  final bool isReceipt;

  const KsOrderViewScreen({
    super.key,
    required this.orderId,
    this.isReceipt = false, // default normal view
  });

  @override
  State<KsOrderViewScreen> createState() => _KsOrderViewScreenState();
}

class _KsOrderViewScreenState extends State<KsOrderViewScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.showKsSale(orderId: widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoText(
          widget.isReceipt ? 'KS Receipt' : 'Vasudha KS Sales Pad',
        ),
        actions: widget.isReceipt
            ? [] // receipt me edit/cancel nahi
            : [
                TextButton(
                  onPressed: () {},
                  child: const AutoText(
                    'Edit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const AutoText(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!["ok"] != true) {
            return const Center(child: AutoText("Failed to load order"));
          }

          final order = snapshot.data!["order"] ?? {};
          final crops = snapshot.data!["crops"] as List? ?? [];
          final ks = snapshot.data!["ks"];
          final inputNames = snapshot.data!["input_names"] as List? ?? [];
          final orderLines = order["lines"] ?? [];
          final grossSales =
              double.tryParse(order["gross_sales"]?.toString() ?? '0') ?? 0;

          final amountReceived =
              double.tryParse(order["amount_received"]?.toString() ?? '0') ?? 0;

          final balance = grossSales - amountReceived;

          String cropName = '-';
          for (final c in crops) {
            if (c["id"] == order["crop_id"]) {
              cropName = c["crops"] ?? '-';
              break;
            }
          }

          // 👇 warna purana normal UI
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // ================= Order Details =================
                _sectionCard(
                  title: 'Order Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Order No', order["order_no"] ?? '-'),
                      _statusChip(order["status"] ?? 'Pending'),
                      _infoRow('Created', order["created_at"] ?? '-'),
                      _infoRow('Payment Mode', order["payment_mode"] ?? '-'),
                    ],
                  ),
                ),

                // ================= Customer =================
                _sectionCard(
                  title: 'Customer (Farmer)',
                  child: Column(
                    children: [
                      _infoRow('Name', order["farmer"]?["name"] ?? '-'),
                      _infoRow('Village', order["farmer"]?["village"] ?? '-'),
                      _infoRow('Mobile', order["farmer"]?["phone"] ?? '-'),
                      _infoRow('Crop', cropName),
                      _infoRow('Area', '${order["area"] ?? '-'} Acre'),
                    ],
                  ),
                ),

                // ================= Delivery =================
                _sectionCard(
                  title: 'Delivery / Service',
                  child: Column(
                    children: [
                      _infoRow('Delivery Date', order["delivery_date"] ?? '-'),
                      _infoRow('Time Window', order["time_window"] ?? '-'),
                      _infoRow('Place', order["place"] ?? '-'),
                    ],
                  ),
                ),

                // ================= Supplier =================
                _sectionCard(
                  title: 'Supplier (KS)',
                  child: Column(
                    children: [
                      _infoRow('KS Name', ks?["name"] ?? '-'),
                      _infoRow('KS Phone', ks?["phone"] ?? '-'),
                      _infoRow('Notes', order["ks_notes"] ?? '-'),
                    ],
                  ),
                ),

                // ================= Order Lines =================
                _sectionCard(
                  title: 'Order Lines',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _orderLineHeader(),
                        ...List.generate(orderLines.length, (i) {
                          final item = orderLines[i];
                          return _orderLineRow(
                            index: '${i + 1}',
                            type: item["type"] ?? '-',
                            item: resolveItemName(item["item_id"], inputNames),
                            qty: item["qty"]?.toString() ?? '0',
                            unit: item["unit"] ?? '-',
                            rate: item["rate"]?.toString() ?? '0',
                            total: item["line_total"]?.toString() ?? '0',
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // ================= Payment Summary =================
                _sectionCard(
                  title: 'Payment Summary',
                  child: Column(
                    children: [
                      _infoRow(
                        'Gross Sales',
                        '₹ ${grossSales.toStringAsFixed(2)}',
                      ),
                      _infoRow(
                        'Amount Received',
                        '₹ ${amountReceived.toStringAsFixed(2)}',
                      ),
                      _infoRow('Balance', '₹ ${balance.toStringAsFixed(2)}'),
                      _infoRow('Notes', order["notes"] ?? '-'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================== COMMON WIDGETS ==================

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoText(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: AutoText(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 6,
            child: AutoText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Chip(
        label: AutoText(status),
        backgroundColor: Colors.orange.shade200,
      ),
    );
  }

  Widget _orderLineHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey.shade200,
      child: const Row(
        children: [
          _TableText('#', 1),
          _TableText('Type', 3),
          _TableText('Item', 3),
          _TableText('Qty', 2),
          _TableText('Unit', 2),
          _TableText('Rate', 2),
          _TableText('Total', 2),
        ],
      ),
    );
  }

  Widget _orderLineRow({
    required String index,
    required String type,
    required String item,
    required String qty,
    required String unit,
    required String rate,
    required String total,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _TableText(index, 1),
          _TableText(type, 3),
          _TableText(item, 3),
          _TableText(qty, 2),
          _TableText(unit, 2),
          _TableText(rate, 2),
          _TableText(total, 2),
        ],
      ),
    );
  }
}

String resolveItemName(dynamic id, List items) {
  for (final i in items) {
    if (i["id"] == id) {
      return i["input_name"] ?? '-';
    }
  }
  return '-';
}

class _TableText extends StatelessWidget {
  final String text;
  final int flex;

  const _TableText(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: flex * 80,
      child: AutoText(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
