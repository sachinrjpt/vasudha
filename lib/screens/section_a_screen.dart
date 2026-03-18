// lib/screens/section_a_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../services/master_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../screens/machinery_section.dart';
import 'package:vasudha/widgets/auto_text.dart';

class SectionAScreen extends StatefulWidget {
  final String farmerId;
  final Map<String, dynamic> moduleData;
  final String plotId;
  final bool isAddMode;
  final void Function(String newPlotId)? onPlotIdGenerated;

  const SectionAScreen({
    super.key,
    required this.farmerId,
    required this.moduleData,
    required this.plotId,
    required this.isAddMode,
    this.onPlotIdGenerated,
  });

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
  final inputCostPerAcreCtrl = TextEditingController();
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
  int? currentAuditId;

  double yieldUnitToKgFactor = 1; // TODO: master data se link karna baad me

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initMasters();
    print("======== SECTION A DEBUG ========");
    print(widget.moduleData);
    print("isAddMode: ${widget.isAddMode}");

    if (!widget.isAddMode) {
      print("Audit Data: ${widget.moduleData?["data"]?["audit"]}");
    }
    _loadFromModuleData();

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
  double _toDouble(String? AutoText) => double.tryParse(AutoText ?? "") ?? 0;

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
    double pricePerKg = (salePrice > 0 && yieldUnitToKgFactor > 0)
        ? salePrice / yieldUnitToKgFactor
        : 0;
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
    inputCostPerAcreCtrl.text = inputCostPerAcre.toStringAsFixed(2);
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

  void _loadFromModuleData() {
    final data = widget.moduleData["data"] ?? {};

    setState(() {
      if (widget.isAddMode) {
        auditIdCtrl.text = "FARM-${widget.farmerId}";
        currentAuditId = null;
        return;
      }

      final audit = data["audit"] ?? {};

      currentAuditId = audit["id"];
      auditIdCtrl.text = audit["plot_id"]?.toString() ?? "";

      // ---------------- SECTION A ----------------
      sowingDateCtrl.text = audit["sowing_date"] ?? "";
      harvestDateCtrl.text = audit["harvest_date"] ?? "";
      irrigationsCtrl.text = audit["no_of_irrigations"]?.toString() ?? "";

      landAreaCtrl.text =
          (audit["land_size"] ?? audit["land_area"])?.toString() ?? "";

      selectedSeason = int.tryParse(audit["season"]?.toString() ?? "");

      selectedCrop = int.tryParse(
        (audit["main_crop"] ?? audit["cropp"])?.toString() ?? "",
      );

      selectedIrrigationMethod = int.tryParse(
        (audit["irrigation_method"] ?? audit["irrigationn_method"])
                ?.toString() ??
            "",
      );

      selectedYieldUnit = int.tryParse(audit["yield_unit"]?.toString() ?? "");

      selectedUsageType = int.tryParse(audit["usage_type"]?.toString() ?? "");

      yieldUnitToKgFactor = MasterService.getUnitFactor(selectedYieldUnit);

      // ---------------- SECTION B ----------------
      totalYieldCtrl.text = audit["total_yield"]?.toString() ?? "";
      totalYieldKgCtrl.text = audit["total_yield_kg"]?.toString() ?? "";
      soldQtyCtrl.text = audit["sold_quantity"]?.toString() ?? "";
      salePriceCtrl.text = audit["sale_price_per_unit"]?.toString() ?? "";
      farmGatePriceCtrl.text = audit["farm_gate_price"]?.toString() ?? "";
      pricePerKgCtrl.text = audit["price_per_kg"]?.toString() ?? "";
      priceGapCtrl.text = audit["price_gap"]?.toString() ?? "";
      valueSoldCtrl.text = audit["value_sold"]?.toString() ?? "";
      qtyHouseholdCtrl.text = audit["household_qty"]?.toString() ?? "";
      valueHouseholdCtrl.text = audit["household_value"]?.toString() ?? "";
      totalValueCtrl.text = audit["total_value"]?.toString() ?? "";

      // ---------------- LABOUR ----------------
      paidLabourCtrl.text = audit["paid_labour_cost"]?.toString() ?? "";
      maleFamilyDaysCtrl.text =
          audit["male_family_labour_days"]?.toString() ?? "";
      femaleFamilyDaysCtrl.text =
          audit["female_family_labour_days"]?.toString() ?? "";
      maleWageCtrl.text = audit["male_wage_rate"]?.toString() ?? "";
      femaleWageCtrl.text = audit["female_wage_rate"]?.toString() ?? "";

      valuedMaleCtrl.text =
          audit["valued_male_family_labour"]?.toString() ?? "";
      valuedFemaleCtrl.text =
          audit["valued_female_family_labour"]?.toString() ?? "";
      valuedFamilyCtrl.text = audit["valued_family_labour"]?.toString() ?? "";
      totalLabourCtrl.text = audit["total_labour_cost"]?.toString() ?? "";

      // ---------------- M&E ----------------
      machineryRentCtrl.text = audit["machinery_cost"]?.toString() ?? "";
      irrigationCostCtrl.text = audit["irrigation_cost"]?.toString() ?? "";
      otherCostCtrl.text = audit["other_cost"]?.toString() ?? "";
      totalCostCtrl.text = audit["mtotal_cost"]?.toString() ?? "";

      // machinery ids
      if (audit["machinery_id"] != null) {
        _selectedMachineryIds = audit["machinery_id"]
            .toString()
            .split(',')
            .map((e) => int.tryParse(e) ?? 0)
            .where((e) => e > 0)
            .toSet();
      }

      // ---------------- WATER ----------------
      waterUsageMmCtrl.text = audit["water_usage_in_mm"]?.toString() ?? "";
      waterUsageLitresCtrl.text = audit["water_usage_in_ltr"]?.toString() ?? "";
      irrigationEfficiencyCtrl.text =
          audit["irrigation_efficiency"]?.toString() ?? "";
    });

    _calculateAllTotals();
  }

  Future<void> _updateAllSections() async {
    final body = _buildFullRequestBody();
    await _callUpdate(body, "Audit updated successfully");
  }

  Future<void> _initMasters() async {
    print("🚀 Loading masters...");
    await MasterService.init();
    print("✅ Masters loaded: ${MasterService.crops}");

    setState(() {
      isLoading = false;
    });
  }

  // Fetch crop master and apply values to water fields
  Future<void> _fetchAndApplyCropInfo(
    int cropId,
    int? irrigationMethodId,
  ) async {
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
    await _callUpdate(body, "Audit plot information updated successfully");
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
    await _callUpdate(body, "Crop Yield & Usage updated successfully");
  }

  void showToast(BuildContext context, String message) {
    if (kIsWeb) {
      // Web में Snackbar दिखा देंगे
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AutoText(message)));
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
      "valued_female_family_labour":
          double.tryParse(valuedFemaleCtrl.text) ?? 0,
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
      "cropp": selectedCrop,
      "irrigationn_method": selectedIrrigationMethod,
      "land_size": landAreaCtrl.text,
    };

    await _callUpdate(body, "Water usage updated successfully");
  }

  Map<String, dynamic> _buildFullRequestBody() {
    return {
      // ---------- Section A ----------
      "audit_id": currentAuditId,
      "plot_id": widget.plotId,
      "season": selectedSeason,
      "main_crop": selectedCrop,
      "cropp": selectedCrop,
      "sowing_date": sowingDateCtrl.text,
      "harvest_date": harvestDateCtrl.text,
      "irrigation_method": selectedIrrigationMethod,
      "irrigationn_method": selectedIrrigationMethod,
      "no_of_irrigations": irrigationsCtrl.text,
      "land_size": landAreaCtrl.text,

      // ---------- Section B ----------
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

      // ---------- Labour ----------
      "paid_labour_cost": paidLabourCtrl.text,
      "male_family_labour_days": maleFamilyDaysCtrl.text,
      "female_family_labour_days": femaleFamilyDaysCtrl.text,
      "male_wage_rate": maleWageCtrl.text,
      "female_wage_rate": femaleWageCtrl.text,
      "valued_male_family_labour": valuedMaleCtrl.text,
      "valued_female_family_labour": valuedFemaleCtrl.text,
      "valued_family_labour": valuedFamilyCtrl.text,
      "total_labour_cost": totalLabourCtrl.text,

      // ---------- M&E ----------
      "machinery_id": _selectedMachineryIds.map((e) => e.toString()).toList(),
      "machinery_cost": machineryRentCtrl.text,
      "irrigation_cost": irrigationCostCtrl.text,
      "other_cost": otherCostCtrl.text,
      "mtotal_cost": totalCostCtrl.text,

      // ---------- Water ----------
      "water_usage_in_mm": waterUsageMmCtrl.text,
      "water_usage_in_ltr": waterUsageLitresCtrl.text,
      "irrigation_efficiency": irrigationEfficiencyCtrl.text,

      "input_cost_per_acre": double.tryParse(inputCostPerAcreCtrl.text) ?? 0,
    };
  }

  Future<void> _callUpdate(
    Map<String, dynamic> body,
    String successMessage,
  ) async {
    try {
      final fullBody = _buildFullRequestBody();

      final url = "${ApiService.baseUrl}/farmers/${widget.farmerId}/analysis";
      final res = await ApiService.putJson(url, fullBody);

      debugPrint("Updating employee_id: ${widget.farmerId}");
      debugPrint("Request Body: $fullBody");
      debugPrint("Update Response: $res");

      if (res != null && res["status"] == "success") {
        final audit = res["data"]?["audit"];

        if (audit != null) {
          setState(() {
            // ---------------- Update controllers ----------------
            auditIdCtrl.text = audit["plot_id"]?.toString() ?? auditIdCtrl.text;
            currentAuditId = audit["id"];

            // Section A
            landAreaCtrl.text =
                audit["land_size"]?.toString() ?? landAreaCtrl.text;
            sowingDateCtrl.text = audit["sowing_date"] ?? sowingDateCtrl.text;
            harvestDateCtrl.text =
                audit["harvest_date"] ?? harvestDateCtrl.text;
            irrigationsCtrl.text =
                audit["no_of_irrigations"]?.toString() ?? irrigationsCtrl.text;

            // Section B
            totalYieldCtrl.text =
                audit["total_yield"]?.toString() ?? totalYieldCtrl.text;
            totalYieldKgCtrl.text =
                audit["total_yield_kg"]?.toString() ?? totalYieldKgCtrl.text;
            soldQtyCtrl.text =
                audit["sold_quantity"]?.toString() ?? soldQtyCtrl.text;
            salePriceCtrl.text =
                audit["sale_price_per_unit"]?.toString() ?? salePriceCtrl.text;
            farmGatePriceCtrl.text =
                audit["farm_gate_price"]?.toString() ?? farmGatePriceCtrl.text;
            pricePerKgCtrl.text =
                audit["price_per_kg"]?.toString() ?? pricePerKgCtrl.text;
            priceGapCtrl.text =
                audit["price_gap"]?.toString() ?? priceGapCtrl.text;
            valueSoldCtrl.text =
                audit["value_sold"]?.toString() ?? valueSoldCtrl.text;
            qtyHouseholdCtrl.text =
                audit["household_qty"]?.toString() ?? qtyHouseholdCtrl.text;
            valueHouseholdCtrl.text =
                audit["household_value"]?.toString() ?? valueHouseholdCtrl.text;
            totalValueCtrl.text =
                audit["total_value"]?.toString() ?? totalValueCtrl.text;

            // Labour
            paidLabourCtrl.text =
                audit["paid_labour_cost"]?.toString() ?? paidLabourCtrl.text;
            maleFamilyDaysCtrl.text =
                audit["male_family_labour_days"]?.toString() ??
                maleFamilyDaysCtrl.text;
            femaleFamilyDaysCtrl.text =
                audit["female_family_labour_days"]?.toString() ??
                femaleFamilyDaysCtrl.text;
            maleWageCtrl.text =
                audit["male_wage_rate"]?.toString() ?? maleWageCtrl.text;
            femaleWageCtrl.text =
                audit["female_wage_rate"]?.toString() ?? femaleWageCtrl.text;
            valuedMaleCtrl.text =
                audit["valued_male_family_labour"]?.toString() ??
                valuedMaleCtrl.text;
            valuedFemaleCtrl.text =
                audit["valued_female_family_labour"]?.toString() ??
                valuedFemaleCtrl.text;
            valuedFamilyCtrl.text =
                audit["valued_family_labour"]?.toString() ??
                valuedFamilyCtrl.text;
            totalLabourCtrl.text =
                audit["total_labour_cost"]?.toString() ?? totalLabourCtrl.text;

            // M&E
            machineryRentCtrl.text =
                audit["machinery_cost"]?.toString() ?? machineryRentCtrl.text;
            irrigationCostCtrl.text =
                audit["irrigation_cost"]?.toString() ?? irrigationCostCtrl.text;
            otherCostCtrl.text =
                audit["other_cost"]?.toString() ?? otherCostCtrl.text;
            totalCostCtrl.text =
                audit["mtotal_cost"]?.toString() ?? totalCostCtrl.text;

            // machinery ids
            if (audit["machinery_id"] != null) {
              _selectedMachineryIds = audit["machinery_id"]
                  .toString()
                  .split(',')
                  .map((e) => int.tryParse(e) ?? 0)
                  .where((e) => e > 0)
                  .toSet();
            }

            // Water usage
            waterUsageMmCtrl.text =
                audit["water_usage_in_mm"]?.toString() ?? waterUsageMmCtrl.text;
            waterUsageLitresCtrl.text =
                audit["water_usage_in_ltr"]?.toString() ??
                waterUsageLitresCtrl.text;
            irrigationEfficiencyCtrl.text =
                audit["irrigation_efficiency"]?.toString() ??
                irrigationEfficiencyCtrl.text;
          });

          // Recalculate totals based on updated data
          _calculateAllTotals();
        }

        // Handle Add mode plot_id generation
        if (widget.isAddMode && audit?["plot_id"] != null) {
          final generatedPlotId = audit["plot_id"].toString();
          setState(() {
            auditIdCtrl.text = generatedPlotId;
            currentAuditId = audit["id"];
          });

          if (widget.onPlotIdGenerated != null) {
            widget.onPlotIdGenerated!(generatedPlotId);
          }
        }

        showToast(context, successMessage);
      } else {
        showToast(context, res?["message"] ?? "Update failed");
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      showToast(context, "Update error: $e");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: AutoText("Crop Audit", style: TextStyle(color: Colors.black)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          tabs: [
            Tab(child: AutoText("Audit plot information")),
            Tab(child: AutoText("Crop Yield & Usage")),
            Tab(child: AutoText("Labour usage (D)")),
            Tab(child: AutoText("M&E Costs (E)")),
            Tab(child: AutoText("Water usage")),
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
      _buildDropdown(
        "Season",
        MasterService.seasons,
        selectedSeason,
        (val) => setState(() => selectedSeason = val),
      ),

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
      _buildDropdown(
        "Irrigation Method",
        MasterService.irrigationMethods,
        selectedIrrigationMethod,
        (val) {
          setState(() {
            selectedIrrigationMethod = val;
          });
          if (selectedCrop != null) {
            _fetchAndApplyCropInfo(selectedCrop!, val);
          }
        },
      ),

      _buildTextField("No. of Irrigations", irrigationsCtrl),
      _buildTextField(
        "Land Area",
        landAreaCtrl,
        onChanged: (_) => _calculateWaterUsage(),
      ),

      _buildButtons(_updateAllSections),
    ]);
  }

  Widget _buildSectionB() {
    return _formContainer([
      _buildDropdown("Yield Unit", MasterService.unitTypes, selectedYieldUnit, (
        val,
      ) {
        setState(() {
          selectedYieldUnit = val;
          // ✅ yield unit change hote hi calculation auto-update
          yieldUnitToKgFactor = MasterService.getUnitFactor(val);
          if (widget.isAddMode) {
            _calculateAllTotals();
          }
        });
      }),

      _buildTextField(
        "Total Yield",
        totalYieldCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField("Total Yield in KG", totalYieldKgCtrl, readOnly: true),
      // ✅
      _buildDropdown(
        "Usage Type",
        MasterService.usageTypes,
        selectedUsageType,
        (val) => setState(() => selectedUsageType = val),
      ),
      _buildTextField(
        "Sold Quantity",
        soldQtyCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Sale Price per unit",
        salePriceCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Price of the produce per KG",
        pricePerKgCtrl,
        readOnly: true,
      ),
      _buildTextField(
        "Farm Gate (Local market) Price per unit",
        farmGatePriceCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField("Price Gap per unit", priceGapCtrl, readOnly: true),
      _buildTextField(
        "Value of the produce sold",
        valueSoldCtrl,
        readOnly: true,
      ),
      _buildTextField(
        "Quantity kept for household usage",
        qtyHouseholdCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Value kept for household usage",
        valueHouseholdCtrl,
        readOnly: true,
      ),
      _buildTextField(
        "Total value of the produce (Rs)",
        totalValueCtrl,
        readOnly: true,
      ),
      _buildButtons(_updateAllSections),
    ]);
  }

  Widget _buildLabourUsage() {
    return _formContainer([
      _buildTextField(
        "Paid Labour Cost (Rs)",
        paidLabourCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Male Family Labour Days",
        maleFamilyDaysCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Female Family Labour Days",
        femaleFamilyDaysCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Male Wage Rate",
        maleWageCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Female Wage Rate",
        femaleWageCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Valued Male Family Labour (Rs)",
        valuedMaleCtrl,
        readOnly: true,
      ),
      _buildTextField(
        "Valued Female Family Labour (Rs)",
        valuedFemaleCtrl,
        readOnly: true,
      ),
      _buildTextField(
        "Valued Family Labour (Rs)",
        valuedFamilyCtrl,
        readOnly: true,
      ),
      _buildTextField(
        "Total Labour Cost (Hired + family labour)",
        totalLabourCtrl,
        readOnly: true,
      ),
      _buildButtons(_updateAllSections),
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
      _buildTextField(
        "Machinery Rent Cost",
        machineryRentCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Irrigation Cost",
        irrigationCostCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField(
        "Other Cost",
        otherCostCtrl,
        onChanged: (_) => _calculateAllTotals(),
      ), // ✅
      _buildTextField("Total Cost", totalCostCtrl, readOnly: true),
      _buildButtons(_updateAllSections),
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
        readOnly: true, // crop readonly
      ),
      _buildDropdown(
        "Irrigation Method",
        MasterService.irrigationMethods,
        selectedIrrigationMethod,
        (val) => setState(() => selectedIrrigationMethod = val),
        readOnly: true, // irrigation method readonly
      ),
      _buildTextField(
        "Water Usage in mm",
        waterUsageMmCtrl,
        readOnly: true,
      ), // ✅ DB से आएगा, readonly
      // ✅ live calculation
      _buildTextField(
        "Water Usage in Litres",
        waterUsageLitresCtrl,
        readOnly: true,
      ), // ✅ auto-filled
      _buildTextField(
        "Land Size",
        landAreaCtrl,
        onChanged: (_) => _calculateAllTotals(),
        readOnly: true,
      ), // ✅ live calculation
      _buildTextField(
        "Irrigation Efficiency (%)",
        irrigationEfficiencyCtrl,
        readOnly: true,
      ), // auto
      _buildButtons(_updateAllSections),
    ]);
  }

  // ---------------- Reusable Widgets ----------------
  Widget _formContainer(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(runSpacing: 16, spacing: 16, children: children),
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
          label: AutoText(label),
          filled: readOnly, // ✅ readonly ho toh fill karo
          fillColor: readOnly ? Colors.grey[200] : null, // ✅ halka grey
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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
          label: AutoText(label),
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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
            .map(
              (e) =>
                  DropdownMenuItem<int>(value: e.key, child: AutoText(e.value)),
            )
            .toList(),
        onChanged: readOnly ? null : onChanged,
        // ✅ disable agar readonly
        decoration: InputDecoration(
          label: AutoText(label),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v!)),
          AutoText(label),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: AutoText("Save", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
