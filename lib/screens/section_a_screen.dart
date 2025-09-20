import 'package:flutter/material.dart';

class SectionAScreen extends StatefulWidget {
  const SectionAScreen({super.key});

  @override
  State<SectionAScreen> createState() => _SectionAScreenState();
}

class _SectionAScreenState extends State<SectionAScreen>
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
        elevation: 2,
        title: const Text(
          "Crop Audit",
          style: TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          tabs: const [
            Tab(text: "Section A"),
            Tab(text: "Section B"),
            Tab(text: "Labour usage (D)"),
            Tab(text: "M&E Costs (E)"),
            Tab(text: "Water usage"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSectionA(),
          _buildSectionB(),
          _buildLabourUsage(),
          _buildMECosts(),
          _buildWaterUsage(),
        ],
      ),
    );
  }

  // ---------------- Section A ----------------
  Widget _buildSectionA() {
    return _formContainer(
      children: [
        _buildTextField("Audit ID"),
        _buildDropdown("Season", []),
        _buildDropdown("Main Crop Name", []),
        _buildDateField("Sowing Date"),
        _buildDateField("Harvest Date"),
        _buildDropdown("Irrigation Method", []),
        _buildTextField("No. of Irrigations"),
        _buildTextField("Land Area"),
        _buildButtons(),
      ],
    );
  }

  // ---------------- Section B ----------------
  Widget _buildSectionB() {
    return _formContainer(
      children: [
        _buildDropdown("Yield Unit", []),
        _buildTextField("Total Yield"),
        _buildTextField("Total Yield in KG"),
        _buildDropdown("Usage Type", []),
        _buildTextField("Sold Quantity"),
        _buildTextField("Sale Price per unit"),
        _buildTextField("Price of the produce per KG"),
        _buildTextField("Farm Gate Price per unit"),
        _buildTextField("Price Gap per unit"),
        _buildTextField("Value of the produce sold"),
        _buildTextField("Quantity kept for household usage"),
        _buildTextField("Value kept for household usage"),
        _buildTextField("Total value of the produce (Rs)"),
        _buildButtons(),
      ],
    );
  }

  // ---------------- Labour Usage ----------------
  Widget _buildLabourUsage() {
    return _formContainer(
      children: [
        _buildTextField("Paid Labour Cost (Rs)"),
        _buildTextField("Male Family Labour Days"),
        _buildTextField("Female Family Labour Days"),
        _buildTextField("Male Wage Rate"),
        _buildTextField("Female Wage Rate"),
        _buildTextField("Valued Male Family Labour (Rs)"),
        _buildTextField("Valued Female Family Labour (Rs)"),
        _buildTextField("Valued Family Labour (Rs)"),
        _buildTextField("Total Labour Cost (Hired + family labour)"),
        _buildButtons(),
      ],
    );
  }

  // ---------------- M&E Costs ----------------
  Widget _buildMECosts() {
    return _formContainer(
      children: [
        _buildCheckbox("Power Tiller"),
        _buildCheckbox("Tractor"),
        _buildCheckbox("Harvesting machine"),
        _buildTextField("Machinery Rent Cost"),
        _buildTextField("Irrigation Cost"),
        _buildTextField("Other Cost"),
        _buildTextField("Total Cost"),
        _buildButtons(),
      ],
    );
  }

  // ---------------- Water Usage ----------------
  Widget _buildWaterUsage() {
    return _formContainer(
      children: [
        _buildDropdown("Crop Name", []),
        _buildDropdown("Irrigation Method", []),
        _buildTextField("Water Usage in mm"),
        _buildTextField("Water Usage in Litres"),
        _buildTextField("Land Size"),
        _buildTextField("Irrigation Efficiency (%)"),
        _buildButtons(),
      ],
    );
  }

  // ---------------- Reusable Widgets ----------------

  Widget _formContainer({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        children: children,
      ),
    );
  }

  Widget _buildTextField(String label) {
    return SizedBox(
      width: 300,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDateField(String label) {
    return SizedBox(
      width: 300,
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            // TODO: integrate with controller later
          }
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        items: options
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        onChanged: (value) {},
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          StatefulBuilder(
            builder: (context, setState) {
              bool isChecked = false;
              return Checkbox(
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    isChecked = value ?? false;
                  });
                },
              );
            },
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {},
          child: const Text("Update"),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {},
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
