import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ✅ apne service file ka sahi path

class SummaryScreen extends StatefulWidget {
  final String farmerId;

  const SummaryScreen({super.key, required this.farmerId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> summary = {};
  Map<String, dynamic> perAcre = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSummary();
    print(summary);
  }

  Future<void> _fetchSummary() async {
    final res = await ApiService.getFarmerSummary(widget.farmerId);

    if (res["ok"] == true) {
      setState(() {
        summary = res["data"]["summary"] ?? {};
        perAcre = res["data"]["per_acre"] ?? {};
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Failed to load summary")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // --- Tabs ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black87,
                          indicator: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tabs: const [
                            Tab(text: "Summary"),
                            Tab(text: "Per Acre Results"),
                          ],
                        ),
                      ),

                      // --- Tab Content ---
                      SizedBox(
                        height: 600,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSummaryTab(),
                            _buildPerAcreTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ✅ Summary Tab - Matches Laravel JSON keys exactly
  Widget _buildSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        children: [
          _buildField("Total Seed Cost", summary["Total Seed Cost"]),
          _buildField("Total Chemical Fertiliser Cost", summary["Total Chemical Fertiliser Cost"]),
          _buildField("Total Chemical Pesticide Cost", summary["Total Chemical Pesticide Cost"]),
          _buildField("Total Cost Sustainable Agriculture - Fertilisers", summary["Total Cost Sustainable Agriculture - Fertilisers"]),
          _buildField("Total Cost Sustainable Agriculture - Pesticides", summary["Total Cost Sustainable Agriculture - Pesticides"]),
          _buildField("Total value of the Produce", summary["Total value of the Produce"]),
          _buildField("Total input cost", summary["Total input cost"]),
          _buildField("Net income as per the plot size", summary["Net income as per the plot size"]),
        ],
      ),
    );
  }

  // ✅ Per Acre Results Tab
  Widget _buildPerAcreTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        children: [
          _buildField("Total production per acre (in KG)", perAcre["Total production per acre (in KG)"]),
          _buildField("Total value of the Produce per acre", perAcre["Total value of the Produce per acre"]),
          _buildField("Input cost per acre (Inputs without labour)", perAcre["Input cost per acre (Inputs without labour)"]),
          _buildField("Labour costs per acre (Hired labour and household labour)", perAcre["Labour costs per acre (Hired labour and household labour)"]),
          _buildField("Total input cost per acre", perAcre["Total input cost per acre"]),
          _buildField("Net income per acre", perAcre["Net income per acre"]),
        ],
      ),
    );
  }

  // 🧱 Reusable TextField (Read-only)
  Widget _buildField(String label, dynamic value) {
    final textValue = value != null ? value.toString() : "0.00";
    return SizedBox(
      width: 250,
      child: TextField(
        enabled: false,
        controller: TextEditingController(text: textValue),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
