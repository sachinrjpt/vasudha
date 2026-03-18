import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ✅ apne service file ka sahi path
import 'package:vasudha/widgets/auto_text.dart';

class SummaryScreen extends StatefulWidget {
  final String plotId;
  final Map<String, dynamic> moduleData;

  const SummaryScreen({
    super.key,
    required this.plotId,
    required this.moduleData,
  });

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

  // Future<void> _fetchSummary() async {
  //   final res = await ApiService.getFarmerSummary(widget.plotId);

  //   if (res["ok"] == true) {
  //     setState(() {
  //       summary = res["data"]["summary"] ?? {};
  //       perAcre = res["data"]["per_acre"] ?? {};
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() => isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(res["message"] ?? "Failed to load summary")),
  //     );
  //   }
  // }

  Future<void> _fetchSummary() async {
    try {
      final res = await ApiService.getFarmerSummary(widget.plotId);

      if (res["ok"] == true && res["data"] != null) {
        setState(() {
          summary = res["data"]["summary"] ?? {};
          perAcre = res["data"]["per_acre"] ?? {};
          isLoading = false;
        });
      } else {
        // 🔥 Audit not created yet → show empty state
        setState(() {
          summary = {};
          perAcre = {};
          isLoading = false;
        });
      }
    } catch (e) {
      // 🔥 Network / ModelNotFoundException / 500 error
      setState(() {
        summary = {};
        perAcre = {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (summary.isEmpty && perAcre.isEmpty)
          ? _buildEmptyState()
          : Column(
              children: [
                const SizedBox(height: 16),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(child: AutoText("Summary")),
                      Tab(child: AutoText("Per Acre Results")),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildSummaryTab(), _buildPerAcreTab()],
                  ),
                ),
              ],
            ),
    );
  }

  // ✅ Summary Tab - Matches Laravel JSON keys exactly
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        children: [
          _buildField(
            "Total Labour Cost (Hired + family labour)",
            summary["Total Labour Cost (Hired + family labour)"],
          ),
          _buildField(
            "Total Machinery,Energy and other costs",
            summary["Total Machinery,Energy and other costs"],
          ),
          _buildField("Total Seed Cost", summary["Total Seed Cost"]),
          _buildField(
            "Total Chemical Fertiliser Cost",
            summary["Total Chemical Fertiliser Cost"],
          ),
          _buildField(
            "Total Chemical Pesticide Cost",
            summary["Total Chemical Pesticide Cost"],
          ),
          _buildField(
            "Total Cost Sustainable Agriculture - Fertilisers",
            summary["Total Cost Sustainable Agriculture - Fertilisers"],
          ),
          _buildField(
            "Total Cost Sustainable Agriculture - Pesticides",
            summary["Total Cost Sustainable Agriculture - Pesticides"],
          ),
          _buildField(
            "Total value of the Produce",
            summary["Total value of the Produce"],
          ),
          _buildField(
            "Total Expense (Rs)",
            summary["Total Expense(Rs)"], // ✅ FIXED KEY
          ),
          _buildField(
            "Net income as per the plot size",
            summary["Net income as per the plot size"],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const AutoText(
            "No Audit Summary Available",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          AutoText(
            "Please complete and save the audit first.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ✅ Per Acre Results Tab
  Widget _buildPerAcreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        children: [
          _buildField(
            "Total production per acre (in KG)",
            perAcre["Total production per acre (in KG)"],
          ),
          _buildField(
            "Total value of the Produce per acre",
            perAcre["Total value of the Produce per acre"],
          ),
          _buildField(
            "Agricultural Input Cost per acre",
            perAcre["Agricultural Input Cost per acre"], // ✅ FIXED
          ),
          _buildField(
            "Labour costs per acre (Hired labour and household labour)",
            perAcre["Labour costs per acre (Hired labour and household labour)"],
          ),
          _buildField(
            "Total Expense per acre (Rs)",
            perAcre["Total Expense per acre (Rs)"], // ✅ FIXED
          ),
          _buildField("Net income per acre", perAcre["Net income per acre"]),
          _buildField(
            "Total Machinery,Energy and other costs per acre",
            perAcre["Total Machinery,Energy and other costs per acre"],
          ),
        ],
      ),
    );
  }

  // 🧱 Reusable TextField (Read-only)
  Widget _buildField(String label, dynamic value) {
    final textValue = value != null ? value.toString() : "0.00";

    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoText(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AutoText(
            textValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
