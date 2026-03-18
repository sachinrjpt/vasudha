import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'farmer_info_screen.dart';
import 'section_a_screen.dart';
import 'costs_screen.dart';
import 'summary_screen.dart';
import 'krishi_sakhi_screen.dart';
import 'package:vasudha/widgets/auto_text.dart';

class FarmerWizard extends StatefulWidget {
  final String farmerId;
  final Map<String, dynamic>? moduleData;
  final bool isNewAudit;

  const FarmerWizard({
    super.key,
    required this.farmerId,
    this.moduleData,
    this.isNewAudit = false,
  });

  @override
  State<FarmerWizard> createState() => _FarmerWizardState();
}

class _FarmerWizardState extends State<FarmerWizard> {
  int _currentStep = 0;
  bool _isNext = true;

  late Future<Map<String, dynamic>> _moduleFuture;
  String selectedPlotId = "";
  late bool isAddMode;

  void _updatePlotId(String newPlotId) {
    setState(() {
      selectedPlotId = newPlotId;
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.moduleData != null) {
      // Agar moduleData pehle se available hai (preloaded), toh use Future me wrap karo
      _moduleFuture = Future.value(widget.moduleData);
    } else {
      // Nahi toh API call karo
      _moduleFuture = ApiService.getHarvestAuditModule(
        farmerId: int.parse(widget.farmerId),
      );
    }
  }

  void _nextStep(int totalSteps) {
    if (_currentStep < totalSteps - 1) {
      setState(() {
        _isNext = true;
        _currentStep++;
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _isNext = false;
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _moduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: AutoText(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!["ok"] != true) {
          return Scaffold(
            body: Center(
              child: AutoText(
                snapshot.data?["message"] ?? "Failed to load harvest module",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final module = snapshot.data!;

        final data = module["data"] ?? {};

        // 🔥 Detect Add / Edit Mode
        isAddMode = widget.isNewAudit;
        // Base Plot ID (FARM-000063 type)
        String basePlotId = "PLOT";

        if (data["plots"] != null && (data["plots"] as List).isNotEmpty) {
          basePlotId = data["plots"][0]["id"].toString();
        }

        // Existing audits count (for suffix A/B/C/D)
        int existingCount = 0;
        if (data["audits"] != null) {
          existingCount = (data["audits"] as List).length;
        }

        // Initialize selectedPlotId only once (important)
        if (selectedPlotId.isEmpty) {
          if (isAddMode) {
            String suffix = String.fromCharCode(65 + existingCount); // A,B,C,D
            selectedPlotId = "$basePlotId-$suffix";
          } else {
            selectedPlotId =
                data["audit"]?["plot_id"]?.toString() ?? basePlotId;
          }
        }

        // 🔥 Screens
        final screens = [
          FarmerInfoScreen(farmerId: widget.farmerId, moduleData: module),
          SectionAScreen(
            farmerId: widget.farmerId,
            moduleData: module,
            plotId: selectedPlotId,
            isAddMode: isAddMode,
            onPlotIdGenerated: _updatePlotId,
          ),
          CostsScreen(
            farmerId: widget.farmerId,
            plotId: selectedPlotId,
            moduleData: module,
            isAddMode: isAddMode,
          ),
          SummaryScreen(
            plotId: selectedPlotId, // ✅ pass plot id
            moduleData: module,
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Column(
              children: [
                // --- Step Indicator ---
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: List.generate(
                      screens.length,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? Colors.green
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Animated Screen ---
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(_isNext ? 1.0 : -1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    child: screens[_currentStep],
                  ),
                ),

                // --- Nav Buttons ---
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        ElevatedButton(
                          onPressed: _previousStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: AutoText("Previous"),
                        )
                      else
                        const SizedBox(),
                      ElevatedButton(
                        onPressed: () => _nextStep(screens.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: AutoText(
                          _currentStep < screens.length - 1 ? "Next" : "Finish",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
