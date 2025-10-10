import 'package:flutter/material.dart';
import 'package:vasudha/services/api_service.dart';


class CostsScreen extends StatefulWidget {
  final String farmerId; // 🔹 yeh add karo

  const CostsScreen({super.key, required this.farmerId});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
  
}

class _CostsScreenState extends State<CostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _fertilizerUsages = [];
bool _isLoadingFertilizers = true;

List<dynamic> _sustainableFertilizers = [];
bool _isLoadingSustainableFertilizers = true;

String _calculateTotalFertilizerCost() {
  double total = 0;
  for (var item in _fertilizerUsages) {
    total += double.tryParse(item["totlcost"]?.toString() ?? "0") ?? 0;
  }
  return total.toStringAsFixed(2);
}

List<dynamic> _sustainablePesticides = [];
bool _isLoadingSustainablePesticides = true;

String _calculateTotalSustainablePesticideCost() {
  double total = 0;
  for (var item in _sustainablePesticides) {
    total += double.tryParse(item["totalccosttt"]?.toString() ?? "0") ?? 0;
  }
  return total.toStringAsFixed(2);
}


String _calculateTotalSustainableFertilizerCost() {
  double total = 0;
  for (var item in _sustainableFertilizers) {
    total += double.tryParse(item["totalcostee"]?.toString() ?? "0") ?? 0;
  }
  return total.toStringAsFixed(2);
}



  List<dynamic> _chemicalUsages = [];
bool _isLoadingChemicals = true;

String _calculateTotalChemicalCost() {
  double total = 0;
  for (var item in _chemicalUsages) {
    total += double.tryParse(item["totlcost"]?.toString() ?? "0") ?? 0;
  }
  return total.toStringAsFixed(2);
}


  List<dynamic> _seedUsages = []; // API se aane wala data
  bool _isLoading = true; // loader ke liye

  // ✅ Masters mapping ke liye
Map<int, String> _crops = {};
Map<int, String> _varieties = {};
Map<int, String> _units = {};

  String _calculateTotalSeedCost() {
  double total = 0;
  for (var item in _seedUsages ?? []) {
    total += double.tryParse(item["total_cost"]?.toString() ?? "0") ?? 0;
  }
  return total.toStringAsFixed(2);
}





  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);
  _loadMasters();   // masters pehle load karenge
  _fetchChemicalUsages();
  _fetchFertilizerUsages();
  _fetchSeedUsages();
  _fetchSustainableFertilisers();
  _fetchSustainablePesticides();
}

String _mapValue(Map<int, String> master, dynamic id) {
  final parsedId = int.tryParse(id?.toString() ?? "");
  if (parsedId != null && master.containsKey(parsedId)) {
    return master[parsedId]!;
  }
  return id?.toString() ?? "-";
}


Future<void> _loadMasters() async {
  final crops = await ApiService.getCrops();
  final varieties = await ApiService.getSeedVarieties();
  final units = await ApiService.getUnitTypes();

  setState(() {
    _crops = crops;
    _varieties = varieties;
    _units = units;
  });
}

Future<void> _fetchSustainableFertilisers() async {
  final res = await ApiService.getSustainableFertilisersByFarmer(int.parse(widget.farmerId));
  print("📗 Sustainable Fertilizer API Response: $res");

  if (res["ok"] == true) {
    setState(() {
      _sustainableFertilizers = res["data"] ?? [];
      _isLoadingSustainableFertilizers = false;
    });
  } else {
    setState(() => _isLoadingSustainableFertilizers = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Error fetching sustainable fertilisers")),
    );
  }
}

Future<void> _fetchSustainablePesticides() async {
  setState(() {
    _isLoadingSustainablePesticides = true;
  });

  final res = await ApiService.getPesticidesByFarmer(widget.farmerId);
  print("🪴 Sustainable Pesticides API Response: $res");

  if (res["ok"] == true) {
    _sustainablePesticides = res["data"] ?? [];

    // 👇 Force UI to refresh with new data
    setState(() {
      _isLoadingSustainablePesticides = false;
    });
  } else {
    setState(() => _isLoadingSustainablePesticides = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Error fetching pesticides")),
    );
  }
}



void _showPesticideForm(BuildContext context, {Map<String, dynamic>? item}) async {
  final qtyController = TextEditingController(text: item?["qntyusd"]?.toString() ?? "");
  final perUnitController = TextEditingController(text: item?["pruntcst"]?.toString() ?? "");
  final totalCostController = TextEditingController(text: item?["totlcost"]?.toString() ?? "");

// 1️⃣ पहले maps fetch करो
Map<int, String> inputNames = await ApiService.getInputNames();
Map<int, String> inputTypes = await ApiService.getInputTypes();
Map<int, String> units = await ApiService.getUnitTypes();

// 2️⃣ अब ids निकालो
int? selectedInputNameId;
int? selectedInputTypeId;
int? selectedUnitId;

if (item != null) {
  selectedInputNameId = inputNames.entries
      .firstWhere((e) => e.value == item["inptname"], orElse: () => const MapEntry(-1, ""))
      .key;

  selectedInputTypeId = inputTypes.entries
      .firstWhere((e) => e.value == item["inptyp"], orElse: () => const MapEntry(-1, ""))
      .key;

  selectedUnitId = units.entries
      .firstWhere((e) => e.value == item["unttyp"], orElse: () => const MapEntry(-1, ""))
      .key;
}


  void _recalculateTotal() {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final perUnit = double.tryParse(perUnitController.text) ?? 0;
    double total = 0;

    if (selectedUnitId == 5) {
      total = qty * 20 * perUnit;
    } else {
      total = qty * perUnit;
    }

    totalCostController.text = total.toStringAsFixed(2);
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? "Add Chemical Pesticide" : "Edit Chemical Pesticide",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: selectedInputNameId,
                      decoration: _inputDecoration("Input Name"),
                      items: inputNames.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedInputNameId = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: selectedInputTypeId,
                      decoration: _inputDecoration("Input Type"),
                      items: inputTypes.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedInputTypeId = val),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Quantity Used"),
                      onChanged: (_) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      decoration: _inputDecoration("Unit Type"),
                      items: units.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedUnitId = val);
                        _recalculateTotal();
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: perUnitController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Per Unit Cost"),
                      onChanged: (_) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: totalCostController,
                      enabled: false,
                      decoration: _inputDecoration("Total Cost"),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          if (selectedInputNameId == null || selectedUnitId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select Input Name & Unit Type")),
                            );
                            return;
                          }

                          if (item == null) {
                            // ✅ Add new pesticide
                            final res = await ApiService.storeChemicalUsage(
                              farmerId: int.parse(widget.farmerId),
                              inputName: selectedInputNameId!,
                              inputType: selectedInputTypeId ?? 0,
                              quantityUsed: double.tryParse(qtyController.text),
                              unitType: selectedUnitId!,
                              perUnitCost: double.tryParse(perUnitController.text),
                              totalCost: double.tryParse(totalCostController.text),
                            );

                            if (res["ok"] == true) {
                              Navigator.pop(context);
                              _fetchChemicalUsages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res["message"] ?? "Failed to save")),
                              );
                            }
                          } else {
                            // ✅ Update existing pesticide
                            final res = await ApiService.updateChemicalUsage(
  id: item["id"],
  updates: {
    "inptname": selectedInputNameId,
    "inptyp": selectedInputTypeId,
    "qntyusd": qtyController.text,
    "unttyp": selectedUnitId,
    "pruntcst": perUnitController.text,
    "totlcost": totalCostController.text,
  },
);


                            if (res["ok"] == true) {
                              Navigator.pop(context);
                              _fetchChemicalUsages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res["message"] ?? "Failed to update")),
                              );
                            }
                          }
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
    },
  );
}



void _showFertilizerForm(BuildContext context, {Map<String, dynamic>? item}) async {
  // Controllers for text fields
  final qtyController = TextEditingController(text: item?["quantity_used"]?.toString() ?? "");
  final perUnitController = TextEditingController(text: item?["per_unit_cost"]?.toString() ?? "");
  final totalCostController = TextEditingController(text: item?["total_cost"]?.toString() ?? "");

  // Selected IDs
  int? selectedInputNameId = item?["input_name"]?["id"];
int? selectedInputTypeId = item?["input_type"]?["id"];
int? selectedUnitId      = item?["unit"]?["id"];

  // Dropdown Data
  Map<int, String> inputNames = {};
  Map<int, String> inputTypes = {};
  Map<int, String> units = {};

  // 🔹 Fetch dropdown data dynamically
  inputNames = await ApiService.getInputNames();
  inputTypes = await ApiService.getInputTypes();
  units = await ApiService.getUnitTypes(); // 👈 same as Seed Cost

  // Auto-calc function (Seed Cost jaisa)
  void _recalculateTotal() {
  final qty = double.tryParse(qtyController.text) ?? 0;
  final perUnit = double.tryParse(perUnitController.text) ?? 0;
  double total = 0;

  if (selectedUnitId == 5) { 
    // 👈 Same logic as Seed Cost (5 = Mund)
    total = qty * 20 * perUnit;
  } else {
    total = qty * perUnit;
  }

  totalCostController.text = total.toStringAsFixed(2);
}


  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? "Add Fertilizer Cost" : "Edit Fertilizer Cost",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Input Name Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedInputNameId,
                      decoration: _inputDecoration("Input Name"),
                      items: inputNames.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedInputNameId = val),
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Input Type Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedInputTypeId,
                      decoration: _inputDecoration("Input Type"),
                      items: inputTypes.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedInputTypeId = val),
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Quantity Used
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Quantity Used"),
                      onChanged: (_) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Unit Type Dropdown (Seed Cost wala)
                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      decoration: _inputDecoration("Unit Type"),
                      items: units.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedUnitId = val);
                        _recalculateTotal();
                      },
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Per Unit Cost
                    TextField(
                      controller: perUnitController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Per Unit Cost"),
                      onChanged: (_) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    // 🔹 Total Cost (readonly)
                    TextField(
                      controller: totalCostController,
                      enabled: false,
                      decoration: _inputDecoration("Total Cost"),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
  if (selectedInputNameId == null || selectedUnitId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select Input Name & Unit Type")),
    );
    return;
  }

  if (item == null) {
    // ✅ Add Fertilizer
    final res = await ApiService.storeFertilizerUsage(
      farmerId: int.parse(widget.farmerId),
      inputName: selectedInputNameId ?? 0,
      inputType: selectedInputTypeId ?? 0,
      quantityUsed: double.tryParse(qtyController.text),
      unitType: selectedUnitId ?? 0,
      perUnitCost: double.tryParse(perUnitController.text),
      totalCost: double.tryParse(totalCostController.text),
    );

    if (res["ok"] == true) {
      Navigator.pop(context);
      _fetchFertilizerUsages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Failed to save")),
      );
    }
  } else {
    // ✅ Update Fertilizer
    final res = await ApiService.updateFertilizerUsage(
      id: item["id"],
      updates: {
        "input_name": selectedInputNameId,
        "input_type": selectedInputTypeId,
        "quantity_used": qtyController.text,
        "unit_type": selectedUnitId,
        "per_unit_cost": perUnitController.text,
        "total_cost": totalCostController.text,
      },
    );

    if (res["ok"] == true) {
      Navigator.pop(context);
      _fetchFertilizerUsages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Failed to update")),
      );
    }
  }
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
    },
  );
}



Future<void> _fetchChemicalUsages() async {
  final res = await ApiService.getChemicalUsagesByFarmer(widget.farmerId);
  print("📌 Chemical API Response: $res");

  if (res["ok"] == true) {
    setState(() {
      _chemicalUsages = res["data"] ?? [];
      _isLoadingChemicals = false;
    });
  } else {
    setState(() => _isLoadingChemicals = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Error fetching chemical usages")),
    );
  }
}

Future<void> _fetchFertilizerUsages() async {
  final res = await ApiService.getFertilizerUsagesByFarmer(widget.farmerId);
  print("📌 Fertilizer API Response: $res");

  if (res["ok"] == true) {
    setState(() {
      _fertilizerUsages = res["data"] ?? [];
      _isLoadingFertilizers = false;
    });
  } else {
    setState(() => _isLoadingFertilizers = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Error fetching fertilizer usages")),
    );
  }
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
          _buildSeedCostTab(),
          _buildChemicalFertilizersTab(),
          _buildChemicalPesticideTab(),
          _buildSustainableFertilizerTab(),
          _buildSustainablePesticideTab(),
        ],
      ),
    );
  }

Widget _buildSustainableFertilizerTab() {
  if (_isLoadingSustainableFertilizers) {
    return const Center(child: CircularProgressIndicator());
  }

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Total + Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Total Cost Sustainable Agriculture - Fertilisers: ${_calculateTotalSustainableFertilizerCost()}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                _showSustainableForm(context);
              },
              child: const Text("Add Sustainable Fertilizer"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table Container
        Expanded(
          child: _sustainableFertilizers.isEmpty
              ? const Center(child: Text("No sustainable fertiliser data found"))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text("SN")),
                          DataColumn(label: Text("Farmer Name")), // 👈 Added
                          DataColumn(label: Text("Input Name")),
                          DataColumn(label: Text("Input Type")),
                          DataColumn(label: Text("Quantity Used")),
                          DataColumn(label: Text("Unit Type")),
                          DataColumn(label: Text("Per Unit Cost")),
                          DataColumn(label: Text("Total Cost")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: List.generate(_sustainableFertilizers.length, (index) {
                          final item = _sustainableFertilizers[index];
                          return DataRow(cells: [
                            DataCell(Text("${index + 1}")),
                            DataCell(Text(item["farmer_name"]?.toString() ?? "-")),
 // 👈 Added
                            DataCell(Text(item["inputnamee"]?.toString() ?? "-")),
                            DataCell(Text(item["inputtypee"]?.toString() ?? "-")),
                            DataCell(Text(item["quantityuseed"]?.toString() ?? "-")),
                            DataCell(Text(item["unittypee"]?.toString() ?? "-")),
                            DataCell(Text(item["perunitcoste"]?.toString() ?? "-")),
                            DataCell(Text(item["totalcostee"]?.toString() ?? "-")),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    print("Editing Sustainable: $item");
                                    _showSustainableForm(context, item: item);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text("Are you sure you want to delete this fertiliser entry?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final res = await ApiService.deleteSustainableFertiliser(item["id"]);
                                      if (res["ok"]) {
                                        await _fetchSustainableFertilisers(); // refresh
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(res["message"] ?? "Deleted successfully")),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(res["message"] ?? "Delete failed")),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}


Widget _buildSustainablePesticideTab() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Top Row: Total Cost + Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Total Sustainable Agri - Pesticides: ${_calculateTotalSustainablePesticideCost()}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                _showSustainablePesticideForm(context);
              },
              child: const Text("Add SA Pesticide"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 Table Container
        Expanded(
          child: _sustainablePesticides.isEmpty
              ? const Center(child: Text("No sustainable pesticide data found"))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text("SN")),
                          DataColumn(label: Text("Farmer Name")),
                          DataColumn(label: Text("Input/Seed Name")),
                          DataColumn(label: Text("Type")),            // <<< ADDED
                          DataColumn(label: Text("Quantity")),
                          DataColumn(label: Text("Unit Type")),
                          DataColumn(label: Text("Per Unit Cost")),
                          DataColumn(label: Text("Total Cost")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: List.generate(_sustainablePesticides.length, (index) {
                          final item = _sustainablePesticides[index];
                          return DataRow(cells: [
                            DataCell(Text("${index + 1}")),
                            DataCell(Text(item["farmer_name"]?.toString() ?? "-")),
                            DataCell(Text(item["inputttt"]?.toString() ?? "-")),
                            DataCell(Text(item["inpuuttype"]?.toString() ?? "-")), // <<< ADDED
                            DataCell(Text(item["quantiiityused"]?.toString() ?? "-")),
                            DataCell(Text(item["unittyppp"]?.toString() ?? "-")),
                            DataCell(Text(item["prunitcoost"]?.toString() ?? "-")),
                            DataCell(Text(item["totalccosttt"]?.toString() ?? "-")),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    print("Editing pesticide: $item");
                                    _showSustainablePesticideForm(context, item: item);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text("Are you sure you want to delete this record?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final res = await ApiService.deletePesticide(item["id"]);
                                      if (res["ok"] == true) {
                                        await _fetchSustainablePesticides(); // refresh table
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(res["message"] ?? "Deleted successfully ✅")),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(res["message"] ?? "Delete failed")),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}

void _showSustainablePesticideForm(BuildContext context, {Map<String, dynamic>? item}) async {
  // 1️⃣ Controllers
  final qtyController = TextEditingController(text: item?["quantiiityused"]?.toString() ?? "");
  final perUnitController = TextEditingController(text: item?["prunitcoost"]?.toString() ?? "");
  final totalCostController = TextEditingController(text: item?["totalccosttt"]?.toString() ?? "");

  // 2️⃣ Dropdown data
  Map<int, String> inputNames = await ApiService.getInputNames();
  Map<int, String> inputTypes = await ApiService.getInputTypes();
  Map<int, String> units = await ApiService.getUnitTypes();

  int? selectedInputNameId;
  int? selectedInputTypeId;
  int? selectedUnitId;

  if (item != null) {
    selectedInputNameId = inputNames.entries
        .firstWhere((e) => e.value == item["inputttt"], orElse: () => const MapEntry(-1, ""))
        .key;
    selectedInputTypeId = inputTypes.entries
        .firstWhere((e) => e.value == item["inpuuttype"], orElse: () => const MapEntry(-1, ""))
        .key;
    selectedUnitId = units.entries
        .firstWhere((e) => e.value == item["unittyppp"], orElse: () => const MapEntry(-1, ""))
        .key;
  }

  void _recalculateTotal() {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final perUnit = double.tryParse(perUnitController.text) ?? 0;
    double total = (selectedUnitId == 5) ? qty * 20 * perUnit : qty * perUnit;
    totalCostController.text = total.toStringAsFixed(2);
  }

  // 3️⃣ Dialog
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item == null
                            ? "Add Sustainable Pesticide"
                            : "Edit Sustainable Pesticide",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fields
                  DropdownButtonFormField<int>(
                    value: selectedInputNameId != -1 ? selectedInputNameId : null,
                    decoration: _inputDecoration("Input Name"),
                    items: inputNames.entries
                        .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedInputNameId = val),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: selectedInputTypeId != -1 ? selectedInputTypeId : null,
                    decoration: _inputDecoration("Input Type"),
                    items: inputTypes.entries
                        .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedInputTypeId = val),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("Quantity Used"),
                    onChanged: (_) => _recalculateTotal(),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: selectedUnitId != -1 ? selectedUnitId : null,
                    decoration: _inputDecoration("Unit Type"),
                    items: units.entries
                        .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedUnitId = val);
                      _recalculateTotal();
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: perUnitController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("Per Unit Cost"),
                    onChanged: (_) => _recalculateTotal(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: totalCostController,
                    enabled: false,
                    decoration: _inputDecoration("Total Cost"),
                  ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () async {
                        final inputId = selectedInputNameId;
                        final inputType = selectedInputTypeId;
                        final unitType = selectedUnitId;
                        final quantityUsed = double.tryParse(qtyController.text) ?? 0;
                        final perUnitCost = double.tryParse(perUnitController.text) ?? 0;
                        final totalCost = double.tryParse(totalCostController.text) ?? 0;

                        if (inputId == null || inputType == null || unitType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields.")),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please wait...")),
                        );

                        Map<String, dynamic> res;
                        if (item == null) {
                          // 🟢 CREATE
                          res = await ApiService.storePesticide(
                            farmerId: int.parse(widget.farmerId),
                            inputId: inputId,
                            inputType: inputType,
                            quantityUsed: quantityUsed,
                            unitType: unitType,
                            perUnitCost: perUnitCost,
                            totalCost: totalCost,
                          );
                        } else {
                          // ✏️ UPDATE
                          res = await ApiService.updatePesticide(
                            id: item["id"],
                            updates: {
                              "inputttt": inputId,
                              "inpuuttype": inputType,
                              "quantiiityused": quantityUsed,
                              "unittyppp": unitType,
                              "prunitcoost": perUnitCost,
                              "totalccosttt": totalCost,
                            },
                          );
                        }

                        if (res["ok"] == true) {
                          await _fetchSustainablePesticides(); // 🔁 Refresh table
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(item == null
                                  ? "Added successfully ✅"
                                  : "Updated successfully ✅"),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res["message"] ?? "Something went wrong"),
                            ),
                          );
                        }
                      },
                      child: Text(item == null ? "Save" : "Update"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
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
                onPressed: () => _showForm(context),
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

  Widget _buildChemicalFertilizersTab() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total + Add Button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Total Chemical Fertilizers: ${_calculateTotalFertilizerCost()}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
    _showFertilizerForm(context); // 👈 yaha call karna hai
  },
              child: const Text("Add Chemical Fertilizer"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: _isLoadingFertilizers
              ? const Center(child: CircularProgressIndicator())
              : Container(
  width: double.infinity,
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
    borderRadius: BorderRadius.circular(8),
  ),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text("SN")),
          DataColumn(label: Text("Farmer Name")),
          DataColumn(label: Text("Input Name")),
          DataColumn(label: Text("Input Type")),
          DataColumn(label: Text("Quantity Used")),
          DataColumn(label: Text("Unit Type")),
          DataColumn(label: Text("Per Unit Cost")),
          DataColumn(label: Text("Total Cost")),
          DataColumn(label: Text("Action")),
        ],
        rows: List.generate(_fertilizerUsages.length, (index) {
          final item = _fertilizerUsages[index];
          return DataRow(cells: [
            DataCell(Text("${index + 1}")),
            DataCell(Text(item["farmer"]?["name"] ?? "-")),
            DataCell(Text(item["input_name"]?["input_name"] ?? "-")),
            DataCell(Text(item["input_type"]?["input_types"] ?? "-")),
            DataCell(Text(item["quantity_used"]?.toString() ?? "0")),
            DataCell(Text(item["unit"]?["unit_type"] ?? "-")),
            DataCell(Text(item["per_unit_cost"]?.toString() ?? "0")),
            DataCell(Text(item["total_cost"]?.toString() ?? "0")),
            DataCell(Row(
              children: [
                IconButton(
  icon: const Icon(Icons.edit, color: Colors.orange),
  onPressed: () {
    print("Editing Fertilizer: $item");
    _showFertilizerForm(context, item: item); 
  },
),

                IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteFertilizerUsage(item["id"]);
      if (res["ok"] == true) {
        _fetchFertilizerUsages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Delete failed")),
        );
      }
    }
  },
),

              ],
            )),
          ]);
        }),
      ),
    ),
  ),
),

        ),
      ],
    ),
  );
}


  Widget _buildChemicalPesticideTab() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Total + Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Total Chemical Pesticide: ${_calculateTotalChemicalCost()}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  onPressed: () {
    _showPesticideForm(context); // 👈 call this instead
  },
  child: const Text("Add Chemical Pesticide"),
),

          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: _isLoadingChemicals
              ? const Center(child: CircularProgressIndicator())
              : Container(
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
                        DataColumn(label: Text("Input Name")),
                        DataColumn(label: Text("Input Type")),
                        DataColumn(label: Text("Quantity Used")),
                        DataColumn(label: Text("Unit Type")),
                        DataColumn(label: Text("Per Unit Cost")),
                        DataColumn(label: Text("Total Cost")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: List.generate(_chemicalUsages.length, (index) {
                        final item = _chemicalUsages[index];
                        return DataRow(cells: [
                          DataCell(Text("${index + 1}")),
                          DataCell(Text(item["farmer_name"] ?? "-")),
                          DataCell(Text(item["inptname"] ?? "-")),
                          DataCell(Text(item["inptyp"] ?? "-")),
                          DataCell(Text(item["qntyusd"].toString())),
                          DataCell(Text(item["unttyp"] ?? "-")),
                          DataCell(Text(item["pruntcst"].toString())),
                          DataCell(Text(item["totlcost"]?.toString() ?? "0")),
                          DataCell(Row(
                            children: [
                              IconButton(
  icon: const Icon(Icons.edit, color: Colors.orange),
  onPressed: () {
    _showPesticideForm(context, item: item); // ✅ item pass करो यहाँ
  },
),
                              IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this pesticide entry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteChemicalUsage(item["id"]);
      if (res["ok"] == true) {
        _fetchChemicalUsages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Delete failed")),
        );
      }
    }
  },
),

                            ],
                          )),
                        ]);
                      }),
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}




// --- Show Add / Edit Form (Dialog) with Dropdowns ---
// --- Show Add / Edit Form (Dialog) with Dropdowns ---
void _showForm(BuildContext context, {Map<String, dynamic>? item}) async {
  Map<int, String> crops = {};
  Map<int, String> varieties = {};
  Map<int, String> units = {};

int? selectedCropId = int.tryParse(item?["seed_name"]?.toString() ?? "");
int? selectedVarietyId = int.tryParse(item?["seed_variety"]?.toString() ?? "");
int? selectedUnitId = int.tryParse(item?["unit_type"]?.toString() ?? "");


  final TextEditingController qtyController =
      TextEditingController(text: item?["quantity_used"]?.toString() ?? "");
  final TextEditingController perUnitController =
      TextEditingController(text: item?["per_unit_cost"]?.toString() ?? "");
  final TextEditingController totalCostController =
      TextEditingController(text: item?["total_cost"]?.toString() ?? "");

  // 🔹 Fetch dropdown data
  crops = await ApiService.getCrops();
  varieties = await ApiService.getSeedVarieties();
  units = await ApiService.getUnitTypes();

  void _recalculateTotal() {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final perUnit = double.tryParse(perUnitController.text) ?? 0;
    double total = 0;
    if (selectedUnitId == 5) {
      total = qty * 20 * perUnit;
    } else {
      total = qty * perUnit;
    }
    totalCostController.text = total.toStringAsFixed(2);
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? "Add Seed Cost" : "Edit Seed Cost",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dropdowns + Inputs
                    DropdownButtonFormField<int>(
                      value: selectedCropId,
                      decoration: _inputDecoration("Seed Name"),
                      items: crops.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedCropId = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: selectedVarietyId,
                      decoration: _inputDecoration("Seed Variety"),
                      items: varieties.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedVarietyId = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      decoration: _inputDecoration("Unit Type"),
                      items: units.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedUnitId = val);
                        _recalculateTotal();
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Quantity Used"),
                      onChanged: (val) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: perUnitController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Per Unit Cost"),
                      onChanged: (val) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: totalCostController,
                      enabled: false,
                      decoration: _inputDecoration("Total Cost"),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          if (selectedCropId == null || selectedUnitId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all required fields")),
                            );
                            return;
                          }

                          if (item == null) {
                            // 🔹 Add New
                            final res = await ApiService.storeSeedUsage(
                              farmerId: int.parse(widget.farmerId),
                              seedName: selectedCropId ?? 0,
                              seedVariety: selectedVarietyId,
                              quantityUsed: double.tryParse(qtyController.text),
                              unitType: selectedUnitId ?? 0,
                              perUnitCost: double.tryParse(perUnitController.text),
                            );

                            if (res["ok"] == true) {
                              Navigator.pop(context);
                              _fetchSeedUsages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res["message"] ?? "Failed to save")),
                              );
                            }
                          } else {
                            // 🔹 Update Existing
                            final res = await ApiService.updateSeedUsage(
  id: item["id"],
  updates: {
    "seed_name": selectedCropId,
    "seed_variety": selectedVarietyId,
    "quantity_used": qtyController.text,
    "unit_type": selectedUnitId,
    "per_unit_cost": perUnitController.text,
  },
);


                            if (res["ok"] == true) {
                              Navigator.pop(context);
                              _fetchSeedUsages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res["message"] ?? "Failed to update")),
                              );
                            }
                          }
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
    },
  );
}

void _showSustainableForm(BuildContext context, {Map<String, dynamic>? item}) async {
  final qtyController = TextEditingController(text: item?["quantityuseed"]?.toString() ?? "");
  final perUnitController = TextEditingController(text: item?["perunitcoste"]?.toString() ?? "");
  final totalCostController = TextEditingController(text: item?["totalcostee"]?.toString() ?? "");

  // 🔽 Fetch dropdown data
  Map<int, String> inputNames = await ApiService.getInputNames();
  Map<int, String> inputTypes = await ApiService.getInputTypes();
  Map<int, String> units = await ApiService.getUnitTypes();

  int? selectedInputNameId;
  int? selectedInputTypeId;
  int? selectedUnitId;

  if (item != null) {
    final nameEntry = inputNames.entries
        .firstWhere((e) => e.value == item["inputnamee"], orElse: () => const MapEntry(0, ""));
    selectedInputNameId = nameEntry.key == 0 ? null : nameEntry.key;

    final typeEntry = inputTypes.entries
        .firstWhere((e) => e.value == item["inputtypee"], orElse: () => const MapEntry(0, ""));
    selectedInputTypeId = typeEntry.key == 0 ? null : typeEntry.key;

    final unitEntry = units.entries
        .firstWhere((e) => e.value == item["unittypee"], orElse: () => const MapEntry(0, ""));
    selectedUnitId = unitEntry.key == 0 ? null : unitEntry.key;
  }

  void _recalculateTotal() {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final perUnit = double.tryParse(perUnitController.text) ?? 0;
    double total = 0;

    if (selectedUnitId == 5) {
      total = qty * 20 * perUnit;
    } else {
      total = qty * perUnit;
    }

    totalCostController.text = total.toStringAsFixed(2);
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == null ? "Add Sustainable Fertiliser" : "Edit Sustainable Fertiliser",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Input Name
                    DropdownButtonFormField<int>(
                      value: selectedInputNameId,
                      decoration: _inputDecoration("Input Name"),
                      items: inputNames.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedInputNameId = val),
                    ),
                    const SizedBox(height: 12),

                    // Input Type
                    DropdownButtonFormField<int>(
                      value: selectedInputTypeId,
                      decoration: _inputDecoration("Input Type"),
                      items: inputTypes.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedInputTypeId = val),
                    ),
                    const SizedBox(height: 12),

                    // Quantity
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Quantity Used"),
                      onChanged: (_) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    // Unit
                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      decoration: _inputDecoration("Unit Type"),
                      items: units.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedUnitId = val);
                        _recalculateTotal();
                      },
                    ),
                    const SizedBox(height: 12),

                    // Per Unit Cost
                    TextField(
                      controller: perUnitController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Per Unit Cost"),
                      onChanged: (_) => _recalculateTotal(),
                    ),
                    const SizedBox(height: 12),

                    // Total Cost
                    TextField(
                      controller: totalCostController,
                      enabled: false,
                      decoration: _inputDecoration("Total Cost"),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          if (selectedInputNameId == null || selectedUnitId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select Input Name & Unit Type")),
                            );
                            return;
                          }

                          final farmerId = 23; // TODO: replace with actual farmerId from state
                          if (item == null) {
                            // ✅ Add new via API
                            final res = await ApiService.storeSustainableFertiliser(
                              farmerId: farmerId,
                              inputNameId: selectedInputNameId!,
                              inputTypeId: selectedInputTypeId ?? 0,
                              quantityUsed: double.tryParse(qtyController.text),
                              unitTypeId: selectedUnitId!,
                              perUnitCost: double.tryParse(perUnitController.text),
                              totalCost: double.tryParse(totalCostController.text),
                            );
                            if (res["ok"]) {
                              setState(() {
                                _sustainableFertilizers.add(res["data"]);
                              });
                              Navigator.pop(context);
                              await _fetchSustainableFertilisers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fertiliser added successfully")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res["message"] ?? "Add failed")),
                              );
                            }
                          } else {
                            // ✅ Update existing via API
                            final res = await ApiService.updateSustainableFertiliser(
                              id: item["id"],
                              updates: {
                                "inputnamee": selectedInputNameId,
                                "inputtypee": selectedInputTypeId,
                                "quantityuseed": double.tryParse(qtyController.text),
                                "unittypee": selectedUnitId,
                                "perunitcoste": double.tryParse(perUnitController.text),
                                "totalcostee": double.tryParse(totalCostController.text),
                              },
                            );
                            if (res["ok"]) {
                              setState(() {
                                final idx = _sustainableFertilizers.indexWhere((f) => f["id"] == item["id"]);
                                if (idx != -1) {
                                  _sustainableFertilizers[idx] = res["data"];
                                }
                              });
                              Navigator.pop(context);
                              await _fetchSustainableFertilisers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fertiliser updated successfully")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res["message"] ?? "Update failed")),
                              );
                            }
                          }
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
    },
  );
}


InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}


Future<void> _fetchSeedUsages() async {
  final res = await ApiService.getSeedUsagesByFarmer(widget.farmerId);
  print("📌 Full API Response: $res"); // Debugging

  if (res["ok"] == true && res["data"]?["status"] == "success") {
    setState(() {
      final data = res["data"]?["data"];
      if (data is List) {
        _seedUsages = data;
      } else {
        _seedUsages = [];
      }
      _isLoading = false;
    });
  } else {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Error fetching data")),
    );
  }
}




Widget _buildSeedCostTab() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Total + Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Total Seed Cost: ${_calculateTotalSeedCost()}",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => _showForm(context),

              child: const Text("Add Seed Cost"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DataTable
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
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
                        DataColumn(label: Text("Seed Name")),
                        DataColumn(label: Text("Variety")),
                        DataColumn(label: Text("Quantity")),
                        DataColumn(label: Text("Unit Type")),
                        DataColumn(label: Text("Per Unit Cost")),
                        DataColumn(label: Text("Total Cost")),
                        DataColumn(label: Text("Action")), // 👈 yeh add kiya
                      ],
                      rows: List.generate(_seedUsages.length, (index) {
                        final item = _seedUsages[index];
                        return DataRow(cells: [
                          DataCell(Text("${index + 1}")),
                          DataCell(Text(item["farmer"]?["name"]?.toString() ?? "-")),
                          DataCell(Text(_mapValue(_crops, item["seed_name"]))),
DataCell(Text(_mapValue(_varieties, item["seed_variety"]))),
DataCell(Text(item["quantity_used"].toString())),
DataCell(Text(_mapValue(_units, item["unit_type"]))),

                          DataCell(Text(item["per_unit_cost"].toString())),
                          DataCell(Text(item["total_cost"].toString())),
                          DataCell(Row(
                            children: [
                              IconButton(
      icon: const Icon(Icons.edit, color: Colors.orange),
      onPressed: () {
        print("Editing item: $item");
        _showForm(context, item: item); // edit form khulega with old data
      },
    ),
                              IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteSeedUsage(item["id"]);
      if (res["ok"] == true) {
        _fetchSeedUsages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Delete failed")),
        );
      }
    }
  },
),

                            ],
                          )),
                        ]);
                      }),
                    ),
                  ),
                ),
        ),
      ],
    ),
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