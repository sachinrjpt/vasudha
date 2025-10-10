// lib/models/seed_usage.dart
class SeedUsage {
  final int id;
  final int farmerId;
  final String farmerName;
  final String seedName;
  final String variety;
  final double quantityUsed;
  final int unitTypeId;
  final String unitTypeName;
  final double perUnitCost;
  final double totalCost;

  SeedUsage({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.seedName,
    required this.variety,
    required this.quantityUsed,
    required this.unitTypeId,
    required this.unitTypeName,
    required this.perUnitCost,
    required this.totalCost,
  });

  factory SeedUsage.fromJson(Map<String, dynamic> json) {
    return SeedUsage(
      id: json['id'] ?? 0,
      farmerId: json['farmer_id'] ?? 0,
      farmerName: json['farmer_name']?.toString() ?? '', // 👈 safe
      seedName: json['seed_name']?.toString() ?? '',
      variety: json['seed_variety']?.toString() ?? '',
      quantityUsed: double.tryParse(json['quantity_used'].toString()) ?? 0.0,
      unitTypeId: json['unit_type'] ?? 0,
      unitTypeName: json['unit_type_name']?.toString() ?? '',
      perUnitCost: double.tryParse(json['per_unit_cost'].toString()) ?? 0.0,
      totalCost: double.tryParse(json['total_cost'].toString()) ?? 0.0,
    );
  }
}
