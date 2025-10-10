import 'package:flutter/material.dart';
import 'farmer_info_screen.dart';
import 'section_a_screen.dart';
import 'costs_screen.dart';
import 'summary_screen.dart';
import 'krishi_sakhi_screen.dart';

class FarmerWizard extends StatefulWidget {
   final String farmerId; // ✅ Farmer ID pass karni hogi

  const FarmerWizard({super.key, required this.farmerId});

  @override
  State<FarmerWizard> createState() => _FarmerWizardState();
}

class _FarmerWizardState extends State<FarmerWizard> {
  int _currentStep = 0;
  bool _isNext = true;

  late final List<Widget> _screens; // ✅ ab late init karenge

  @override
  void initState() {
    super.initState();

    // ✅ yaha id inject karenge
    _screens = [
      FarmerInfoScreen(farmerId: widget.farmerId),
      SectionAScreen(farmerId: widget.farmerId),

      CostsScreen(farmerId: widget.farmerId),

      SummaryScreen(farmerId: widget.farmerId),
    ];
  }

  void _nextStep() {
    if (_currentStep < _screens.length - 1) {
      setState(() {
        _isNext = true;
        _currentStep++;
      });
    } else {
      // ✅ Last step → Back to KrishiSakhiScreen
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // --- Step Indicator ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _screens.length,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? Colors.green : Colors.grey[300],
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
                  return SlideTransition(position: offsetAnimation, child: child);
                },
                child: _screens[_currentStep],
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Previous"),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_currentStep < _screens.length - 1 ? "Next" : "Finish"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
