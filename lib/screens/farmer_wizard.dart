import 'package:flutter/material.dart';
import 'farmer_info_screen.dart';
import 'section_a_screen.dart';
import 'costs_screen.dart';
import 'summary_screen.dart';
import 'krishi_sakhi_screen.dart'; // ✅ Add this

class FarmerWizard extends StatefulWidget {
  const FarmerWizard({super.key});

  @override
  State<FarmerWizard> createState() => _FarmerWizardState();
}

class _FarmerWizardState extends State<FarmerWizard> {
  int _currentStep = 0;
  bool _isNext = true; // ✅ track direction of slide

  final List<Widget> _screens = const [
    FarmerInfoScreen(),
    SectionAScreen(),
    CostsScreen(),
    SummaryScreen(),
  ];

  void _nextStep() {
    if (_currentStep < _screens.length - 1) {
      setState(() {
        _isNext = true;
        _currentStep++;
      });
    } else {
  // ✅ Last Step -> Go back to KrishiSakhiScreen
  Navigator.pop(context, true); // true = optional result for refresh
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
            // --- Top Step Indicator ---
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

            // --- Animated Screen Content ---
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
                child: _screens[_currentStep],
              ),
            ),

            // --- Navigation Buttons ---
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
                            horizontal: 24, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                        _currentStep < _screens.length - 1 ? "Next" : "Finish"),
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
