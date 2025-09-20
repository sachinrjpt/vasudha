import 'package:flutter/material.dart';

class FarmerInfoScreen extends StatelessWidget {
  const FarmerInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWide = screenWidth > 600; // Responsive

    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Analysis"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header with Title + DP ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Farmer Information",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage("assets/farmer.png"), 
                      // Agar network se photo load karna hai:
                      // backgroundImage: NetworkImage("https://example.com/photo.jpg"),
                      backgroundColor: Colors.grey[300],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Fields ---
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildTextField("Farmer Name"),
                    _buildTextField("Gender"),
                    _buildTextField("Mobile Number"),
                    _buildTextField("Email"),
                    _buildTextField("Pincode"),
                    _buildTextField("Village"),
                    _buildTextField("State"),
                    _buildTextField("District"),
                    _buildTextField("Block"),
                    _buildTextField("Hamlet"),
                    _buildTextField("Total cultivable land owned by the family"),
                    SizedBox(
                      width: isWide ? 800 : double.infinity,
                      child: _buildTextField("Address", maxLines: 3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Reusable Field Builder ---
  Widget _buildTextField(String label, {int maxLines = 1}) {
    return SizedBox(
      width: 350,
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
