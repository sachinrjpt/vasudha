import 'api_service.dart';

class MasterService {
  static Map<int, String> crops = {};
  static Map<int, String> seasons = {};
  static Map<int, String> irrigationMethods = {};
  static Map<int, String> usageTypes = {};
  static Map<int, String> unitTypes = {};
  static Map<int, String> machineries = {};

  static bool _initialized = false;

  /// Load all master data (only once)
  static Future<void> init() async {
    if (_initialized) return;

    print("🔄 Loading master data...");

    crops = await ApiService.getCrops();
    seasons = await ApiService.getSeasons();
    irrigationMethods = await ApiService.getIrrigationMethods();
    usageTypes = await ApiService.getUsageTypes();
    unitTypes = await ApiService.getUnitTypes();
    machineries = await ApiService.getMachineries();

    print("✅ Seasons Loaded: $seasons");
    print("✅ Crops Loaded: $crops");
    print("✅ Irrigation Loaded: $irrigationMethods");
    print("✅ UsageTypes Loaded: $usageTypes");
    print("✅ UnitTypes Loaded: $unitTypes");
    print("✅ Machineries Loaded: $machineries");

    _initialized = true;
  }

  /// Force reload (use this after login success)
  static Future<void> reload() async {
    _initialized = false;
    await init();
  }

  // ✅ Wrapper method (already tha)
  static Future<Map<int, String>> getMachineries() async {
    return await ApiService.getMachineries();
  }

  // ✅ Helper method: Yield Unit → KG factor
  static double getUnitFactor(int? unitId) {
    if (unitId == null) return 1;

    // Example mapping (adjust as per actual API data)
    switch (unitId) {
      case 1:
        return 1; // Quintal → 100 KG (example: adjust)
      case 2:
        return 1; // KG
      case 3:
        return 1; // Ton
      case 4:
        return 1; // Bori
      default:
        return 20; // fallback
    }
  }

  /// Water usage calculation based on irrigation method
  static Map<String, String> calculateWaterUsage({
    required Map<String, dynamic> cropData,
    required int? irrigationMethodId,
  }) {
    String efficiency = "";
    String totalLitres = "";
    String waterRequirementMM =
        cropData["water_requirement_mm"]?.toString() ?? "";

    if (cropData.isEmpty) {
      return {
        "efficiency": efficiency,
        "totalLitres": totalLitres,
        "waterRequirementMM": waterRequirementMM,
      };
    }

    switch (irrigationMethodId) {
      case 4: // Flood
        efficiency =
            cropData["flood_irrigation_efficiency_percent"]?.toString() ?? "";
        totalLitres =
            cropData["flood_irrigation_efficiency_60"]?.toString() ?? "";
        break;
      case 5: // Sprinkler
        efficiency =
            cropData["sprinkler_irrigation_efficiency_percent"]?.toString() ??
                "";
        totalLitres =
            cropData["sprinkler_irrigation_efficiency_75"]?.toString() ?? "";
        break;
      case 3: // Drip
        efficiency =
            cropData["drip_irrigation_efficiency_percent"]?.toString() ?? "";
        totalLitres =
            cropData["drip_irrigation_efficiency_90"]?.toString() ?? "";
        break;
      case 2: // Rainfed
        efficiency = "-";
        totalLitres = cropData["rainfed_water_usage"]?.toString() ?? "";
        break;
      default:
        efficiency = "";
        totalLitres = "";
    }

    return {
      "efficiency": efficiency,
      "totalLitres": totalLitres,
      "waterRequirementMM": waterRequirementMM,
    };
  }
}
