import 'package:flutter/material.dart';

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Costs & Expenditure",
            style: TextStyle(color: Colors.black)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(6),
          ),
          tabs: const [
            Tab(text: "Seed Cost"),
            Tab(text: "Chemical Fertilizers"),
            Tab(text: "Chemical Pesticide"),
            Tab(text: "Sustainable Agri - Fertilizer"),
            Tab(text: "Sustainable Agri - Pesticides"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent("Seed Cost", "Add Seed Cost"),
          _buildTabContent("Chemical Fertilizers", "Add Chemical Fertilizer"),
          _buildTabContent("Chemical Pesticide", "Add Pesticide"),
          _buildTabContent("Sustainable Agri - Fertilizer", "Add SA Fertilizer"),
          _buildTabContent("Sustainable Agri - Pesticides", "Add SA Pesticide"),
        ],
      ),
    );
  }

  // --- Reusable tab content with DataTable + Add button ---
  Widget _buildTabContent(String title, String buttonText) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Total Cost + Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Total $title: 0.00",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _showAddForm(context, title),
                child: Text(buttonText),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DataTable with horizontal scroll
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("SN")),
                    DataColumn(label: Text("Farmer Name")),
                    DataColumn(label: Text("Input/Seed Name")),
                    DataColumn(label: Text("Quantity")),
                    DataColumn(label: Text("Unit Type")),
                    DataColumn(label: Text("Per Unit Cost")),
                    DataColumn(label: Text("Total Cost")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: const [], // later API se fill karenge
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Show Add Form (Dialog) ---
  void _showAddForm(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$title Form",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Form Fields
                  _buildDropdown("Seed/Input Name", []),
                  const SizedBox(height: 12),
                  _buildDropdown("Variety/Type", []),
                  const SizedBox(height: 12),
                  _buildTextField("Quantity Used"),
                  const SizedBox(height: 12),
                  _buildDropdown("Unit Type", []),
                  const SizedBox(height: 12),
                  _buildTextField("Per Unit Cost"),
                  const SizedBox(height: 12),
                  _buildTextField("Total Cost", enabled: false),
                  const SizedBox(height: 20),

                  // Save Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Reusable Widgets ---
  Widget _buildTextField(String label, {bool enabled = true}) {
    return TextField(
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (value) {},
    );
  }
}
