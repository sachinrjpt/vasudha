import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:vasudha/widgets/auto_text.dart';

class CustomSidebar extends StatelessWidget {
  final bool isDesktop;
  final String userType;
  final Function(String) onMenuSelected;

  const CustomSidebar({
    super.key,
    required this.isDesktop,
    required this.userType,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: isDesktop ? AppDimens.sidebarWidth : 280,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              alignment: Alignment.bottomLeft,
              child: AutoText(
                "Menu",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            // MENU LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  /// ===============================
                  /// 👩‍🌾 FARMER MENU
                  /// ===============================
                  if (userType == "farmer") ...[
                    _menuItem(
                      icon: Icons.cloud,
                      label: "Dashboard",
                      context: context,
                      onTap: () => onMenuSelected("Dashboard"),
                    ),
                    _menuItem(
                      icon: Icons.agriculture,
                      label: "Advisory",
                      context: context,
                      onTap: () => onMenuSelected("Advisory"),
                    ),
                    _menuItem(
                      icon: Icons.video_library,
                      label: "Video",
                      context: context,
                      onTap: () => onMenuSelected("Video"),
                    ),
                    _menuItem(
                      icon: Icons.wb_sunny,
                      label: "Weather Dashboard",
                      context: context,
                      onTap: () => onMenuSelected("Weather Dashboard"),
                    ),
                  ],

                  /// ===============================
                  /// 👩‍💼 EMPLOYEE MENU
                  /// ===============================
                  if (userType == "employee") ...[
                    _menuItem(
                      icon: Icons.dashboard,
                      label: "Dashboard",
                      context: context,
                      onTap: () => onMenuSelected("Dashboard"),
                    ),

                    _dropDownMenu(
                      icon: Icons.agriculture,
                      label: "Farmer",
                      children: [
                        _subItem(
                          label: "Registration",
                          context: context,
                          onTap: () => onMenuSelected("Registration"),
                        ),
                        _subItem(
                          label: "Farmer Lists",
                          context: context,
                          onTap: () => onMenuSelected("Farmer Lists"),
                        ),
                        _subItem(
                          label: "Advisory",
                          context: context,
                          onTap: () => onMenuSelected("Advisory"),
                        ),
                        _subItem(
                          label: "KS Sales Pad",
                          context: context,
                          onTap: () => onMenuSelected("KS Sales Pad"),
                        ),
                        _subItem(
                          label: "Video Library",
                          context: context,
                          onTap: () => onMenuSelected("Video Library"),
                        ),
                        _subItem(
                          label: "Weather Dashboard",
                          context: context,
                          onTap: () => onMenuSelected("Weather Dashboard"),
                        ),
                        _subItem(
                          label: "Harvest Audit",
                          context: context,
                          onTap: () => onMenuSelected("Harvest Audit"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MAIN MENU ITEM
  Widget _menuItem({
    required IconData icon,
    required String label,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        onTap();
        if (!isDesktop) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            AutoText(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // DROPDOWN MENU (EXPANSION)
  Widget _dropDownMenu({
    required IconData icon,
    required String label,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary),
        title: AutoText(label, style: const TextStyle(fontSize: 16)),
        childrenPadding: const EdgeInsets.only(left: 10, bottom: 8),
        children: children,
      ),
    );
  }

  // SUB MENU ITEM
  Widget _subItem({
    required String label,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 10),
      title: AutoText(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        onTap();
        if (!isDesktop) Navigator.pop(context);
      },
    );
  }
}
