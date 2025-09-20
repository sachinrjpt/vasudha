import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'farmer_wizard.dart'; // ✅ NEW



class KrishiSakhiScreen extends StatefulWidget {
  const KrishiSakhiScreen({super.key});

  @override
  State<KrishiSakhiScreen> createState() => _KrishiSakhiScreenState();
}

class _KrishiSakhiScreenState extends State<KrishiSakhiScreen> {

  // ✅ Village dropdown state
List<dynamic> _villageList = [];
String? _selectedVillage;

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _sakhiList = []; // ✅ API data
  List<dynamic> _filteredList = [];

  Map<String, dynamic> _summary = {
    "total_employee": 0,
    "active_employee": 0,
    "inactive_employee": 0,
    "today_joiner": 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchData(); // ✅ API call
    _searchController.addListener(_filterSearch);
  }

  Future<void> _fetchData() async {
    try {
      final result = await ApiService.getEmployees(); // ✅ Use service

      if (result["ok"] == true) {
        List employees = result["employees"] ?? [];

        setState(() {
          _sakhiList = employees;
          _filteredList = employees;
          _summary = result["summary"] ?? {};
        });
      } else {
        print("Error: ${result["message"]}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

Future<void> _pickImage(
    {required Function(Uint8List? bytes, File? file) onImagePicked}) async {
  if (kIsWeb) {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.first.bytes != null) {
      onImagePicked(result.files.first.bytes!, null);
    }
  } else {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text("Camera")),
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text("Gallery")),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      onImagePicked(null, File(pickedFile.path));
    }
  }
}



  void _filterSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _sakhiList.where((item) {
        return item.values.any((value) =>
            value != null && value.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  void _deleteEmployee(BuildContext context, String employeeId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirm Delete"),
      content: const Text("Are you sure you want to delete this employee?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final result = await ApiService.deleteEmployee(employeeId);

  if (result["ok"] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result["message"] ?? "Deleted successfully")),
    );

    setState(() {
      _sakhiList.removeWhere((emp) => emp["employee_id"].toString() == employeeId);
      _filteredList.removeWhere((emp) => emp["employee_id"].toString() == employeeId);
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result["message"] ?? "Failed to delete")),
    );
  }
}


void _showEditDialog(BuildContext context, Map<String, dynamic> item) {
  final TextEditingController nameController =
      TextEditingController(text: item["name"] ?? "");
  final TextEditingController phoneController =
      TextEditingController(text: item["phone"] ?? "");
  final TextEditingController emailController =
      TextEditingController(text: item["email"] ?? "");
  final TextEditingController designationController =
      TextEditingController(text: item["designation"] ?? "");
  final TextEditingController pincodeController =
      TextEditingController(text: item["pincode"] ?? "");
  final TextEditingController villageController =
      TextEditingController(text: item["village"] ?? "");
  final TextEditingController districtController =
      TextEditingController(text: item["district"] ?? "");
  final TextEditingController blockController =
      TextEditingController(text: item["block"] ?? "");
  final TextEditingController hamletController =
      TextEditingController(text: item["hamlet"] ?? "");
  final TextEditingController stateController =
      TextEditingController(text: item["state"] ?? "");
  final TextEditingController landAreaController =
      TextEditingController(text: item["land_area"] ?? "");
  final TextEditingController passwordController =
      TextEditingController(text: "");
  final TextEditingController addressController =
      TextEditingController(text: item["address"] ?? "");


  final ImagePicker _picker = ImagePicker();
  String gender = item["gender"] ?? "Female";

  List<Map<String, dynamic>> _villageList = [];
  String? _selectedVillage = item["village"];



  showDialog(
    context: context,
    builder: (context) {
      final bool isMobile = MediaQuery.of(context).size.width < 600;

        File? _profileImageFile;
  Uint8List? _profileImageBytes;

      return StatefulBuilder(
        builder: (context, setState) {

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




          return AlertDialog(
            title: const Text("Edit Employee"),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _textField("Name", nameController, isMobile),
                  _textField("Phone", phoneController, isMobile,
                      keyboardType: TextInputType.phone),
                  _textField("Email", emailController, isMobile,
                      keyboardType: TextInputType.emailAddress),
                  _textField("Designation", designationController, isMobile),
                  _dropdownField("Gender", gender, ["Male", "Female", "Other"],
                      isMobile, (val) {
                    if (val != null) gender = val;
                  }),
                  _textField("Pincode", pincodeController, isMobile,
                      keyboardType: TextInputType.number, onChanged: (val) async {
                    if (val.length == 6) {
                      final res = await ApiService.getVillagesByPincode(val);
                      if (res["ok"] == true && res["data"] != null) {
                        setState(() {
                          _villageList =
                              List<Map<String, dynamic>>.from(res["data"]);
                          if (_villageList.isNotEmpty) {
                            _selectedVillage = _villageList.first["Name"];
                            villageController.text = _selectedVillage!;
                            districtController.text =
                                _villageList.first["District"] ?? "";
                            stateController.text =
                                _villageList.first["State"] ?? "";
                            blockController.text =
                                _villageList.first["Block"] ?? "";
                          }
                        });
                      } else {
                        setState(() {
                          _villageList = [];
                          _selectedVillage = null;
                          villageController.text = "";
                          districtController.text = "";
                          stateController.text = "";
                          blockController.text = "";
                        });
                      }
                    }
                  }),
                  DropdownButtonFormField<String>(
                    value: _selectedVillage != null &&
                            _villageList.any((v) => v["Name"] == _selectedVillage)
                        ? _selectedVillage
                        : null,
                    decoration: const InputDecoration(
                      labelText: "Village",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: _villageList.map<DropdownMenuItem<String>>((v) {
                      return DropdownMenuItem<String>(
                        value: v["Name"],
                        child: Text(v["Name"] ?? ""),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
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
                          villageController.text = val;
                          districtController.text = match["District"] ?? "";
                          stateController.text = match["State"] ?? "";
                          blockController.text = match["Block"] ?? "";
                          pincodeController.text = match["Pincode"] ?? "";
                        });
                      }
                    },
                  ),
                  _textField("District", districtController, isMobile),
                  _textField("Block", blockController, isMobile),
                  _textField("Hamlet", hamletController, isMobile),
                  _textField("State", stateController, isMobile),
                  _textField("Address", addressController, isMobile),
                  _textField("Land Area (in acres)", landAreaController, isMobile,
                      keyboardType: TextInputType.number),
                  _textField("Password", passwordController, isMobile,
                      obscure: true),
                  SizedBox(
                    width: isMobile ? double.infinity : 350,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : _profileImageFile != null
                                  ? FileImage(_profileImageFile!) as ImageProvider
                                  : (item["profile_image"] != null &&
                                          item["profile_image"].toString().isNotEmpty
                                      ? NetworkImage(item["profile_image"].toString())
                                      : const AssetImage("assets/default_user.png")),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: const Text("Upload Photo"),
                          onPressed: _pickImage,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await ApiService.updateEmployee(
                    employeeId: item["employee_id"] ?? "",
                    name: nameController.text,
                    phone: phoneController.text,
                    email: emailController.text,
                    halmet: hamletController.text,
                    zipCode: pincodeController.text,
                    village: villageController.text,
                    address: addressController.text,
                    state: stateController.text,
                    district: districtController.text,
                    block: blockController.text,
                    profileImageFile: _profileImageFile,
                    profileImageBytes: _profileImageBytes,
                  );

                  if (result["ok"] == true) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              result["message"] ?? "Updated successfully")),
                    );
                    _fetchData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result["message"] ?? "Update failed")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}










Widget _textField(
  String label,
  TextEditingController controller,
  bool isMobile, {
  TextInputType keyboardType = TextInputType.text,
  bool obscure = false,
  ValueChanged<String>? onChanged, // ✅ add this line
}) {
  return SizedBox(
    width: isMobile ? double.infinity : 350, // two columns on wide screens
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged, // ✅ pass it to TextField
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    ),
  );
}


Widget _dropdownField(String label, String? value, List<String> options,
    bool isMobile, ValueChanged<String?> onChanged) {
  return SizedBox(
    width: isMobile ? double.infinity : 350,
    child: DropdownButtonFormField<String>(
      value: value != null && options.contains(value) ? value : null,
      items: options
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    ),
  );
}



  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
        body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Krishi Sakhi",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 16),

                  // ✅ Dashboard Cards (API summary)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      if (constraints.maxWidth < 360) {
                        crossAxisCount = 1;
                      } else if (constraints.maxWidth > 600) {
                        crossAxisCount = 4;
                      }

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard("Total Employee",
                              "${_summary["total_employee"]}", Colors.black, Icons.people),
                          _buildStatCard("Active",
                              "${_summary["active_employee"]}", Colors.green, Icons.check_circle),
                          _buildStatCard("Inactive",
                              "${_summary["inactive_employee"]}", Colors.red, Icons.cancel),
                          _buildStatCard("New Joiners",
                              "${_summary["today_joiner"]}", Colors.blue, Icons.person_add),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Search Box
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Data Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(Colors.blue.shade50),
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [
                        DataColumn(label: Text("S/N")),
                        DataColumn(label: Text("Photo")),
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Phone")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Designation")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows: List<DataRow>.generate(_filteredList.length, (index) {
                        final item = _filteredList[index];
                        final String rawImageUrl = item["profile_image"] ?? "";
                        final String imageUrl = rawImageUrl.replaceAll("\\", "");

                        // 🔍 Debugging
  print("Raw Image: $rawImageUrl");
  print("Fixed URL: $imageUrl");

                        // 🔍 Debug print
                        print("Loading image: $imageUrl");

                        return DataRow(cells: [
                          DataCell(Text("${index + 1}")),
                          DataCell(
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              radius: 20,
                              child: ClipOval(
                                child: Image.network(
                                  imageUrl.isNotEmpty
                                      ? imageUrl
                                      : "https://via.placeholder.com/150",
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person,
                                        color: Colors.grey);
                                  },
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(item["employee_id"] ?? "-")),
                          DataCell(Text(item["name"] ?? "-")),
                          DataCell(Text(item["phone"] ?? "-")),
                          DataCell(Text(item["email"] ?? "-")),
                          DataCell(Text(item["designation"] ?? "-")),
                          DataCell(Text(item["status"] ?? "-")),
                          DataCell(
  Row(
    children: [
      // ✏️ Edit Button
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        onPressed: () {
          _showEditDialog(context, item); // 🔹 Pass row data
        },
      ),

      const SizedBox(width: 8),

      // 📊 Analysis Button (linked with FarmerWizard)
      IconButton(
  icon: const Icon(Icons.analytics, color: Colors.green),
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FarmerWizard(),
      ),
    );

    if (result == true) {
      _fetchData(); // ✅ Refresh after Finish
    }
  },
),

    ],
  ),
),


                        ]);
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}