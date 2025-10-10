import 'package:flutter/material.dart';
import '../services/api_service.dart'; // adjust path if needed

class FarmerInfoScreen extends StatefulWidget {
  final String farmerId;
  const FarmerInfoScreen({super.key, required this.farmerId});

  @override
  State<FarmerInfoScreen> createState() => _FarmerInfoScreenState();
}

class _FarmerInfoScreenState extends State<FarmerInfoScreen> {
  // controllers
  final nameController = TextEditingController();
  final genderController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final zipController = TextEditingController();
  final villageController = TextEditingController();
  final stateController = TextEditingController();
  final districtController = TextEditingController();
  final blockController = TextEditingController();
  final hamletController = TextEditingController();
  final landAreaController = TextEditingController();
  final addressController = TextEditingController();

  String? profileImageUrl;
  bool loading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchFarmer();
  }

  @override
  void dispose() {
    nameController.dispose();
    genderController.dispose();
    phoneController.dispose();
    emailController.dispose();
    zipController.dispose();
    villageController.dispose();
    stateController.dispose();
    districtController.dispose();
    blockController.dispose();
    hamletController.dispose();
    landAreaController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchFarmer() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final res = await ApiService.getEmployeeById(widget.farmerId);


      if (res['status'] == "success") {
        final Map<String, dynamic> emp = Map<String, dynamic>.from(res['data'] ?? {});

        setState(() {
          nameController.text = emp['name']?.toString() ?? '';
          genderController.text = emp['gender']?.toString() ?? '';
          phoneController.text = emp['phone']?.toString() ?? '';
          emailController.text = emp['email']?.toString() ?? '';
          zipController.text = emp['zip_code']?.toString() ?? '';
          villageController.text = emp['village']?.toString() ?? '';
          stateController.text = emp['state']?.toString() ?? '';
          districtController.text = emp['district']?.toString() ?? '';
          blockController.text = emp['block']?.toString() ?? '';
          hamletController.text = emp['halmet']?.toString() ?? '';
          landAreaController.text = emp['land_area']?.toString() ?? '';
          addressController.text = emp['address']?.toString() ?? '';

          profileImageUrl = emp['profile_image']?.toString();
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = res['message'] ?? 'Failed to load farmer';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = 'Error: $e';
      });
    }
  }

  Widget _profileAvatar() {
    final imageProvider = (profileImageUrl != null && profileImageUrl!.isNotEmpty)
        ? NetworkImage(profileImageUrl!)
        : const AssetImage('assets/farmer.png') as ImageProvider;

    return CircleAvatar(
      radius: 36,
      backgroundImage: imageProvider,
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, {int maxLines = 1}) {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWide = screenWidth > 600;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Information"),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFarmer,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: errorMsg != null
                ? Column(
                    children: [
                      Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchFarmer,
                        child: const Text('Retry'),
                      )
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Farmer Information",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          _profileAvatar(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Fields
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildReadOnlyField("Farmer Name", nameController),
                          _buildReadOnlyField("Gender", genderController),
                          _buildReadOnlyField("Mobile Number", phoneController),
                          _buildReadOnlyField("Email", emailController),
                          _buildReadOnlyField("Pincode", zipController),
                          _buildReadOnlyField("Village", villageController),
                          _buildReadOnlyField("State", stateController),
                          _buildReadOnlyField("District", districtController),
                          _buildReadOnlyField("Block", blockController),
                          _buildReadOnlyField("Hamlet", hamletController),
                          _buildReadOnlyField("Total cultivable land owned by the family", landAreaController),
                          SizedBox(
                            width: isWide ? 800 : double.infinity,
                            child: _buildReadOnlyField("Address", addressController, maxLines: 3),
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
}
