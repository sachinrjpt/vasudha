import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../models/ks_sales_models.dart';
import '../screens/new_order_screen.dart';
import '../screens/ks_order_view_screen.dart';
import '../screens/ks_receipt_view.dart';
import 'package:vasudha/widgets/auto_text.dart';

class KSSalesPad extends StatefulWidget {
  const KSSalesPad({super.key});

  @override
  State<KSSalesPad> createState() => _KSSalesPadState();
}

class _KSSalesPadState extends State<KSSalesPad> {
  int selectedTab = 0;

  // 🔹 API STATE
  bool isLoading = true;
  String? errorMessage;
  KsSalesResponse? ksSalesResponse;

  // 🔹 FILTERED ORDERS
  List<KsOrder> filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _loadKsSalesData();
  }

  Future<void> _loadKsSalesData() async {
    final result = await ApiService.getKsSaleData();

    // print("KS SALES RESULT => $result");

    if (result['ok'] == true) {
      setState(() {
        ksSalesResponse = KsSalesResponse.fromJson(result);

        // 🔥 DEFAULT = ALL ORDERS
        filteredOrders = ksSalesResponse!.orders;

        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Something went wrong';
        isLoading = false;
      });
    }
  }

  // ================= TAB FILTER =================
  void _applyTabFilter(int index) {
    final allOrders = ksSalesResponse!.orders;

    setState(() {
      selectedTab = index;

      if (index == 0) {
        filteredOrders = allOrders;
      } else if (index == 1) {
        filteredOrders = allOrders
            .where((o) => o.status == 'Order Booked')
            .toList();
      } else if (index == 2) {
        filteredOrders = allOrders.where((o) => o.status == 'Closed').toList();
      } else if (index == 3) {
        filteredOrders = allOrders
            .where((o) => o.status == 'Cancelled')
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: AutoText(errorMessage!));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 HEADER ROW
          Row(
            children: [
              Expanded(
                child: AutoText(
                  "Vasudha KS Sales Pad",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              ElevatedButton.icon(
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewOrderScreen()),
                  );

                  if (created == true) {
                    _loadKsSalesData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const AutoText("New Order"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _searchBar(),
          const SizedBox(height: 12),
          _statusTabs(),
          const SizedBox(height: 12),
          _summaryCards(),
          const SizedBox(height: 12),
          Expanded(child: _orderList(filteredOrders)),
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _searchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ================= TABS =================
  Widget _statusTabs() {
    final allOrders = ksSalesResponse!.orders;

    final tabs = [
      {"title": "All Orders", "count": allOrders.length},
      {
        "title": "Pre-Orders(Open)",
        "count": allOrders.where((o) => o.status == 'Order Booked').length,
      },
      {
        "title": "Sold-Orders(Closed)",
        "count": allOrders.where((o) => o.status == 'Closed').length,
      },
      {
        "title": "Cancelled",
        "count": allOrders.where((o) => o.status == 'Cancelled').length,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: AutoText(
                "${tabs[index]['title']} (${tabs[index]['count']})",
              ),
              selected: isSelected,
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              onSelected: (_) {
                _applyTabFilter(index);
              },
            ),
          );
        }),
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCards() {
    final orders = filteredOrders; // yahan filteredOrders ka use karo

    final totalOrders = orders.length;
    final gross = orders.fold(0.0, (sum, o) => sum + o.grossSales);
    final received = orders.fold(0.0, (sum, o) => sum + o.amountReceived);
    final balance = gross - received;

    return Row(
      children: [
        _summaryItem("Total Orders", totalOrders.toString()),
        _summaryItem("Gross ₹", gross.toStringAsFixed(2)),
        _summaryItem("Received ₹", received.toStringAsFixed(2)),
        _summaryItem("Balance ₹", balance.toStringAsFixed(2)),
      ],
    );
  }

  Widget _summaryItem(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              AutoText(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              AutoText(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ORDER LIST =================
  Widget _orderList(List<KsOrder> orders) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  order.orderNo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                AutoText("Farmer: ${order.farmer?.name ?? '-'}"),
                AutoText("Village: ${order.farmer?.village ?? '-'}"),
                AutoText(
                  "Date: ${DateFormat('dd-MMM-yyyy').format(order.createdAt)}",
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusBadge(order.status),
                    const Spacer(),
                    AutoText(
                      "₹ ${order.grossSales.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 ACTION BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(
                      "View",
                      Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KsOrderViewScreen(
                              orderId: order.id, // 👈 API ke liye sirf ID
                            ),
                          ),
                        );
                      },
                    ),

                    _actionButton(
                      "Receipt",
                      Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KsReceiptViewScreen(orderId: order.id),
                          ),
                        );
                      },
                    ),

                    _actionButton(
                      "Edit",
                      Colors.red,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewOrderScreen(
                              orderId: order.id, // 👈 ye sabse important hai
                            ),
                          ),
                        );

                        // 🔄 agar update successful hua ho
                        if (updated == true) {
                          _loadKsSalesData(); // list refresh
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= STATUS BADGE =================
  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Order Booked':
        color = Colors.blue;
        break;
      case 'Delivered':
        color = Colors.orange;
        break;
      case 'Closed':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AutoText(status, style: const TextStyle(color: Colors.white)),
    );
  }

  // ================= ACTION BUTTON =================
  Widget _actionButton(
    String title,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: AutoText(title, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
