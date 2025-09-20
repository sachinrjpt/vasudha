import 'package:flutter/material.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
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

                // --- Tab Contents ---
                SizedBox(
                  height: 500, // Adjust height as needed
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // --- Summary Tab ---
                      _buildSummaryTab(),

                      // --- Per Acre Results Tab ---
                      _buildPerAcreResultsTab(),
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

  // --- SUMMARY TAB UI ---
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReadOnlyField("Total Seed Cost", "0.00"),
          _buildReadOnlyField("Total Chemical Fertiliser Cost", "0.00"),
          _buildReadOnlyField("Total Chemical Pesticide Cost", "0.00"),
          _buildReadOnlyField(
              "Total Cost Sustainable Agriculture - Fertilisers", "0.00"),
          _buildReadOnlyField(
              "Total Cost Sustainable Agriculture - Pesticides", "0.00"),
          _buildReadOnlyField("Total value of the Produce", "0.00"),
          _buildReadOnlyField("Total input cost", "0.00"),
          _buildReadOnlyField(
              "Net income as per the plot size", "0.00"),
        ],
      ),
    );
  }

  // --- PER ACRE RESULTS TAB UI ---
  Widget _buildPerAcreResultsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReadOnlyField("Total production per acre (in KG)", "0.00"),
          _buildReadOnlyField(
              "Total value of the Produce per acre", "0.00"),
          _buildReadOnlyField("Input cost per acre", "0.00"),
          _buildReadOnlyField("Labour costs per acre", "0.00"),
          _buildReadOnlyField("Total input cost per acre", "0.00"),
          _buildReadOnlyField("Net income per acre", "0.00"),
        ],
      ),
    );
  }

  // --- REUSABLE READ-ONLY FIELD ---
  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        enabled: false,
        controller: TextEditingController(text: value),
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
