import 'package:flutter/material.dart';
import 'package:vasudha/widgets/auto_text.dart';

class FarmerAnalysisScreen extends StatelessWidget {
  final List<Map<String, String>> farmers = [
    {
      "sn": "1",
      "photo": "https://via.placeholder.com/50",
      "name": "kaka",
      "phone": "1234567895",
      "pincode": "201010",
      "state": "Uttar Pradesh",
      "village": "I.E.Sahibabad",
      "hamlet": "sdsf",
      "land": "60 acre",
    },
    {
      "sn": "2",
      "photo": "https://via.placeholder.com/50",
      "name": "Testing",
      "phone": "7777777777",
      "pincode": "380001",
      "state": "Gujarat",
      "village": "Ahmedabad",
      "hamlet": "Ahmedabad",
      "land": "406",
    },
    {
      "sn": "3",
      "photo": "https://via.placeholder.com/50",
      "name": "AQSWDEFGH",
      "phone": "1234567897",
      "pincode": "231208",
      "state": "Uttar Pradesh",
      "village": "Bairpur",
      "hamlet": "sdjcf",
      "land": "4.5 acre",
    },
  ];

  FarmerAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoText("Farmers Analysis"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal, // ✅ for desktop wide table
        child: DataTable(
          border: TableBorder.all(color: Colors.grey.shade300),
          headingRowColor: WidgetStateProperty.all(
            Colors.green.shade50,
          ), // header bg
          columns: const [
            DataColumn(label: AutoText("S/N")),
            DataColumn(label: AutoText("Photograph")),
            DataColumn(label: AutoText("Farmers")),
            DataColumn(label: AutoText("Phone")),
            DataColumn(label: AutoText("Pin Code")),
            DataColumn(label: AutoText("State")),
            DataColumn(label: AutoText("Village")),
            DataColumn(label: AutoText("Hamlet")),
            DataColumn(label: AutoText("Total Cultivable Land")),
            DataColumn(label: AutoText("Action")),
          ],
          rows: farmers.map((farmer) {
            return DataRow(
              cells: [
                DataCell(AutoText(farmer["sn"] ?? "-")),
                DataCell(
                  CircleAvatar(
                    backgroundImage: NetworkImage(farmer["photo"] ?? ""),
                    radius: 20,
                  ),
                ),
                DataCell(AutoText(farmer["name"] ?? "-")),
                DataCell(AutoText(farmer["phone"] ?? "-")),
                DataCell(AutoText(farmer["pincode"] ?? "-")),
                DataCell(AutoText(farmer["state"] ?? "-")),
                DataCell(AutoText(farmer["village"] ?? "-")),
                DataCell(AutoText(farmer["hamlet"] ?? "-")),
                DataCell(AutoText(farmer["land"] ?? "-")),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // TODO: Edit action here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: AutoText("Edit clicked")),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
