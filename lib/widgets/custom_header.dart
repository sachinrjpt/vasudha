import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final bool isDesktop;

  const CustomHeader({
    super.key,
    this.onMenuPressed,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.headerHeight,
      color: AppColors.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              onPressed: onMenuPressed,
            ),
          Image.asset(
            "assets/logo.png",
            height: 40,
          ),
          const SizedBox(width: 10),

          // Title wrapped with Expanded
          Expanded(
            child: Text(
              "Utthan",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis, // Prevents overflow
            ),
          ),

          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundImage: NetworkImage(
              "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
            ),
          ),
        ],
      ),
    );
  }
}
