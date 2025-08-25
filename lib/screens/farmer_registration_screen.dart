import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _landAreaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _hamletController = TextEditingController();

  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _selectedGender;

  // Village list
  List<dynamic> _villageList = [];
  String? _selectedVillage;

  Future<void> _pickImage() async {
    if (kIsWeb) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _profileImageBytes = result.files.first.bytes!;
        });
      }
    } else {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Select Image Source"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text("Camera"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text("Gallery"),
            ),
          ],
        ),
      );

      if (source == null) return;

      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
      }
    }
  }

  // Fetch villages by pincode
  Future<void> _fetchVillages(String pinCode) async {
    if (pinCode.length == 6) {
      final result = await ApiService.getVillagesByPincode(pinCode);
      debugPrint("API Response: $result");
      if (result["status"] == "success" && result["data"] is List) {
        setState(() {
          _villageList = result["data"];
          debugPrint("Village List Updated: $_villageList");
          _selectedVillage = null;
          _villageController.clear();
          _districtController.clear();
          _stateController.clear();
          _blockController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"] ?? "No villages found")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile image upload
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: kIsWeb
                                ? (_profileImageBytes != null
                                    ? MemoryImage(_profileImageBytes!)
                                    : const NetworkImage(
                                        "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                                      ) as ImageProvider)
                                : (_profileImageFile != null
                                    ? FileImage(_profileImageFile!)
                                    : const NetworkImage(
                                        "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                                      ) as ImageProvider),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Upload Profile Image",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 200,
                                child: OutlinedButton(
                                  onPressed: _pickImage,
                                  child: const Text("Choose File"),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 30),

                      LayoutBuilder(builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 700;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildTextField("Name *", isWide,
                                controller: _nameController),
                            _buildTextField("Mobile Number *", isWide,
                                controller: _mobileController),
                            _buildTextField("Email *", isWide,
                                controller: _emailController),
                            _buildDropdown("Gender *", isWide),

                            // 🔹 Pin Code field
                            SizedBox(
                              width: isWide ? 450 : double.infinity,
                              child: TextFormField(
                                controller: _zipCodeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: "Pin Code *",
                                  border: OutlineInputBorder(),
                                  counterText: "",
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) {
                                  if (val.length == 6) {
                                    _fetchVillages(val);
                                  }
                                },
                                validator: (value) => (value == null || value.isEmpty)
                                    ? "Required"
                                    : null,
                              ),
                            ),

                            SizedBox(
                              width: isWide ? 450 : double.infinity,
                              child: DropdownButtonFormField<String>(
                                value: _selectedVillage,
                                decoration: const InputDecoration(
                                  labelText: "Village *",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                items: _villageList
                                    .map<DropdownMenuItem<String>>((v) {
                                  final villageName = v["Name"] ?? "Unknown";
                                  return DropdownMenuItem(
                                    value: villageName,
                                    child: Text(villageName),
                                  );
                                }).toList(),
                                onChanged: (val) {
  final match = _villageList.firstWhere(
    (e) => e["Name"] == val,
    orElse: () => {
      "District": "",
      "State": "",
      "Block": "",
      "Pincode": ""
    },
  );

  setState(() {
    _selectedVillage = val;
    _villageController.text = val ?? "";

    _districtController.text = match["District"] ?? "";
    _stateController.text = match["State"] ?? "";
    _blockController.text = match["Block"] ?? "";
    _zipCodeController.text = match["Pincode"] ?? "";
  });
},

                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? "Required"
                                        : null,
                              ),
                            ),

                            _buildTextField("Address *", isWide,
                                controller: _addressController),

                            // District/State/Block auto-fill
                            _buildTextField("District *", isWide,
                                controller: _districtController, readOnly: true),
                            _buildTextField("State *", isWide,
                                controller: _stateController, readOnly: true),
                            _buildTextField("Block *", isWide,
                                controller: _blockController, readOnly: true),

                            // 🔹 Village dropdown (single copy only)
                            

                            _buildTextField("Land Area *", isWide,
                                controller: _landAreaController),
                            _buildTextField("Hamlet *", isWide,
                                controller: _hamletController),
                            _buildTextField("Password *", isWide,
                                controller: _passwordController,
                                obscure: true),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white),
                            onPressed: () async {
  if (_formKey.currentState!.validate()) {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService.storeEmployee(
      name: _nameController.text,
      phone: _mobileController.text,   // ✅ phone not mobile
      email: _emailController.text,
      password: _passwordController.text,
      zipCode: _zipCodeController.text,
      state: _stateController.text,     // ✅ new
      district: _districtController.text, // ✅ new
      block: _blockController.text,       // ✅ new
      village: _villageController.text,   // ✅ new
      halmet: _hamletController.text,     // ✅ new
      address: _addressController.text,   // ✅ new
      landArea: _landAreaController.text,
      profileImageBytes: _profileImageBytes,
      profileImageFile: _profileImageFile,
    );

    Navigator.pop(context); // Close loading

    if (result['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee added successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? "Failed to add employee",
          ),
        ),
      );
    }
  }
},

                            child: const Text("Save"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable text field
  Widget _buildTextField(String label, bool isWide,
      {bool obscure = false,
      bool readOnly = false,
      TextEditingController? controller}) {
    return SizedBox(
      width: isWide ? 450 : double.infinity,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  // Gender dropdown
  Widget _buildDropdown(String label, bool isWide) {
    return SizedBox(
      width: isWide ? 450 : double.infinity,
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: "Male", child: Text("Male")),
          DropdownMenuItem(value: "Female", child: Text("Female")),
          DropdownMenuItem(value: "Other", child: Text("Other")),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        validator: (value) => value == null ? "Required" : null,
      ),
    );
  }
}
