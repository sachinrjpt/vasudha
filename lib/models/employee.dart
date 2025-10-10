class Employee {
  final int id;
  final String employeeId;
  final String name;
  final String gender;
  final String phone;
  final String? email;
  final String? designation;
  final String status;
  final String? zipCode;
  final String? village;
  final String? state;
  final String? district;
  final String? block;
  final String? halmet;
  final String? landArea;
  final String? address;
  final String? plotId;
  final String? season;
  final String? mainCrop;
  final String? sowingDate;
  final String? harvestDate;
  final String? irrigationMethod;
  final int? noOfIrrigations;
  final String? yieldUnit;
  final String? totalYield;
  final String? usageType;
  final String? soldQuantity;
  final String? salePricePerUnit;
  final String? farmGatePrice;
  final String? seedName;
  final String? seedVarietyId;
  final String? quantityUsed;
  final String? unitType;
  final String? perUnitCost;
  final String? totalCost;
  final String? inputName;
  final String? inputTypes;
  final String? quantityUsedd;
  final String? unitTypess;
  final String? perUnitCosttt;
  final String? totalCosttt;
  final String? paidLabourCost;
  final int? maleFamilyLabourDays;
  final int? femaleFamilyLabourDays;
  final String? maleWageRate;
  final String? femaleWageRate;
  final List<String>? machineryId;
  final String? machineryCost;
  final String? irrigationCost;
  final String? otherCost;
  final String? mtotalCost;
  final int? cropp;
  final int? irrigationnMethod;
  final String? totalYieldKg;
  final String? pricePerKg;
  final String? priceGap;
  final String? valueSold;
  final String? householdQty;
  final String? householdValue;
  final String? totalValue;
  final String? valuedMaleFamilyLabour;
  final String? valuedFemaleFamilyLabour;
  final String? valuedFamilyLabour;
  final String? totalLabourCost;
  final String? waterUsageInLtr;
  final int? irrigationEfficiency;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.gender,
    required this.phone,
    this.email,
    this.designation,
    required this.status,
    this.zipCode,
    this.village,
    this.state,
    this.district,
    this.block,
    this.halmet,
    this.landArea,
    this.address,
    this.plotId,
    this.season,
    this.mainCrop,
    this.sowingDate,
    this.harvestDate,
    this.irrigationMethod,
    this.noOfIrrigations,
    this.yieldUnit,
    this.totalYield,
    this.usageType,
    this.soldQuantity,
    this.salePricePerUnit,
    this.farmGatePrice,
    this.seedName,
    this.seedVarietyId,
    this.quantityUsed,
    this.unitType,
    this.perUnitCost,
    this.totalCost,
    this.inputName,
    this.inputTypes,
    this.quantityUsedd,
    this.unitTypess,
    this.perUnitCosttt,
    this.totalCosttt,
    this.paidLabourCost,
    this.maleFamilyLabourDays,
    this.femaleFamilyLabourDays,
    this.maleWageRate,
    this.femaleWageRate,
    this.machineryId,
    this.machineryCost,
    this.irrigationCost,
    this.otherCost,
    this.mtotalCost,
    this.cropp,
    this.irrigationnMethod,
    this.totalYieldKg,
    this.pricePerKg,
    this.priceGap,
    this.valueSold,
    this.householdQty,
    this.householdValue,
    this.totalValue,
    this.valuedMaleFamilyLabour,
    this.valuedFemaleFamilyLabour,
    this.valuedFamilyLabour,
    this.totalLabourCost,
    this.waterUsageInLtr,
    this.irrigationEfficiency,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  /// ✅ Factory: JSON → Employee
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json["id"] ?? 0,
      employeeId: json["employee_id"] ?? "",
      name: json["name"] ?? "",
      gender: json["gender"] ?? "",
      phone: json["phone"] ?? "",
      email: json["email"],
      designation: json["designation"],
      status: json["status"] ?? "",
      zipCode: json["zip_code"],
      village: json["village"],
      state: json["state"],
      district: json["district"],
      block: json["block"],
      halmet: json["halmet"],
      landArea: json["land_area"],
      address: json["address"],
      plotId: json["plot_id"],
      season: json["season"],
      mainCrop: json["main_crop"],
      sowingDate: json["sowing_date"],
      harvestDate: json["harvest_date"],
      irrigationMethod: json["irrigation_method"]?.toString(),
      noOfIrrigations: json["no_of_irrigations"],
      yieldUnit: json["yield_unit"],
      totalYield: json["total_yield"],
      usageType: json["usage_type"],
      soldQuantity: json["sold_quantity"],
      salePricePerUnit: json["sale_price_per_unit"],
      farmGatePrice: json["farm_gate_price"],
      seedName: json["seed_name"],
      seedVarietyId: json["seed_variety_id"],
      quantityUsed: json["quantity_used"],
      unitType: json["unit_type"],
      perUnitCost: json["per_unit_cost"],
      totalCost: json["total_cost"],
      inputName: json["input_name"],
      inputTypes: json["input_types"],
      quantityUsedd: json["quantity_usedd"],
      unitTypess: json["unit_typess"],
      perUnitCosttt: json["per_unit_costtt"],
      totalCosttt: json["total_costtt"],
      paidLabourCost: json["paid_labour_cost"],
      maleFamilyLabourDays: json["male_family_labour_days"],
      femaleFamilyLabourDays: json["female_family_labour_days"],
      maleWageRate: json["male_wage_rate"],
      femaleWageRate: json["female_wage_rate"],
      machineryId: (json["machinery_id"] as List?)?.map((e) => e.toString()).toList(),
      machineryCost: json["machinery_cost"],
      irrigationCost: json["irrigation_cost"],
      otherCost: json["other_cost"],
      mtotalCost: json["mtotal_cost"],
      cropp: json["cropp"],
      irrigationnMethod: json["irrigationn_method"],
      totalYieldKg: json["total_yield_kg"],
      pricePerKg: json["price_per_kg"],
      priceGap: json["price_gap"],
      valueSold: json["value_sold"],
      householdQty: json["household_qty"],
      householdValue: json["household_value"],
      totalValue: json["total_value"],
      valuedMaleFamilyLabour: json["valued_male_family_labour"],
      valuedFemaleFamilyLabour: json["valued_female_family_labour"],
      valuedFamilyLabour: json["valued_family_labour"],
      totalLabourCost: json["total_labour_cost"],
      waterUsageInLtr: json["water_usage_in_ltr"],
      irrigationEfficiency: json["irrigation_efficiency"],
      profileImage: json["profile_image"],
      createdAt: json["created_at"] != null ? DateTime.tryParse(json["created_at"]) : null,
      updatedAt: json["updated_at"] != null ? DateTime.tryParse(json["updated_at"]) : null,
    );
  }

  /// ✅ Employee → JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "employee_id": employeeId,
      "name": name,
      "gender": gender,
      "phone": phone,
      "email": email,
      "designation": designation,
      "status": status,
      "zip_code": zipCode,
      "village": village,
      "state": state,
      "district": district,
      "block": block,
      "halmet": halmet,
      "land_area": landArea,
      "address": address,
      "plot_id": plotId,
      "season": season,
      "main_crop": mainCrop,
      "sowing_date": sowingDate,
      "harvest_date": harvestDate,
      "irrigation_method": irrigationMethod,
      "no_of_irrigations": noOfIrrigations,
      "yield_unit": yieldUnit,
      "total_yield": totalYield,
      "usage_type": usageType,
      "sold_quantity": soldQuantity,
      "sale_price_per_unit": salePricePerUnit,
      "farm_gate_price": farmGatePrice,
      "seed_name": seedName,
      "seed_variety_id": seedVarietyId,
      "quantity_used": quantityUsed,
      "unit_type": unitType,
      "per_unit_cost": perUnitCost,
      "total_cost": totalCost,
      "input_name": inputName,
      "input_types": inputTypes,
      "quantity_usedd": quantityUsedd,
      "unit_typess": unitTypess,
      "per_unit_costtt": perUnitCosttt,
      "total_costtt": totalCosttt,
      "paid_labour_cost": paidLabourCost,
      "male_family_labour_days": maleFamilyLabourDays,
      "female_family_labour_days": femaleFamilyLabourDays,
      "male_wage_rate": maleWageRate,
      "female_wage_rate": femaleWageRate,
      "machinery_id": machineryId,
      "machinery_cost": machineryCost,
      "irrigation_cost": irrigationCost,
      "other_cost": otherCost,
      "mtotal_cost": mtotalCost,
      "cropp": cropp,
      "irrigationn_method": irrigationnMethod,
      "total_yield_kg": totalYieldKg,
      "price_per_kg": pricePerKg,
      "price_gap": priceGap,
      "value_sold": valueSold,
      "household_qty": householdQty,
      "household_value": householdValue,
      "total_value": totalValue,
      "valued_male_family_labour": valuedMaleFamilyLabour,
      "valued_female_family_labour": valuedFemaleFamilyLabour,
      "valued_family_labour": valuedFamilyLabour,
      "total_labour_cost": totalLabourCost,
      "water_usage_in_ltr": waterUsageInLtr,
      "irrigation_efficiency": irrigationEfficiency,
      "profile_image": profileImage,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }
}
