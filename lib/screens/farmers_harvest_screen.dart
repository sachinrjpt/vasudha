import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart'; // Add this import
import '../screens/farmer_wizard.dart';
import '../screens/farmer_dashboard_screen.dart';
import 'package:vasudha/widgets/auto_text.dart';

class FarmersHarvestScreen extends StatefulWidget {
  const FarmersHarvestScreen({Key? key}) : super(key: key);

  @override
  State<FarmersHarvestScreen> createState() => _FarmersHarvestScreenState();
}

class _FarmersHarvestScreenState extends State<FarmersHarvestScreen> {
  late Future<Map<String, dynamic>> _future;
  List farmers = [];
  List filteredFarmers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchFarmersHarvestList();

    _future.then((data) {
      if (data["ok"] == true) {
        farmers = data["farmers"];
        filteredFarmers = farmers;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoText("Harvest Audit – Farmers"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!["ok"] != true) {
            return Center(
              child: AutoText(
                snapshot.data?["message"] ?? "Failed to load data",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final farmers = snapshot.data!["farmers"] as List;

          if (farmers.isEmpty) {
            return const Center(child: AutoText("No farmers found"));
          }

          return Column(
            children: [
              /// SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchController,
                  onChanged: _searchFarmers,
                  decoration: InputDecoration(
                    hintText: "Search by Name or Mobile",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = ApiService.fetchFarmersHarvestList();
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredFarmers.length,
                    itemBuilder: (context, index) {
                      final farmer = filteredFarmers[index];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADER
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.green.shade100,
                                    child: AutoText(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AutoText(
                                      farmer["name"] ?? "-",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 20),

                              _infoRow("📞 Phone", farmer["phone"]),
                              _infoRow("🏞 State", farmer["state"]),
                              _infoRow("🏡 Village", farmer["village"]),
                              _infoRow("📍 Hamlet", farmer["halmet"]),

                              const SizedBox(height: 14),

                              /// ACTION BUTTONS
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blue, // 🔥 button color
                                        foregroundColor:
                                            Colors.white, // 🔥 text color
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FarmerWizard(
                                              farmerId: farmer["id"].toString(),
                                              moduleData: null,
                                              isNewAudit: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const AutoText("Add Audit"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      child: const AutoText("View Audits"),
                                      onPressed: () {
                                        _showAuditSheet(
                                          context,
                                          farmer["id"],
                                          farmer["name"] ?? "",
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: AutoText(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: AutoText(value?.isNotEmpty == true ? value! : "-")),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);

      if (date.isUtc) {
        date = date.toLocal();
      }

      return DateFormat("d/M/yyyy, h:mm a").format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _searchFarmers(String query) {
    final results = farmers.where((farmer) {
      final name = (farmer["name"] ?? "").toLowerCase();
      final phone = (farmer["phone"] ?? "").toLowerCase();

      return name.contains(query.toLowerCase()) || phone.contains(query);
    }).toList();

    setState(() {
      filteredFarmers = results;
    });
  }

  /// ================= BOTTOM SHEET (View Audits) =================
  void _showAuditSheet(BuildContext context, int farmerId, String farmerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getFarmerAudits(
              farmerId: farmerId,
            ), // Fetch audits here
            builder: (context, auditSnapshot) {
              if (auditSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!auditSnapshot.hasData || auditSnapshot.data!["ok"] != true) {
                return Center(
                  child: AutoText(
                    auditSnapshot.data?["message"] ?? "Failed to load audits",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final audits = auditSnapshot.data!["audits"] as List;

              if (audits.isEmpty) {
                return const Center(child: AutoText("No audits found"));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: audits.length,
                itemBuilder: (context, index) {
                  final audit = audits[index];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoText(
                            "Plot ID: ${audit["plot_id"] ?? "-"}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          AutoText("Date: ${_formatDate(audit["created_at"])}"),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                color: Colors.orange,
                                onPressed: () async {
                                  final auditId = audit["id"];

                                  final res =
                                      await ApiService.getEditHarvestAudit(
                                        auditId: auditId,
                                      );

                                  if (res["ok"] == true) {
                                    // 🔥 Convert edit API response into wizard-compatible moduleData
                                    final moduleData = {
                                      "ok": true,
                                      "data": {
                                        "audit": res["audit"],
                                        "farmer": res["farmer"],
                                        "plots": [
                                          {"id": res["audit"]["plot_id"]},
                                        ],
                                        "audits": [], // not needed in edit mode
                                      },
                                    };

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FarmerWizard(
                                          farmerId: res["farmer_id"].toString(),
                                          moduleData: moduleData,
                                          isNewAudit: false, // 🔥 IMPORTANT
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: AutoText(
                                          res["message"] ??
                                              "Failed to load audit",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.dashboard),
                                color: Colors.blue,
                                onPressed: () {
                                  final auditId = audit["id"];

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FarmerDashboardScreen(
                                        auditId: auditId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
