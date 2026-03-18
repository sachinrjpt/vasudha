// ================= ROOT RESPONSE =================
class KsSalesResponse {
  final KsUser ks;
  final String autoOrderNo;
  final List<KsOrder> orders;
  final double openGross;

  KsSalesResponse({
    required this.ks,
    required this.autoOrderNo,
    required this.orders,
    required this.openGross,
  });

  factory KsSalesResponse.fromJson(Map<String, dynamic> json) {
    return KsSalesResponse(
      ks: KsUser.fromJson(json['ks']),
      autoOrderNo: json['auto_order_no'] ?? '',
      orders: (json['orders'] as List<dynamic>? ?? [])
          .map((e) => KsOrder.fromJson(e))
          .toList(),
      openGross: double.tryParse(json['openGross'].toString()) ?? 0.0,
    );
  }
}

// ================= KS USER =================
class KsUser {
  final int id;
  final String name;
  final String phone;

  KsUser({required this.id, required this.name, required this.phone});

  factory KsUser.fromJson(Map<String, dynamic> json) {
    return KsUser(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

// ================= FARMER (MINI) =================
class FarmerMini {
  final int id;
  final String name;
  final String village;
  final String phone;

  FarmerMini({
    required this.id,
    required this.name,
    required this.village,
    required this.phone,
  });

  factory FarmerMini.fromJson(Map<String, dynamic> json) {
    return FarmerMini(
      id: json['id'],
      name: json['name'] ?? '',
      village: json['village'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

// ================= ORDER =================
class KsOrder {
  final int id;
  final String orderNo;
  final String status;
  final DateTime createdAt;
  final double grossSales;
  final double amountReceived;
  final FarmerMini? farmer;

  KsOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.createdAt,
    required this.grossSales,
    required this.amountReceived,
    this.farmer,
  });

  double get balance => grossSales - amountReceived;

  factory KsOrder.fromJson(Map<String, dynamic> json) {
    return KsOrder(
      id: json['id'],
      orderNo: json['order_no'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      grossSales: double.tryParse(json['gross_sales'].toString()) ?? 0.0,
      amountReceived:
          double.tryParse(json['amount_received'].toString()) ?? 0.0,
      farmer: json['farmer'] != null
          ? FarmerMini.fromJson(json['farmer'])
          : null,
    );
  }
}
