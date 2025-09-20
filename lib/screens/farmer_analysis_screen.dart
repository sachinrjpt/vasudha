import 'package:flutter/material.dart';

class FarmerAnalysisScreen extends StatelessWidget {
  final List<Map<String, String>> farmers = [
    {
      "sn": "1",
      "photo":
          "https://via.placeholder.com/50", // replace with your image URL
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
        title: const Text("Farmers Analysis"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal, // ✅ for desktop wide table
        child: DataTable(
          border: TableBorder.all(color: Colors.grey.shade300),
          headingRowColor:
              WidgetStateProperty.all(Colors.green.shade50), // header bg
          columns: const [
            DataColumn(label: Text("S/N")),
            DataColumn(label: Text("Photograph")),
            DataColumn(label: Text("Farmers")),
            DataColumn(label: Text("Phone")),
            DataColumn(label: Text("Pin Code")),
            DataColumn(label: Text("State")),
            DataColumn(label: Text("Village")),
            DataColumn(label: Text("Hamlet")),
            DataColumn(label: Text("Total Cultivable Land")),
            DataColumn(label: Text("Action")),
          ],
          rows: farmers.map((farmer) {
            return DataRow(
              cells: [
                DataCell(Text(farmer["sn"] ?? "-")),
                DataCell(
                  CircleAvatar(
                    backgroundImage: NetworkImage(farmer["photo"] ?? ""),
                    radius: 20,
                  ),
                ),
                DataCell(Text(farmer["name"] ?? "-")),
                DataCell(Text(farmer["phone"] ?? "-")),
                DataCell(Text(farmer["pincode"] ?? "-")),
                DataCell(Text(farmer["state"] ?? "-")),
                DataCell(Text(farmer["village"] ?? "-")),
                DataCell(Text(farmer["hamlet"] ?? "-")),
                DataCell(Text(farmer["land"] ?? "-")),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // TODO: Edit action here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Edit clicked")),
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
