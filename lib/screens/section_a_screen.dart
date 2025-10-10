// lib/screens/section_a_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../services/master_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../screens/machinery_section.dart';


class SectionAScreen extends StatefulWidget {
  final String farmerId;

  const SectionAScreen({super.key, required this.farmerId});

  @override
  State<SectionAScreen> createState() => _SectionAScreenState();
}

class _SectionAScreenState extends State<SectionAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ---------------- Controllers ----------------
  final auditIdCtrl = TextEditingController();
  final sowingDateCtrl = TextEditingController();
  final harvestDateCtrl = TextEditingController();
  final irrigationsCtrl = TextEditingController();
  final landAreaCtrl = TextEditingController();

  final totalYieldCtrl = TextEditingController();
  final totalYieldKgCtrl = TextEditingController();
  final soldQtyCtrl = TextEditingController();
  final salePriceCtrl = TextEditingController();
  final pricePerKgCtrl = TextEditingController();
  final farmGatePriceCtrl = TextEditingController();
  final priceGapCtrl = TextEditingController();
  final valueSoldCtrl = TextEditingController();
  final qtyHouseholdCtrl = TextEditingController();
  final valueHouseholdCtrl = TextEditingController();
  final totalValueCtrl = TextEditingController();

  final paidLabourCtrl = TextEditingController();
  final maleFamilyDaysCtrl = TextEditingController();
  final femaleFamilyDaysCtrl = TextEditingController();
  final maleWageCtrl = TextEditingController();
  final femaleWageCtrl = TextEditingController();
  final valuedMaleCtrl = TextEditingController();
  final valuedFemaleCtrl = TextEditingController();
  final valuedFamilyCtrl = TextEditingController();
  final totalLabourCtrl = TextEditingController();

 Set<int> _selectedMachineryIds = {};

  final machineryRentCtrl = TextEditingController();
  final irrigationCostCtrl = TextEditingController();
  final otherCostCtrl = TextEditingController();
  final totalCostCtrl = TextEditingController();

  final waterUsageMmCtrl = TextEditingController();
  final waterUsageLitresCtrl = TextEditingController();
  final irrigationEfficiencyCtrl = TextEditingController();

  // ---------------- Dropdown Values ----------------
  int? selectedSeason;
  int? selectedCrop;
  int? selectedIrrigationMethod;
  int? selectedYieldUnit;
  int? selectedUsageType;

  double yieldUnitToKgFactor = 1; // TODO: master data se link karna baad me


@override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);
  _fetchFarmerData();

  // --- Section B ke liye listeners ---
  totalYieldCtrl.addListener(_calculateAllTotals);
  soldQtyCtrl.addListener(_calculateAllTotals);
  salePriceCtrl.addListener(_calculateAllTotals);
  farmGatePriceCtrl.addListener(_calculateAllTotals);
  qtyHouseholdCtrl.addListener(_calculateAllTotals);

  // --- Section D (Labour Usage) ke liye listeners ---
  paidLabourCtrl.addListener(_calculateAllTotals);
  maleFamilyDaysCtrl.addListener(_calculateAllTotals);
  femaleFamilyDaysCtrl.addListener(_calculateAllTotals);
  maleWageCtrl.addListener(_calculateAllTotals);
  femaleWageCtrl.addListener(_calculateAllTotals);
    // --- Section E (M&E Costs) ke liye listeners ---
  machineryRentCtrl.addListener(_calculateAllTotals);
  irrigationCostCtrl.addListener(_calculateAllTotals);
  otherCostCtrl.addListener(_calculateAllTotals);

}
Map<String, dynamic> _cropData = {}; // ✅ backend se crop info store hoga





// ================= Helper Parsers =================
double _toDouble(String? text) => double.tryParse(text ?? "") ?? 0;

// ================= Section B Calculations =================
void _calculateSectionB() {
  double yield = _toDouble(totalYieldCtrl.text);
  double soldQty = _toDouble(soldQtyCtrl.text);
  double salePrice = _toDouble(salePriceCtrl.text);
  double farmGatePrice = _toDouble(farmGatePriceCtrl.text);
  int? usageType = selectedUsageType;

  // 👉 Yield conversion
  double yieldKg = yield * yieldUnitToKgFactor;
  totalYieldKgCtrl.text = yieldKg.toStringAsFixed(2);

  // 👉 Price per KG
  double pricePerKg =
      (salePrice > 0 && yieldUnitToKgFactor > 0) ? salePrice / yieldUnitToKgFactor : 0;
  pricePerKgCtrl.text = pricePerKg.toStringAsFixed(2);

  // 👉 Price gap
  double priceGap = salePrice - farmGatePrice;
  priceGapCtrl.text = priceGap.toStringAsFixed(2);

  // 👉 Household / Sold Logic
  if (usageType == 3) {
    soldQty = 0;
    salePrice = 0;
  }

  double valueSold = soldQty * salePrice;
  valueSoldCtrl.text = valueSold.toStringAsFixed(2);

  double householdQty = yield - soldQty;
  qtyHouseholdCtrl.text = householdQty.toStringAsFixed(2);

  // ✅ सही formula household value के लिए
  double householdValue;
  if (usageType == 3) {
    householdValue = farmGatePrice * yield; // सब कुछ household
  } else {
    householdValue = householdQty * salePrice; // बची हुई qty salePrice से
  }
  valueHouseholdCtrl.text = householdValue.toStringAsFixed(2);

  double totalValue = valueSold + householdValue;
  totalValueCtrl.text = totalValue.toStringAsFixed(2);
}


// ================= Labour Calculations =================
void _calculateLabour() {
  double paidLabour = _toDouble(paidLabourCtrl.text);
  double maleDays = _toDouble(maleFamilyDaysCtrl.text);
  double femaleDays = _toDouble(femaleFamilyDaysCtrl.text);
  double maleWage = _toDouble(maleWageCtrl.text);
  double femaleWage = _toDouble(femaleWageCtrl.text);

  double valuedMale = maleDays * maleWage;
  double valuedFemale = femaleDays * femaleWage;
  double totalFamilyLabour = valuedMale + valuedFemale;
  double totalLabourCost = paidLabour + totalFamilyLabour;

  valuedMaleCtrl.text = valuedMale.toStringAsFixed(2);
  valuedFemaleCtrl.text = valuedFemale.toStringAsFixed(2);
  valuedFamilyCtrl.text = totalFamilyLabour.toStringAsFixed(2);
  totalLabourCtrl.text = totalLabourCost.toStringAsFixed(2);
}

// ================= Water Usage Calculations =================
void _calculateWaterUsage() {
  // ✅ Backend से आया हुआ litres ही दिखाना है
  if (_cropData.isNotEmpty) {
    String litres = waterUsageLitresCtrl.text;

    setState(() {
      waterUsageLitresCtrl.text = litres;
    });
  }

  // ✅ Efficiency भी सिर्फ़ backend से आएगी
  // यहाँ दुबारा calculate करने की ज़रूरत नहीं है
}



// ================= M&E Cost Calculations =================
void _calculateMECosts() {
  double machineryCost = _toDouble(machineryRentCtrl.text);
  double irrigationCost = _toDouble(irrigationCostCtrl.text);
  double otherCost = _toDouble(otherCostCtrl.text);

  double mtotalCost = machineryCost + irrigationCost + otherCost;
  totalCostCtrl.text = mtotalCost.toStringAsFixed(2);
}

// ================= Final Totals & Per Acre =================
void _calculateFinal() {
  double landArea = _toDouble(landAreaCtrl.text);
  double yieldKg = _toDouble(totalYieldKgCtrl.text);
  double totalValue = _toDouble(totalValueCtrl.text);
  double totalLabourCost = _toDouble(totalLabourCtrl.text);
  double mtotalCost = _toDouble(totalCostCtrl.text);

  double totalInputCost = totalLabourCost + mtotalCost;
  double netIncomePlot = totalValue - totalInputCost;

  double productionPerAcre = (landArea > 0) ? yieldKg / landArea : 0;
  double valuePerAcre = (landArea > 0) ? totalValue / landArea : 0;
  double labourCostPerAcre = (landArea > 0) ? totalLabourCost / landArea : 0;
  double inputCostPerAcre = (landArea > 0) ? totalInputCost / landArea : 0;
  double netIncomePerAcre = valuePerAcre - inputCostPerAcre;

  debugPrint("Production/acre: $productionPerAcre");
  debugPrint("Value/acre: $valuePerAcre");
  debugPrint("Labour/acre: $labourCostPerAcre");
  debugPrint("InputCost/acre: $inputCostPerAcre");
  debugPrint("NetIncome/acre: $netIncomePerAcre");
}

// ================= Master Function =================
void _calculateAllTotals() {
  _calculateSectionB();
  _calculateLabour();
  _calculateMECosts();
  _calculateWaterUsage(); // ✅ new line added
  _calculateFinal();

  setState(() {}); // refresh UI
}






  // ---------------- Fetch Farmer Data ----------------
// ⬅️ Add this import at the top

Future<void> _fetchFarmerData() async {
  final res = await ApiService.getEmployeeById(widget.farmerId);
  if (res["status"] == "success" && res["data"] != null) {
    final data = res["data"];
    debugPrint("======= RAW API DATA =======");
    debugPrint(data.toString());
    debugPrint("water_usage_in_mm from API: ${data["water_usage_in_mm"]}");
    debugPrint("water_usage_in_ltr from API: ${data["water_usage_in_ltr"]}");
    debugPrint("irrigation_efficiency from API: ${data["irrigation_efficiency"]}");
    setState(() {
      // ---------- Section A ----------
      auditIdCtrl.text = data["employee_id"] ?? "";
      
   


      // format sowing_date
      // format sowing_date
if (data["sowing_date"] != null && data["sowing_date"].toString().isNotEmpty) {
  DateTime? sowing = DateTime.tryParse(data["sowing_date"]);
  sowingDateCtrl.text = sowing != null ? sowing.toIso8601String().split("T").first : "";
}

// format harvest_date
if (data["harvest_date"] != null && data["harvest_date"].toString().isNotEmpty) {
  DateTime? harvest = DateTime.tryParse(data["harvest_date"]);
  harvestDateCtrl.text = harvest != null ? harvest.toIso8601String().split("T").first : "";
}


      irrigationsCtrl.text = data["no_of_irrigations"]?.toString() ?? "";
      landAreaCtrl.text = data["land_area"]?.toString() ?? "";

      // ---------- Section B ----------
      totalYieldCtrl.text = data["total_yield"]?.toString() ?? "";
      totalYieldKgCtrl.text = data["total_yield_kg"]?.toString() ?? "";
      soldQtyCtrl.text = data["sold_quantity"]?.toString() ?? "";
      salePriceCtrl.text = data["sale_price_per_unit"]?.toString() ?? "";
      pricePerKgCtrl.text = data["price_per_kg"]?.toString() ?? "";
      farmGatePriceCtrl.text = data["farm_gate_price"]?.toString() ?? "";
      priceGapCtrl.text = data["price_gap"]?.toString() ?? "";
      valueSoldCtrl.text = data["value_sold"]?.toString() ?? "";
      qtyHouseholdCtrl.text = data["household_qty"]?.toString() ?? "";
      valueHouseholdCtrl.text = data["household_value"]?.toString() ?? "";
      totalValueCtrl.text = data["total_value"]?.toString() ?? "";

      // ---------- Labour ----------
      paidLabourCtrl.text = data["paid_labour_cost"]?.toString() ?? "";
      maleFamilyDaysCtrl.text = data["male_family_labour_days"]?.toString() ?? "";
      femaleFamilyDaysCtrl.text = data["female_family_labour_days"]?.toString() ?? "";
      maleWageCtrl.text = data["male_wage_rate"]?.toString() ?? "";
      femaleWageCtrl.text = data["female_wage_rate"]?.toString() ?? "";
      valuedMaleCtrl.text = data["valued_male_family_labour"]?.toString() ?? "";
      valuedFemaleCtrl.text = data["valued_female_family_labour"]?.toString() ?? "";
      valuedFamilyCtrl.text = data["valued_family_labour"]?.toString() ?? "";
      totalLabourCtrl.text = data["total_labour_cost"]?.toString() ?? "";

      // ---------- Machinery & Costs ----------
List<dynamic> machineryIds = data["machinery_id"] ?? [];
_selectedMachineryIds =
    machineryIds.map((e) => int.tryParse(e.toString()) ?? 0).toSet();

machineryRentCtrl.text = data["machinery_cost"]?.toString() ?? "";
irrigationCostCtrl.text = data["irrigation_cost"]?.toString() ?? "";
otherCostCtrl.text = data["other_cost"]?.toString() ?? "";
totalCostCtrl.text = data["mtotal_cost"]?.toString() ?? "";


      // ---------- Water Usage ----------
      // ✅ Debug first
debugPrint("RAW API DATA: ${data.toString()}");

// ✅ Water usage
waterUsageMmCtrl.text = data["water_usage_mm"]?.toString() 
    ?? data["water_usage_in_mm"]?.toString() 
    ?? "";

waterUsageLitresCtrl.text = data["water_usage_ltr"]?.toString() 
    ?? data["water_usage_in_ltr"]?.toString() 
    ?? "";

irrigationEfficiencyCtrl.text = data["irrigation_efficiency"]?.toString() ?? "";

      // ---------- Dropdown preload IDs ----------
      selectedSeason = int.tryParse(data["season"]?.toString() ?? "");
      selectedCrop = int.tryParse(data["cropp"]?.toString() ?? "");
      selectedIrrigationMethod = int.tryParse(data["irrigationn_method"]?.toString() ?? "");
      selectedYieldUnit = int.tryParse(data["yield_unit"]?.toString() ?? "");
yieldUnitToKgFactor = MasterService.getUnitFactor(selectedYieldUnit); // ✅ factor update
selectedUsageType = int.tryParse(data["usage_type"]?.toString() ?? "");
if (selectedCrop != null) {
  _fetchAndApplyCropInfo(selectedCrop!, selectedIrrigationMethod);
}

// ✅ values set karne ke baad calculation force-run karo
_calculateAllTotals();


// ✅ values set karne ke baad calculation force-run karo
_calculateAllTotals();

    });
  }
}

// Fetch crop master and apply values to water fields
Future<void> _fetchAndApplyCropInfo(int cropId, int? irrigationMethodId) async {
  try {
    final res = await ApiService.getCropInfo(cropId);
    if (res["ok"] == true && res["data"] != null) {
      _cropData = Map<String, dynamic>.from(res["data"]);

      // use MasterService helper (we added earlier)
      final usage = MasterService.calculateWaterUsage(
        cropData: _cropData,
        irrigationMethodId: irrigationMethodId,
      );

      setState(() {
        // fill UI controllers exactly like web
        waterUsageMmCtrl.text = usage["waterRequirementMM"] ?? "";
        waterUsageLitresCtrl.text = usage["totalLitres"] ?? "";
        irrigationEfficiencyCtrl.text = usage["efficiency"] ?? "";
      });

      // recalc dependent totals (value per acre, etc.)
      _calculateAllTotals();
    } else {
      debugPrint("getCropInfo failed: ${res["message"]}");
    }
  } catch (e) {
    debugPrint("Error in _fetchAndApplyCropInfo: $e");
  }
}



  // ---------------- Update Functions ----------------
  Future<void> _updateSectionA() async {
    final body = {
      "audit_id": auditIdCtrl.text,
      "season": selectedSeason,
      "cropp": selectedCrop,
      "sowing_date": sowingDateCtrl.text,
      "harvest_date": harvestDateCtrl.text,
      "irrigationn_method": selectedIrrigationMethod,
      "no_of_irrigations": irrigationsCtrl.text,
      "land_area": landAreaCtrl.text,
    };
    await _callUpdate(body, "Section A updated successfully");
  }

  Future<void> _updateSectionB() async {
    final body = {
      
      "yield_unit": selectedYieldUnit,
      "total_yield": totalYieldCtrl.text,
      "total_yield_kg": totalYieldKgCtrl.text,
      "usage_type": selectedUsageType,
      "sold_quantity": soldQtyCtrl.text,
      "sale_price_per_unit": salePriceCtrl.text,
      "price_per_kg": pricePerKgCtrl.text,
      "farm_gate_price": farmGatePriceCtrl.text,
      "price_gap": priceGapCtrl.text,
      "value_sold": valueSoldCtrl.text,
      "household_qty": qtyHouseholdCtrl.text,
      "household_value": valueHouseholdCtrl.text,
      "total_value": totalValueCtrl.text,
    };
    await _callUpdate(body, "Section B updated successfully");
  }

  
void showToast(BuildContext context, String message) {
  if (kIsWeb) {
    // Web में Snackbar दिखा देंगे
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } else {
    // Mobile (Android/iOS) में Fluttertoast चलेगा
    Fluttertoast.showToast(msg: message);
  }
}

  Future<void> _updateLabourUsage() async {
  final body = <String, dynamic>{
    "paid_labour_cost": double.tryParse(paidLabourCtrl.text) ?? 0,
    "male_family_labour_days": int.tryParse(maleFamilyDaysCtrl.text) ?? 0,
    "female_family_labour_days": int.tryParse(femaleFamilyDaysCtrl.text) ?? 0,
    "male_wage_rate": double.tryParse(maleWageCtrl.text) ?? 0,
    "female_wage_rate": double.tryParse(femaleWageCtrl.text) ?? 0,
    "valued_male_family_labour": double.tryParse(valuedMaleCtrl.text) ?? 0,
    "valued_female_family_labour": double.tryParse(valuedFemaleCtrl.text) ?? 0,
    "valued_family_labour": double.tryParse(valuedFamilyCtrl.text) ?? 0,
    "total_labour_cost": double.tryParse(totalLabourCtrl.text) ?? 0,
  };

  await _callUpdate(body, "Labour usage updated successfully");
}


  Future<void> _updateMECosts() async {
  final body = <String, dynamic>{
    "machinery_id": _selectedMachineryIds.map((e) => e.toString()).toList(),
    "machinery_cost": double.tryParse(machineryRentCtrl.text) ?? 0,
    "irrigation_cost": double.tryParse(irrigationCostCtrl.text) ?? 0,
    "other_cost": double.tryParse(otherCostCtrl.text) ?? 0,
    "mtotal_cost": double.tryParse(totalCostCtrl.text) ?? 0,
  };

  await _callUpdate(body, "M&E costs updated successfully");
}



  Future<void> _updateWaterUsage() async {
  final body = {
    "cropp": selectedCrop,                     // ✅ cropp
    "irrigationn_method": selectedIrrigationMethod,  // ✅ irrigationn_method
    "water_usage_in_mm": waterUsageMmCtrl.text,
    "water_usage_in_ltr": waterUsageLitresCtrl.text,
    "land_area": landAreaCtrl.text,
    "irrigation_efficiency": irrigationEfficiencyCtrl.text,
  };
  await _callUpdate(body, "Water usage updated successfully");
}


Future<void> _callUpdate(Map<String, dynamic> body, String successMessage) async {
  try {
    // ✅ हर बार required fields inject कर देंगे
    body.addAll({
  "main_crop": selectedCrop,              // ✅ पुराना column भी update
  "irrigation_method": selectedIrrigationMethod,  // ✅ पुराना column भी update
  "cropp": selectedCrop,                  // ✅ नया column
  "irrigationn_method": selectedIrrigationMethod, // ✅ नया column
});

    // ✅ सही employee_id से call
    final res = await ApiService.updateEmployeeJson(auditIdCtrl.text, body);

    debugPrint("Updating employee_id: ${auditIdCtrl.text}");
    debugPrint("Request Body: $body");
    debugPrint("Update Response: $res");

    if (res != null && res["status"] == "success") {
      showToast(context, successMessage);
    } else {
      showToast(context, res?["message"] ?? "Update failed");
    }
  } catch (e) {
    debugPrint("Update Error: $e");
    showToast(context, "Update error: $e"); // ✅ unified toast
  }
}



  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text("Crop Audit", style: TextStyle(color: Colors.black)),
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

  // ---------------- Section Widgets ----------------
  Widget _buildSectionA() {
  debugPrint("Seasons: ${MasterService.seasons}");
  debugPrint("Crops: ${MasterService.crops}");
  debugPrint("Irrigation: ${MasterService.irrigationMethods}");

  return _formContainer([
    _buildTextField("Audit ID", auditIdCtrl, readOnly: true),
    _buildDropdown("Season", MasterService.seasons, selectedSeason,
        (val) => setState(() => selectedSeason = val)),

    // ✅ Main Crop dropdown with crop info fetch
    _buildDropdown("Main Crop", MasterService.crops, selectedCrop, (val) {
      setState(() {
        selectedCrop = val;
      });
      if (val != null) {
        _fetchAndApplyCropInfo(val, selectedIrrigationMethod);
      }
    }),

    _buildDateField("Sowing Date", sowingDateCtrl),
    _buildDateField("Harvest Date", harvestDateCtrl),

    // ✅ Irrigation method dropdown with crop info fetch
    _buildDropdown("Irrigation Method", MasterService.irrigationMethods,
        selectedIrrigationMethod, (val) {
      setState(() {
        selectedIrrigationMethod = val;
      });
      if (selectedCrop != null) {
        _fetchAndApplyCropInfo(selectedCrop!, val);
      }
    }),

    _buildTextField("No. of Irrigations", irrigationsCtrl),
    _buildTextField("Land Area", landAreaCtrl,
        onChanged: (_) => _calculateWaterUsage()),

    _buildButtons(_updateSectionA),
  ]);
}


  Widget _buildSectionB() {
  return _formContainer([
    _buildDropdown("Yield Unit", MasterService.unitTypes, selectedYieldUnit,
    (val) {
      setState(() {
        selectedYieldUnit = val;
        // ✅ yield unit change hote hi calculation auto-update
        yieldUnitToKgFactor = MasterService.getUnitFactor(val);
        _calculateAllTotals();
      });
    }),

    _buildTextField("Total Yield", totalYieldCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Total Yield in KG", totalYieldKgCtrl, readOnly: true),
 // ✅
    _buildDropdown("Usage Type", MasterService.usageTypes, selectedUsageType,
        (val) => setState(() => selectedUsageType = val)),
    _buildTextField("Sold Quantity", soldQtyCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Sale Price per unit", salePriceCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Price of the produce per KG", pricePerKgCtrl, readOnly: true),
    _buildTextField("Farm Gate Price per unit", farmGatePriceCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Price Gap per unit", priceGapCtrl, readOnly: true),
    _buildTextField("Value of the produce sold", valueSoldCtrl, readOnly: true),
    _buildTextField("Quantity kept for household usage", qtyHouseholdCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Value kept for household usage", valueHouseholdCtrl, readOnly: true),
    _buildTextField("Total value of the produce (Rs)", totalValueCtrl, readOnly: true),
    _buildButtons(_updateSectionB),
  ]);
}


  Widget _buildLabourUsage() {
  return _formContainer([
    _buildTextField("Paid Labour Cost (Rs)", paidLabourCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Male Family Labour Days", maleFamilyDaysCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Female Family Labour Days", femaleFamilyDaysCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Male Wage Rate", maleWageCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Female Wage Rate", femaleWageCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Valued Male Family Labour (Rs)", valuedMaleCtrl, readOnly: true),
    _buildTextField("Valued Female Family Labour (Rs)", valuedFemaleCtrl, readOnly: true),
    _buildTextField("Valued Family Labour (Rs)", valuedFamilyCtrl, readOnly: true),
    _buildTextField("Total Labour Cost (Hired + family labour)", totalLabourCtrl, readOnly: true),
    _buildButtons(_updateLabourUsage),
  ]);
}

 Widget _buildMECosts() {
  return _formContainer([
    MachinerySection(
      isUpdateMode: true,
      selectedIds: _selectedMachineryIds.toList(),
      onSelectionChanged: (ids) {
        setState(() => _selectedMachineryIds = ids.toSet());
      },
    ),
    _buildTextField("Machinery Rent Cost", machineryRentCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Irrigation Cost", irrigationCostCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Other Cost", otherCostCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅
    _buildTextField("Total Cost", totalCostCtrl, readOnly: true),
    _buildButtons(_updateMECosts),
  ]);
}



  // ✅ New code (with auto calculation like web)
Widget _buildWaterUsage() {
  return _formContainer([
    _buildDropdown(
      "Crop Name",
      MasterService.crops,
      selectedCrop,
      (val) => setState(() => selectedCrop = val),
      readOnly: false, // crop readonly
    ),
    _buildDropdown(
      "Irrigation Method",
      MasterService.irrigationMethods,
      selectedIrrigationMethod,
      (val) => setState(() => selectedIrrigationMethod = val),
      readOnly: false, // irrigation method readonly
    ),
    _buildTextField("Water Usage in mm", waterUsageMmCtrl, readOnly: true), // ✅ DB से आएगा, readonly
 // ✅ live calculation
    _buildTextField("Water Usage in Litres", waterUsageLitresCtrl, readOnly: true), // ✅ auto-filled
    _buildTextField("Land Size", landAreaCtrl,
        onChanged: (_) => _calculateAllTotals()), // ✅ live calculation
    _buildTextField("Irrigation Efficiency (%)", irrigationEfficiencyCtrl, readOnly: true), // auto
    _buildButtons(_updateWaterUsage),
  ]);
}



  // ---------------- Reusable Widgets ----------------
  Widget _formContainer(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
  String label,
  TextEditingController controller, {
  bool readOnly = false,
  Function(String)? onChanged,
}) {
  return SizedBox(
    width: 300,
    child: TextField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: readOnly, // ✅ readonly ho toh fill karo
        fillColor: readOnly ? Colors.grey[200] : null, // ✅ halka grey
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );
}



Widget _buildDateField(String label, TextEditingController controller) {
  return SizedBox(
    width: 300,
    child: TextField(
      controller: controller,
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
          initialDate: controller.text.isNotEmpty
              ? DateTime.tryParse(controller.text) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = picked.toIso8601String().split("T").first; 
          // => yyyy-MM-dd
        }
      },
    ),
  );
}


  Widget _buildDropdown(
  String label,
  Map<int, String> items,
  int? value,
  Function(int?) onChanged, {
  bool readOnly = false,
}) {
  return SizedBox(
    width: 300,
    child: DropdownButtonFormField<int>(
      value: (value != null && items.containsKey(value)) ? value : null,
      items: items.entries
          .map((e) =>
              DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: readOnly ? null : onChanged,
// ✅ disable agar readonly
      decoration: InputDecoration(
        labelText: label,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[200] : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );
}


  Widget _buildCheckbox(
      String label, bool value, Function(bool) onChanged) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v!)),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildButtons(Future<void> Function() onSave) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Save", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
