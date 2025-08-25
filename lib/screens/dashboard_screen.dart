import 'package:flutter/material.dart';
import '../widgets/custom_sidebar.dart';
import '../widgets/custom_header.dart';
import '../utils/constants.dart';
import 'farmer_registration_screen.dart';
import 'krishi_sakhi_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _selectedContent = const Center(
    child: Text(
      "Main Content Area",
      style: TextStyle(fontSize: 20),
    ),
  );

  void _onMenuSelected(String title) {
  setState(() {
    if (title == "Registration") {
      _selectedContent = const RegistrationForm();
    } else if (title == "Dashboard") {
      _selectedContent = const Center(
        child: Text(
          "Main Content Area",
          style: TextStyle(fontSize: 20),
        ),
      );
    } else if (title == "Farmer Lists") {
      _selectedContent = const KrishiSakhiScreen();
    } else if (title == "Employee Type") {
      _selectedContent = const Center(child: Text("Employee Type Page"));
    }
  });
}


  @override
  Widget build(BuildContext context) {
    bool isDesktop = context.isDesktop;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop
          ? CustomSidebar(
              isDesktop: isDesktop,
              onMenuSelected: _onMenuSelected,
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            CustomSidebar(
              isDesktop: isDesktop,
              onMenuSelected: _onMenuSelected,
            ),
          Expanded(
            child: Column(
              children: [
                CustomHeader(
                  isDesktop: isDesktop,
                  onMenuPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
                Expanded(child: _selectedContent),
              ],
            ),
          )
        ],
      ),
    );
  }
}
