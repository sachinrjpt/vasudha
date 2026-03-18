import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:vasudha/widgets/auto_text.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Map data;

  const AnnouncementDetailScreen({Key? key, required this.data})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoText("Announcement"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                AutoText(
                  data['created_at']?.toString().substring(0, 10) ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Html(data: data['message'] ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
