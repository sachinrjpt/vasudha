import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:vasudha/widgets/auto_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomHeader extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final bool isDesktop;
  final String userType;
  final Map<String, dynamic>? userData;

  const CustomHeader({
    super.key,
    this.onMenuPressed,
    required this.isDesktop,
    required this.userType, // add this
    this.userData,
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  String userName = "";
  String email = "";
  String phone = "";
  String imageUrl = "https://vasudha.app/assets/img/profiles/avatar-12.jpg";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoText(
                "Select Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _langItem("English", "en"),
              _langItem("Hindi", "hi"),
              _langItem("Gujarati", "gu"),
              _langItem("Marathi", "mr"),
              _langItem("Odia", "or"),
            ],
          ),
        );
      },
    );
  }

  Future<void> loadProfile() async {
    if (widget.userType == "farmer") {
      final d = widget.userData ?? {};

      if (d.isNotEmpty) {
        // If data is passed from login
        setState(() {
          userName = d["name"] ?? "Farmer";
          email = d["email"] ?? "";
          phone = d["phone"] ?? "";
          imageUrl = d["profile_image"] != null
              ? "https://vasudha.app/${d["profile_image"]}"
              : "https://vasudha.app/assets/img/profiles/avatar-12.jpg";
        });
      } else {
        // Try loading from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          userName = prefs.getString("farmerName") ?? "Farmer";
          email = prefs.getString("farmerEmail") ?? "";
          phone = prefs.getString("farmerPhone") ?? "";
          final img = prefs.getString("farmerImage") ?? "";
          imageUrl = img.isNotEmpty
              ? "https://vasudha.app/$img"
              : "https://vasudha.app/assets/img/profiles/avatar-12.jpg";
        });
      }
    } else {
      final res = await ApiService.getEmployeeProfile();
      if (res["ok"] == true) {
        final d = res["data"];
        setState(() {
          userName = d["name"] ?? "Employee";
          email = d["email"] ?? "";
          phone = d["phone"] ?? "";
          imageUrl =
              d["photo"]?.toString() ??
              "https://vasudha.app/assets/img/profiles/avatar-12.jpg";
        });
      }
    }
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(imageUrl),
                ),
                const SizedBox(height: 12),
                AutoText(
                  userName.isEmpty ? "User" : userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                AutoText(
                  email.isEmpty ? "No Email" : email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                AutoText(
                  phone.isEmpty ? "No Phone" : phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const Divider(),

                /// Dynamic options
                if (widget.userType == "employee") ...[
                  ListTile(
                    leading: const Icon(Icons.manage_accounts),
                    title: AutoText("Manage Farmers"),
                    onTap: () {},
                  ),
                ] else if (widget.userType == "farmer") ...[
                  ListTile(
                    leading: const Icon(Icons.agriculture),
                    title: AutoText("My Advisory"),
                    onTap: () {},
                  ),
                ],

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: AutoText("Logout"),
                  onTap: () async {
                    await StorageService.clearToken();

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove("isLoggedIn");
                    await prefs.remove("userType");

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top +
            6, // ↓ header को नीचे लाने वाला magic
        left: 12,
        right: 12,
      ),
      height: MediaQuery.of(context).padding.top + 66,
      color: AppColors.headerBg,

      child: Row(
        children: [
          if (!widget.isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              onPressed: widget.onMenuPressed,
            ),

          Image.asset("assets/logo.png", height: 40),
          const SizedBox(width: 10),

          Expanded(
            child: AutoText(
              "Utthan",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),

          IconButton(
            icon: const Icon(Icons.language, color: AppColors.primary),
            onPressed: _openLanguageSheet,
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: _openProfileSheet,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langItem(String title, String code) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: AutoText(title),
      onTap: () {
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).changeLanguage(code);

        Navigator.pop(context);
      },
    );
  }
}
