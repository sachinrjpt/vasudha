import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vasudha/widgets/auto_text.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

import '../services/api_service.dart';

class WeatherDashboardScreen extends StatefulWidget {
  const WeatherDashboardScreen({super.key});

  @override
  State<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends State<WeatherDashboardScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String searchCity = "";

  @override
  void initState() {
    super.initState();
    _loadByLocation();
  }

  // 📍 Auto GPS Location
  Future<void> _loadByLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Enable location services");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: "Location permission permanently denied");
        return;
      }

      Position pos = await Geolocator.getCurrentPosition();

      await loadWeather(city: "${pos.latitude},${pos.longitude}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Location error");
    }
  }

  // 🌦 Load Weather
  Future<void> loadWeather({String? city}) async {
    setState(() => isLoading = true);

    final result = await ApiService.getWeather(city: city);

    if (result["ok"] == true) {
      setState(() {
        weatherData = result;
        isLoading = false;
      });
    } else {
      isLoading = false;
      Fluttertoast.showToast(msg: result["message"] ?? "Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const AutoText(
          'Weather Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData == null
          ? const Center(child: AutoText("No weather data"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _searchBar(),
                  const SizedBox(height: 16),
                  _currentWeatherCard(size),
                  const SizedBox(height: 24),
                  const AutoText(
                    '3 Day Forecast',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _forecastList(),
                ],
              ),
            ),
    );
  }

  // 🔍 Search Bar
  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<String>(
            future: context.read<LanguageProvider>().translate(
              'Search city or state',
            ),
            builder: (context, snapshot) {
              final hint = snapshot.data ?? 'Search city or state';
              return TextField(
                onChanged: (v) => searchCity = v,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            if (searchCity.isEmpty) {
              final msg = await context.read<LanguageProvider>().translate(
                "Enter city name",
              );
              Fluttertoast.showToast(msg: msg);
              return;
            }
            loadWeather(city: searchCity);
          },
          child: const Icon(Icons.search, color: Colors.white),
        ),
      ],
    );
  }

  // ☀ Current Card
  Widget _currentWeatherCard(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoText(
                    "${weatherData!["location"]["name"]}, ${weatherData!["location"]["region"]}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoText(
                    weatherData!["current"]["condition"]["text"],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              // 🌤 API ICON
              CachedNetworkImage(
                imageUrl:
                    "https:${weatherData!["current"]["condition"]["icon"]}",
                width: 48,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoTile(
                label: 'Temp',
                value: "${weatherData!["current"]["temp_c"]}°C",
              ),
              _InfoTile(
                label: 'Humidity',
                value: "${weatherData!["current"]["humidity"]}%",
              ),
              _InfoTile(
                label: 'Wind',
                value: "${weatherData!["current"]["wind_kph"]} km/h",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📆 Forecast
  Widget _forecastList() {
    final List days = weatherData!["forecast"];

    return Column(
      children: days.map((day) {
        return _ForecastTile(
          date: day["date"],
          min: "${day["day"]["mintemp_c"]}°C",
          max: "${day["day"]["maxtemp_c"]}°C",
          icon: Icons.wb_sunny,
          condition: day["day"]["condition"]["text"],
        );
      }).toList(),
    );
  }
}

// ----------------------

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AutoText(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        AutoText(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final String date;
  final String min;
  final String max;
  final IconData icon;
  final String condition;

  const _ForecastTile({
    required this.date,
    required this.min,
    required this.max,
    required this.icon,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoText(
                date,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              AutoText(condition, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              AutoText('$min / $max'),
              const SizedBox(width: 12),
              Icon(icon, color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}
