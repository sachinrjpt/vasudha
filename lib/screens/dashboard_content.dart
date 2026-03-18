import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vasudha/widgets/auto_text.dart';
import '../services/api_service.dart';
import 'announcement_detail_screen.dart';

class DashboardContent extends StatefulWidget {
  final String userType;

  const DashboardContent({Key? key, required this.userType}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? weatherData;
  List notifications = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    await fetchDashboard();
    await fetchWeatherWithLocation();
  }

  Future<void> fetchDashboard() async {
    final result = await ApiService.getDashboard();

    if (result['ok'] == true) {
      dashboardData = result['dashboard'] ?? {};
      notifications = result['notifications'] ?? [];
    } else {
      errorMessage = result['message'];
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchWeatherWithLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final result = await ApiService.getWeather(
        city: "${position.latitude},${position.longitude}",
      );

      if (result['ok'] == true) {
        setState(() {
          weatherData = {
            "location": result["location"],
            "current": result["current"],
          };
        });
      }
    } catch (_) {}
  }

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANT FIX
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: AutoText(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AutoText(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeatherSection() {
    if (weatherData == null ||
        weatherData!['location'] == null ||
        weatherData!['current'] == null) {
      return const AutoText("No weather data available");
    }

    final location = weatherData!['location'];
    final current = weatherData!['current'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4facfe), Color(0xff00f2fe)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (current['condition']?['icon'] != null)
            Image.network('https:${current['condition']['icon']}', width: 60),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoText(
                location['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AutoText(
                "${current['temp_c']} °C",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AutoText(
                current['condition']?['AutoText'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAnnouncements() {
    if (notifications.isEmpty) {
      return const AutoText("No announcements available");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AutoText(
          "Announcements",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...notifications.map((item) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnouncementDetailScreen(data: item),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoText(
                          item['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        AutoText(
                          item['created_at']?.toString().substring(0, 10) ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: AutoText(errorMessage!));
    }

    final d = dashboardData ?? {};
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    return RefreshIndicator(
      onRefresh: loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===============================
            /// 👩‍💼 EMPLOYEE DASHBOARD
            /// ===============================
            if (widget.userType != "farmer") ...[
              const AutoText(
                "Krishi Sakhi Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  buildStatCard(
                    "Total Farmers",
                    d['total_farmers']?.toString() ?? "0",
                    Icons.people,
                    Colors.green,
                  ),
                  buildStatCard(
                    "This Month Farmers",
                    d['monthly_farmers']?.toString() ?? "0",
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  buildStatCard(
                    "Orders Created",
                    d['orders_created']?.toString() ?? "0",
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                  buildStatCard(
                    "Orders Completed",
                    d['orders_completed']?.toString() ?? "0",
                    Icons.check_circle,
                    Colors.teal,
                  ),
                  buildStatCard(
                    "Total Sales (₹)",
                    d['total_sales']?.toString() ?? "0",
                    Icons.currency_rupee,
                    Colors.red,
                  ),
                  buildStatCard(
                    "Active Zones",
                    d['active_zones']?.toString() ?? "0",
                    Icons.location_on,
                    Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 25),
            ],

            /// ===============================
            /// 👩‍🌾 FARMER DASHBOARD TITLE
            /// ===============================
            if (widget.userType == "farmer") ...[
              const AutoText(
                "Farmer Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
            ],
            buildWeatherSection(),
            const SizedBox(height: 25),
            buildAnnouncements(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
