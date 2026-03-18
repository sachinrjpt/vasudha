import 'package:flutter/material.dart';
import '../widgets/custom_sidebar.dart';
import '../widgets/custom_header.dart';
import '../utils/constants.dart';
import 'farmer_registration_screen.dart';
import 'krishi_sakhi_screen.dart';
import 'farmer_analysis_screen.dart';
import 'advisory_screen.dart';
import 'search_crop_videos_screen.dart';
import 'weather_dashboard_screen.dart';
import 'farmers_harvest_screen.dart';
import 'dashboard_content.dart';
import 'kssales_pad.dart';

class DashboardScreen extends StatefulWidget {
  final String userType;
  final Map<String, dynamic>? userData; // Farmer profile

  const DashboardScreen({super.key, required this.userType, this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Widget _selectedContent;

  @override
  void initState() {
    super.initState();

    /// Default screen based on user role
    _selectedContent = DashboardContent(userType: widget.userType);
  }

  void _onMenuSelected(String title) {
    setState(() {
      /// =========================
      /// 👩‍🌾 FARMER ACCESS
      /// =========================
      if (widget.userType == "farmer") {
        switch (title) {
          case "Dashboard":
            _selectedContent = DashboardContent(
              userType: widget.userType,
            ); // shows notifications + weather
            break;
          case "Weather Dashboard": // <-- sidebar label ke saath match
            _selectedContent = const WeatherDashboardScreen();
            break;

          case "Advisory":
            _selectedContent = const AdvisoryScreen();
            break;

          case "Video":
            _selectedContent = const SearchCropVideosScreen();
            break;

          default:
            _selectedContent = const WeatherDashboardScreen();
        }
      }
      /// =========================
      /// 👩‍💼 EMPLOYEE ACCESS
      /// =========================
      else {
        switch (title) {
          case "Dashboard":
            _selectedContent = DashboardContent(userType: widget.userType);
            break;

          case "Registration":
            _selectedContent = const RegistrationForm();
            break;

          case "Farmer Lists":
            _selectedContent = const KrishiSakhiScreen();
            break;

          case "Farmer Analysis List":
            _selectedContent = FarmerAnalysisScreen();
            break;

          case "Advisory":
            _selectedContent = const AdvisoryScreen();
            break;

          case "KS Sales Pad":
            _selectedContent = const KSSalesPad();
            break;

          case "Video Library":
            _selectedContent = const SearchCropVideosScreen();
            break;

          case "Weather Dashboard":
            _selectedContent = const WeatherDashboardScreen();
            break;

          case "Harvest Audit":
            _selectedContent = const FarmersHarvestScreen();
            break;

          default:
            _selectedContent = DashboardContent(userType: widget.userType);
        }
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
              userType: widget.userType,
              onMenuSelected: _onMenuSelected,
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            CustomSidebar(
              isDesktop: isDesktop,
              userType: widget.userType,
              onMenuSelected: _onMenuSelected,
            ),
          Expanded(
            child: Column(
              children: [
                CustomHeader(
                  isDesktop: isDesktop,
                  userType: widget.userType,
                  userData: widget.userData, // farmer profile
                  onMenuPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
                Expanded(child: _selectedContent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
