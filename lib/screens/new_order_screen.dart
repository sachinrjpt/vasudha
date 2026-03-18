import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:vasudha/widgets/auto_text.dart';

class NewOrderScreen extends StatefulWidget {
  final int? orderId; // 👈 null = create, not null = edit

  const NewOrderScreen({super.key, this.orderId});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  // ---------------- STATE ----------------
  bool loading = true;

  String autoOrderNo = '';
  String ksName = '';
  String ksPhone = '';

  List<dynamic> farmers = [];
  List<dynamic> crops = [];
  List<dynamic> inputNames = [];
  List<dynamic> inputTypes = [];
  List<dynamic> unitTypes = [];

  int? selectedFarmerId;
  int? selectedCropId;
  String? selectedPlace;
  String? selectedAreaUnit;
  String? selectedPaymentMode;
  String selectedVillage = '';
  String selectedPhone = '';

  final areaController = TextEditingController();
  final areaUnitController = TextEditingController();
  final timeWindowController = TextEditingController();
  final amountReceivedController = TextEditingController();
  final ksNotesController = TextEditingController();
  final paymentNotesController = TextEditingController();
  final deliveryDateController = TextEditingController();

  DateTime? deliveryDate;

  List<Map<String, dynamic>> orderLines = [
    {"type": null, "item_id": null, "qty": "", "unit": null, "rate": ""},
  ];
  bool get isEdit => widget.orderId != null;
  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();

    if (isEdit) {
      _loadEditData();
    } else {
      _loadSaleData(); // existing create flow
    }
  }

  Future<void> _loadSaleData() async {
    final res = await ApiService.getKsSaleData();

    if (res["ok"] == true) {
      setState(() {
        autoOrderNo = res["auto_order_no"] ?? '';
        ksName = res["ks"]["name"] ?? '';
        ksPhone = res["ks"]["phone"] ?? '';

        farmers = res["farmers"];
        crops = res["crops"];
        inputNames = res["input_names"];
        inputTypes = res["input_types"];
        unitTypes = res["unit_types"];

        loading = false;
      });
    } else {
      loading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText(res["message"] ?? "Failed to load data")),
      );
    }
  }

  Future<void> _loadEditData() async {
    final res = await ApiService.editKsSale(orderId: widget.orderId!);

    if (res["ok"] == true) {
      final order = res["order"];

      setState(() {
        // 🔹 Header
        autoOrderNo = order["order_no"] ?? '';
        ksName = res["ks"]["name"] ?? '';
        ksPhone = res["ks"]["phone"] ?? '';

        // 🔹 Master data
        farmers = res["farmers"];
        crops = res["crops"];
        inputNames = res["input_names"];
        inputTypes = res["input_types"];
        unitTypes = res["unit_types"];

        // 🔹 Selected values
        selectedFarmerId = order["farmer_id"];
        selectedCropId = order["crop_id"];
        selectedPlace = order["place"];
        selectedPaymentMode = order["payment_mode"];

        areaController.text = order["area"] ?? '';
        selectedAreaUnit = order["area_unit"];
        timeWindowController.text = order["time_window"] ?? '';
        ksNotesController.text = order["ks_notes"] ?? '';
        paymentNotesController.text = order["notes"] ?? '';
        amountReceivedController.text = (order["amount_received"] ?? '')
            .toString();

        // 🔹 Delivery date
        if (order["delivery_date"] != null) {
          deliveryDate = DateTime.parse(order["delivery_date"]);
          deliveryDateController.text = DateFormat(
            'dd-MM-yyyy',
          ).format(deliveryDate!);
        }

        // 🔹 Farmer extra info
        final f = farmers.firstWhere(
          (e) => e["id"] == selectedFarmerId,
          orElse: () => null,
        );
        if (f != null) {
          selectedVillage = f["village"] ?? '';
          selectedPhone = f["phone"] ?? '';
        }

        // 🔹 Order lines
        orderLines = (order["lines"] as List)
            .map<Map<String, dynamic>>(
              (l) => {
                "type": l["type"],
                "item_id": l["item_id"],
                "item_name": l["item_name"],
                "qty": l["qty"].toString(),
                "unit": l["unit"],
                "rate": l["rate"].toString(),
              },
            )
            .toList();

        loading = false;
      });
    } else {
      loading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText(res["message"] ?? "Failed to load order")),
      );
    }
  }

  Future<void> _pickDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: deliveryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        deliveryDate = picked;
        deliveryDateController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(picked); // web jaisa format
      });
    }
  }

  // ---------------- CALC ----------------
  double get grossSales {
    double total = 0;
    for (var l in orderLines) {
      final qty = double.tryParse(l["qty"].toString()) ?? 0;
      final rate = double.tryParse(l["rate"].toString()) ?? 0;
      final unit = l["unit"]?.toString() ?? "";

      if (unit.toLowerCase() == "mund") {
        total += qty * rate * 20; // 👈 Mund special multiplier
      } else {
        total += qty * rate;
      }
    }
    return total;
  }

  double get balance {
    final received = double.tryParse(amountReceivedController.text) ?? 0;
    return grossSales - received;
  }

  // ---------------- SAVE ----------------
  Future<void> _saveOrder() async {
    if (selectedFarmerId == null || selectedCropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AutoText("Select farmer and crop")),
      );
      return;
    }

    final payload = {
      "farmerId": selectedFarmerId!,
      "cropId": selectedCropId!,
      "area": areaController.text,
      "areaUnit": selectedAreaUnit,
      "deliveryDate": deliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(deliveryDate!)
          : null,
      "timeWindow": timeWindowController.text,
      "place": selectedPlace,
      "amountReceived": double.tryParse(amountReceivedController.text),
      "paymentMode": selectedPaymentMode,
      "notes": paymentNotesController.text, // Payment notes
      "ksNotes": ksNotesController.text, // Supplier (KS) notes
      "lines": orderLines,
    };

    final res = isEdit
        ? await ApiService.updateKsSale(
            orderId: widget.orderId!,
            farmerId: payload["farmerId"] as int,
            cropId: payload["cropId"] as int,
            area: payload["area"] as String?,
            areaUnit: payload["areaUnit"] as String?,
            deliveryDate: payload["deliveryDate"] as String?,
            timeWindow: payload["timeWindow"] as String?,
            place: payload["place"] as String?,
            amountReceived: payload["amountReceived"] as double?,
            paymentMode: payload["paymentMode"] as String?,
            notes: paymentNotesController.text, // ✅ payment notes
            ksNotes: ksNotesController.text, // ✅ supplier notes
            lines: orderLines,
          )
        : await ApiService.storeKsSale(
            farmerId: payload["farmerId"] as int,
            cropId: payload["cropId"] as int,
            area: payload["area"] as String?,
            areaUnit: payload["areaUnit"] as String?,
            deliveryDate: payload["deliveryDate"] as String?,
            timeWindow: payload["timeWindow"] as String?,
            place: payload["place"] as String?,
            amountReceived: payload["amountReceived"] as double?,
            paymentMode: payload["paymentMode"] as String?,
            notes: paymentNotesController.text, // ✅ payment notes
            ksNotes: ksNotesController.text, // ✅ supplier notes
            lines: orderLines,
          );

    if (res["ok"] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText(res["message"] ?? "Operation failed")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: AutoText(isEdit ? "Edit Order" : "New Order")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Order Info"),
            _readonly("Order No", autoOrderNo),
            _statusChip(),
            _readonly(
              "Created",
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            ),

            _section("Customer (Farmer)"),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                label: AutoText("Farmer"),
                border: const OutlineInputBorder(),
              ),
              value: selectedFarmerId,
              items: farmers.map<DropdownMenuItem<int>>((farmer) {
                return DropdownMenuItem<int>(
                  value: farmer["id"], // unique id as value
                  child: AutoText(farmer["name"].toString()),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  selectedFarmerId = val;
                  final f = farmers.firstWhere((e) => e["id"] == val);
                  selectedVillage = f["village"] ?? '';
                  selectedPhone = f["phone"] ?? '';
                });
              },
            ),
            _readonly("Village", selectedVillage),
            _readonly("Mobile", selectedPhone),
            _dropdown(
              "Crop",
              crops.map((e) => e["crops"].toString()).toList(),
              value: selectedCropId == null
                  ? null
                  : crops
                        .firstWhere((e) => e["id"] == selectedCropId)["crops"]
                        .toString(),
              onChanged: (val) {
                final c = crops.firstWhere((e) => e["crops"] == val);
                selectedCropId = c["id"];
              },
            ),
            _text("Area", controller: areaController),
            _dropdown(
              "Area Unit",
              unitTypes.map((e) => e["unit_type"].toString()).toList(),
              value: selectedAreaUnit,
              onChanged: (v) {
                setState(() {
                  selectedAreaUnit = v;
                });
              },
            ),

            _section("Order Lines"),
            _orderLinesUI(),

            _section("Delivery / Service"),
            GestureDetector(
              onTap: _pickDeliveryDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: deliveryDateController,
                  decoration: const InputDecoration(
                    label: AutoText("Delivery / Service Date"),
                    hint: AutoText("dd-mm-yyyy"),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _text("Time Window", controller: timeWindowController),
            _dropdown(
              "Place",
              ["Farm", "Warehouse"],
              value: selectedPlace,
              onChanged: (v) => setState(() => selectedPlace = v),
            ),

            _section("Supplier (KS)"),
            _readonly("KS Name", ksName),
            _readonly("KS Phone", ksPhone),
            _text("Notes", controller: ksNotesController),

            _section("Payment"),
            _readonly("Gross Sales", grossSales.toStringAsFixed(2)),
            _text("Amount Received", controller: amountReceivedController),
            _readonly("Balance", balance.toStringAsFixed(2)),
            _text("Payment Notes", controller: paymentNotesController),
            _dropdown(
              "Payment Mode",
              ["Cash", "UPI", "Bank Transfer"],
              value: selectedPaymentMode,
              onChanged: (v) => setState(() => selectedPaymentMode = v),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveOrder,
                child: AutoText(isEdit ? "Update Order" : "Save Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ORDER LINES ----------------
  Widget _orderLinesUI() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoText(
              "Gross Sales: ₹${grossSales.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 12),
            ),
            AutoText(
              "Lines: ${orderLines.length}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(orderLines.length, (index) {
          final line = orderLines[index];
          final qty = double.tryParse(line["qty"].toString()) ?? 0;
          final rate = double.tryParse(line["rate"].toString()) ?? 0;
          final unit = line["unit"]?.toString() ?? "";

          double lineTotal = unit.toLowerCase() == "mund"
              ? qty * rate * 20
              : qty * rate;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _dropdown(
                    "Type",
                    inputTypes.map((e) => e["input_types"].toString()).toList(),
                    value: line["type"],
                    onChanged: (v) => setState(() => line["type"] = v),
                  ),
                  _dropdown(
                    "Item",
                    inputNames.map((e) => e["input_name"].toString()).toList(),
                    value: inputNames.firstWhere(
                      (e) => e["id"] == line["item_id"],
                      orElse: () => null,
                    )?["input_name"],
                    onChanged: (v) {
                      final i = inputNames.firstWhere(
                        (e) => e["input_name"] == v,
                      );
                      setState(() => line["item_id"] = i["id"]);
                    },
                  ),
                  _text(
                    "Qty",
                    onChanged: (v) => setState(() => line["qty"] = v),
                  ),
                  _dropdown(
                    "Unit",
                    unitTypes.map((e) => e["unit_type"].toString()).toList(),
                    value: line["unit"],
                    onChanged: (v) => setState(() => line["unit"] = v),
                  ),
                  _text(
                    "Rate",
                    onChanged: (v) => setState(() => line["rate"] = v),
                  ),
                  _readonly("Total", lineTotal.toStringAsFixed(2)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() => orderLines.removeAt(index));
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              orderLines.add({
                "type": null,
                "item_id": null,
                "qty": "",
                "unit": null,
                "rate": "",
              });
            });
          },
          icon: const Icon(Icons.add),
          label: const AutoText("Add Line"),
        ),
      ],
    );
  }

  // ---------------- HELPERS (UI SAME) ----------------
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: AutoText(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _text(
    String label, {
    TextEditingController? controller,
    Function(String)? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        label: AutoText(label),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _readonly(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        label: AutoText(label),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _dropdown(
    String label,
    List<String> items, {
    String? value,
    Function(String?)? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        label: AutoText(label),
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: AutoText(e)))
          .toList(),
      onChanged: onChanged,
    ),
  );

  Widget _statusChip() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.green,
      borderRadius: BorderRadius.circular(4),
    ),
    child: AutoText(
      isEdit ? "Editing Order" : "Order Booked",
      style: const TextStyle(color: Colors.white),
    ),
  );
}
