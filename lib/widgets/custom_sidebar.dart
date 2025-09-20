import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomSidebar extends StatelessWidget {
  final bool isDesktop;
  final Function(String) onMenuSelected;

  const CustomSidebar({
    super.key,
    required this.isDesktop,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: isDesktop ? AppDimens.sidebarWidth : null,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary, // ✅ use brand green instead of orange
            ),
            child: Text(
              "Menu",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),

          // Dashboard FIRST
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.primary),
            title: const Text("Dashboard"),
            onTap: () {
              onMenuSelected("Dashboard");
              if (!isDesktop) Navigator.pop(context);
            },
          ),

          // Farmer (dropdown SECOND)
          ExpansionTile(
            leading: const Icon(Icons.agriculture, color: AppColors.primary),
            title: const Text("Farmer"),
            children: [
              // Registration comes FIRST inside Farmer
              ListTile(
                title: const Text("Registration"),
                onTap: () {
                  onMenuSelected("Registration");
                  if (!isDesktop) Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Farmer Lists"),
                onTap: () {
                  onMenuSelected("Farmer Lists");
                  if (!isDesktop) Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Farmer Analysis List"),
                onTap: () {
                  onMenuSelected("Farmer Analysis List");
                  if (!isDesktop) Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
