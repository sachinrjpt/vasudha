// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File, SocketException;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = "https://vasudha.app/api";

  // 🔑 Login Employee API
  static Future<Map<String, dynamic>> loginEmployee(String login, String password) async {
    final url = Uri.parse("$baseUrl/loginemployee");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json", "Accept": "application/json"},
            body: jsonEncode({"login": login, "password": password}),
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      // debug
      print("📌 LOGIN API Response (${response.statusCode}): ${response.body}");
      print("📌 LOGIN Decoded JSON: $data");

      if (response.statusCode == 200 && (data["status"]?.toString().toLowerCase() == "success")) {
        final token = data["token"];
        if (token != null) await StorageService.saveToken(token);

        return {
          "ok": true,
          "message": data["message"] ?? "Login successful",
          "user": data["user"],
          "token": token,
        };
      } else {
        return {
          "ok": false,
          "message": data["message"] ?? "Invalid login credentials",
          "errors": data["errors"],
        };
      }
    } on SocketException {
      return {"ok": false, "message": "No internet connection"};
    } on TimeoutException {
      return {"ok": false, "message": "Request timed out"};
    } catch (e) {
      return {"ok": false, "message": "Unexpected error: $e"};
    }
  }

  
  // ✅ Store Employee (aligned with Laravel apiStoreEmployee)
  static Future<Map<String, dynamic>> storeEmployee({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String zipCode,
    required String state,
    required String district,
    required String block,
    required String village,
    required String halmet,
    required String address,
    required String landArea,
    Uint8List? profileImageBytes, // optional (web)
    File? profileImageFile,       // optional (mobile)
  }) async {
    final url = Uri.parse("$baseUrl/store-employee"); // ✅ exact route

    try {
      final token = await StorageService.getToken();

      final request = http.MultipartRequest('POST', url);
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // ✅ Laravel controller exact fields
      request.fields['name']      = name;
      request.fields['phone']     = phone;
      if (email != null && email.isNotEmpty) {
        request.fields['email']   = email;
      }
      request.fields['password']  = password;
      request.fields['zip_code']  = zipCode;
      request.fields['state']     = state;
      request.fields['district']  = district;
      request.fields['block']     = block;
      request.fields['village']   = village;
      request.fields['halmet']    = halmet;
      request.fields['address']   = address;
      request.fields['land_area'] = landArea;

      // ✅ optional profile image
      if (profileImageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          profileImageFile.path,
        ));
      } else if (profileImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          profileImageBytes,
          filename: 'profile_image.png',
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      // debug
      print("📌 STORE-EMPLOYEE API (${response.statusCode}): ${response.body}");

      final bool okStatus =
          (data["status"]?.toString().toLowerCase() == "success") ||
          (data["success"] == true);

      if ((response.statusCode == 200 || response.statusCode == 201) && okStatus) {
        return {
          "ok": true,
          "message": data["message"] ?? "Employee added successfully",
          "employee_id": data["employee_id"],
          "raw": data,
        };
      } else if (response.statusCode == 422) {
        // validation errors
        return {
          "ok": false,
          "message": data["message"] ?? "Validation failed",
          "errors": data["errors"],
          "raw": data,
        };
      } else if (response.statusCode == 401) {
        return {
          "ok": false,
          "message": data["message"] ?? "Unauthorized",
          "raw": data,
        };
      } else {
        return {
          "ok": false,
          "message": data["message"] ?? "Failed to add employee",
          "errors": data["errors"],
          "raw": data,
        };
      }
    } on SocketException {
      return {"ok": false, "message": "No internet connection"};
    } on TimeoutException {
      return {"ok": false, "message": "Request timed out"};
    } catch (e) {
      return {"ok": false, "message": "Unexpected error: $e"};
    }
  }


  // 📌 Fetch Villages by Pin Code (robust + compatible)
  static Future<Map<String, dynamic>> getVillagesByPincode(String zipCode) async {
    final url = Uri.parse("$baseUrl/get-location-by-pincode/$zipCode");
    try {
      final token = await StorageService.getToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));

      // debug prints to terminal (very useful)
      print("📌 GET $url -> ${response.statusCode}");
      print("📌 API Response Body: ${response.body}");

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      // status check (case-insensitive)
      final status = (data["status"] ?? "").toString().toLowerCase();

      if (response.statusCode == 200 && status == "success") {
        final List<dynamic> raw = (data["data"] ?? []) as List<dynamic>;

        if (raw.isEmpty) {
          return {"ok": false, "status": "success", "message": "No villages found", "data": []};
        }

        // normalize each PO so frontend can use either Name or name
        final villages = raw.map((po) {
          final String name = (po["Name"] ?? po["name"] ?? "").toString();
          final String district = (po["District"] ?? po["district"] ?? "").toString();
          final String block = (po["Block"] ?? po["block"] ?? "").toString();
          final String state = (po["State"] ?? po["state"] ?? "").toString();
          final String pincode = (po["Pincode"] ?? po["pincode"] ?? "").toString();
          final String branchType = (po["BranchType"] ?? po["branchType"] ?? "").toString();
          final String deliveryStatus = (po["DeliveryStatus"] ?? po["deliveryStatus"] ?? "").toString();

          return {
            // keep both variants (capitalized keys from backend + lowercase for convenience)
            "Name": name,
            "name": name,
            "District": district,
            "district": district,
            "Block": block,
            "block": block,
            "State": state,
            "state": state,
            "Pincode": pincode,
            "pincode": pincode,
            "BranchType": branchType,
            "branchType": branchType,
            "DeliveryStatus": deliveryStatus,
            "deliveryStatus": deliveryStatus,
          };
        }).toList();

        // return with multiple keys to maximize compatibility with whatever front-end expects
        return {
          "ok": true,
          "status": "success",
          "message": data["message"] ?? "",
          "data": villages,      // frontends expecting data[]
          "villages": villages,  // frontends expecting villages[]
        };
      } else {
        return {"ok": false, "status": "error", "message": data["message"] ?? "Villages not found", "data": []};
      }
    } on SocketException {
      return {"ok": false, "message": "No internet connection", "data": []};
    } on TimeoutException {
      return {"ok": false, "message": "Request timed out", "data": []};
    } catch (e) {
      return {"ok": false, "message": "Unexpected error: $e", "data": []};
    }
  }

  // ✅ Get Employees API
// ✅ Get Employees API
static Future<Map<String, dynamic>> getEmployees() async {
  final url = Uri.parse("$baseUrl/farmers");

  try {
    final token = await StorageService.getToken(); // 🔑 fetch saved token

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token", // ✅ auth header added
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 EMPLOYEES API Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200 && data["status"] == "success") {
      return {
        "ok": true,
        "employees": data["employees"],
        "summary": data["summary"],
      };
    } else if (response.statusCode == 401) {
      return {"ok": false, "message": "Unauthorized. Please login again."};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to fetch employees",
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// 📌 Get Farmer by ID (direct backend format)
static Future<Map<String, dynamic>> getEmployeeById(String farmerId) async {
  final url = Uri.parse("$baseUrl/farmer/$farmerId");

  try {
    final token = await StorageService.getToken();
    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 GET FARMER ($farmerId) Response (${response.statusCode}): ${response.body}");

    // ✅ ab direct backend ka JSON return karenge
    return data;

  } catch (e) {
    return {
      "status": "error",
      "message": "Error: $e",
    };
  }
}



// 📌 Update Employee API
static Future<Map<String, dynamic>> updateEmployee({
  required String employeeId,
  required String name,
  required String phone,
  String? email,
  required String halmet,
  required String zipCode,
  String? village,
  String? address,
  String? state,
  String? district,
  String? block,
  Uint8List? profileImageBytes, // web optional
  File? profileImageFile,       // mobile optional
}) async {
  final url = Uri.parse("$baseUrl/employee/$employeeId/update");

  try {
    final token = await StorageService.getToken();

    final request = http.MultipartRequest('POST', url);
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['phone'] = phone;
    if (email != null && email.isNotEmpty) request.fields['email'] = email;
    request.fields['halmet'] = halmet;
    request.fields['zip_code'] = zipCode;
    if (village != null) request.fields['village'] = village;
    if (address != null) request.fields['address'] = address;
    if (state != null) request.fields['state'] = state;
    if (district != null) request.fields['district'] = district;
    if (block != null) request.fields['block'] = block;

    // optional profile image
    if (profileImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        profileImageFile.path,
      ));
    } else if (profileImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        profileImageBytes,
        filename: 'profile_image.png',
      ));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 UPDATE EMPLOYEE ($employeeId) Response (${response.statusCode}): ${response.body}");

    final okStatus = (data["status"]?.toString().toLowerCase() == "success");

    if ((response.statusCode == 200 || response.statusCode == 201) && okStatus) {
      return {"ok": true, "message": data["message"] ?? "Employee updated successfully"};
    } else if (response.statusCode == 422) {
      return {
        "ok": false,
        "message": data["message"] ?? "Validation failed",
        "errors": data["errors"],
      };
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to update employee",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// 📌 Delete Employee API
static Future<Map<String, dynamic>> deleteEmployee(String employeeId) async {
  final url = Uri.parse("$baseUrl/employee/$employeeId");

  try {
    final token = await StorageService.getToken();

    final response = await http.delete(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 DELETE EMPLOYEE ($employeeId) Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200 && data["status"]?.toString().toLowerCase() == "success") {
      return {"ok": true, "message": data["message"] ?? "Employee deleted successfully"};
    } else if (response.statusCode == 401) {
      return {"ok": false, "message": "Unauthorized. Please login again."};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to delete employee",
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}


// 📌 Simple JSON Update (for Section A etc.)
static Future<Map<String, dynamic>> updateEmployeeJson(String farmerId, Map<String, dynamic> body) async {
  final url = Uri.parse("$baseUrl/employee/$farmerId/update");

  try {
    final token = await StorageService.getToken();

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 UPDATE FARMER ($farmerId) Response (${response.statusCode}): ${response.body}");

    return data is Map<String, dynamic>
        ? data
        : {"status": "error", "message": "Invalid response"};
  } catch (e) {
    return {"status": "error", "message": "Error: $e"};
  }
}

// 📌 Fetch Seasons Master
static Future<Map<int, String>> getSeasons() async {
  final url = Uri.parse("$baseUrl/seasons");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {for (var s in raw) s["id"] as int: s["season"].toString()};
    }
    return {};
  } catch (e) {
    print("❌ getSeasons error: $e");
    return {};
  }
}

// 📌 Fetch Seed Varieties
static Future<Map<int, String>> getSeedVarieties() async {
  final url = Uri.parse("$baseUrl/seed-varieties");  // Adjust the URL based on your API
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {for (var v in raw) v["id"] as int: v["seed_variety"].toString()}; // Adjusted to 'seed_variety'
    }
    return {};
  } catch (e) {
    print("❌ getSeedVarieties error: $e");
    return {};
  }
}


// 📌 Fetch Crops Master
static Future<Map<int, String>> getCrops() async {
  final url = Uri.parse("$baseUrl/crops");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {for (var c in raw) c["id"] as int: c["crops"].toString()};
    }
    return {};
  } catch (e) {
    print("❌ getCrops error: $e");
    return {};
  }
}

// 📌 Fetch Irrigation Methods Master
static Future<Map<int, String>> getIrrigationMethods() async {
  final url = Uri.parse("$baseUrl/irrigation-methods");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {for (var m in raw) m["id"] as int: m["irrigation_methods"].toString()};
    }
    return {};
  } catch (e) {
    print("❌ getIrrigationMethods error: $e");
    return {};
  }
}

// 📌 Fetch Usage Types Master
static Future<Map<int, String>> getUsageTypes() async {
  final url = Uri.parse("$baseUrl/usage-types");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {for (var u in raw) u["id"] as int: u["usage_types"].toString()};
    }
    return {};
  } catch (e) {
    print("❌ getUsageTypes error: $e");
    return {};
  }
}

// 📌 Fetch Unit Types Master
static Future<Map<int, String>> getUnitTypes() async {
  final url = Uri.parse("$baseUrl/unit-types");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {for (var u in raw) u["id"] as int: u["unit_type"].toString()};
    }
    return {};
  } catch (e) {
    print("❌ getUnitTypes error: $e");
    return {};
  }
}


  static Future<Map<int, String>> getMachineries() async {
    final url = Uri.parse("$baseUrl/machineries");
    try {
      final token = await StorageService.getToken();
      final response = await http.get(url, headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      }).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["status"] == "success") {
        final List<dynamic> raw = data["data"] ?? [];
        return {
          for (var m in raw) m["id"] as int: m["machinery_name"].toString()
        };
      }
      return {};
    } catch (e) {
      print("❌ getMachineries error: $e");
      return {};
    }
  }
  static Future<Map<int, String>> getInputTypes() async {
  final url = Uri.parse("$baseUrl/input-types");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {
        for (var item in raw) item["id"] as int: item["input_types"].toString()
      };
    }
    return {};
  } catch (_) {
    return {};
  }
}
static Future<Map<int, String>> getInputNames() async {
  final url = Uri.parse("$baseUrl/input-names");
  try {
    final token = await StorageService.getToken();
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["status"] == "success") {
      final List<dynamic> raw = data["data"] ?? [];
      return {
        for (var item in raw) item["id"] as int: item["input_name"].toString()
      };
    }
    return {};
  } catch (_) {
    return {};
  }
}


  // 📌 Get Crop Info by ID
static Future<Map<String, dynamic>> getCropInfo(int cropId) async {
  final url = Uri.parse("$baseUrl/crop/$cropId");

  try {
    final token = await StorageService.getToken();
    final headers = {
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final response =
        await http.get(url, headers: headers).timeout(const Duration(seconds: 20));

    print("📌 GET CROP INFO ($cropId) -> ${response.statusCode}: ${response.body}");

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 &&
        (data["status"]?.toString().toLowerCase() == "success")) {
      return {
        "ok": true,
        "data": data["data"] ?? {},
      };
    } else if (response.statusCode == 401) {
      return {"ok": false, "message": "Unauthorized"};
    } else if (response.statusCode == 404) {
      return {"ok": false, "message": "Crop not found"};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to fetch crop info",
        "raw": data,
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// 📦 Seed Usage APIs

// 🔍 Get Seed Usages for a specific Farmer
static Future<Map<String, dynamic>> getSeedUsagesByFarmer(String farmerId) async {
  final url = Uri.parse("$baseUrl/seed-usage/$farmerId");

  print("🔍 DEBUG: getSeedUsagesByFarmer() called");
  print("📌 FarmerId param: $farmerId");
  print("📌 Final URL: $url");

  try {
    final token = await StorageService.getToken();
    print("📌 Token: ${token != null ? token.substring(0, 10) + '...' : 'NULL'}");

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    print("📌 Response Status: ${response.statusCode}");
    print("📌 Raw Response Body: ${response.body}");

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : [];

    if (response.statusCode == 200) {
      print("✅ Parsed Data: $data");
      return {
        "ok": true,
        "data": data,
      };
    } else {
      print("❌ ERROR: Non-200 status received");
      return {"ok": false, "message": "Failed to fetch seed usage data"};
    }
  } catch (e) {
    print("💥 Exception in getSeedUsagesByFarmer: $e");
    return {"ok": false, "message": "Error: $e"};
  }
}


// ➕ Store New Seed Usage
static Future<Map<String, dynamic>> storeSeedUsage({
  required int farmerId,
  required int seedName,          // 🔹 String → int
  int? seedVariety,               // 🔹 String? → int?
  double? quantityUsed,
  required int unitType,          // 🔹 String? → int
  double? perUnitCost,
}) async {
  final url = Uri.parse("$baseUrl/seed-usage/store");

  try {
    final token = await StorageService.getToken();

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "farmer_id": farmerId,
        "seed_name": seedName,
        "seed_variety": seedVariety,
        "quantity_used": quantityUsed,
        "unit_type": unitType,
        "per_unit_cost": perUnitCost,
      }),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 STORE Seed Usage: ${response.statusCode} → ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"ok": true, "data": data};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to store seed usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}


// ✏️ Update Existing Seed Usage
static Future<Map<String, dynamic>> updateSeedUsage({
  required int id,
  required Map<String, dynamic> updates,
}) async {
  final url = Uri.parse("$baseUrl/seed-usage/update/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.put(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 UPDATE Seed Usage ($id): ${response.statusCode} → ${response.body}");

    if (response.statusCode == 200) {
      return {"ok": true, "data": data};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to update seed usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}


// ❌ Delete Seed Usage Entry
static Future<Map<String, dynamic>> deleteSeedUsage(int id) async {
  final url = Uri.parse("$baseUrl/seed-usage/delete/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.delete(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    print("📌 DELETE Seed Usage ($id): ${response.statusCode} → ${response.body}");

    if (response.statusCode == 200 && data["success"] == true) {
      return {"ok": true, "message": "Deleted successfully"};
    } else {
      return {"ok": false, "message": data["message"] ?? "Delete failed"};
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
// ➕ Fetch Chemical Usages for a given farmer
static Future<Map<String, dynamic>> getChemicalUsagesByFarmer(String farmerId) async {
  final url = Uri.parse("$baseUrl/chemical-usages/$farmerId");

  print("🔍 DEBUG: getChemicalUsagesByFarmer() called");
  print("📌 FarmerId param: $farmerId");
  print("📌 Final URL: $url");

  try {
    final token = await StorageService.getToken();
    print("📌 Token: ${token != null ? token.substring(0, 10) + '...' : 'NULL'}");

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    print("📌 Response Status: ${response.statusCode}");
    print("📌 Raw Response Body: ${response.body}");

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : [];

    if (response.statusCode == 200 && data['status'] == 'success') {
      return {
        "ok": true,
        "data": data['data'],  // Only the actual chemical usage list
      };
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to fetch chemical usage data",
      };
    }
  } catch (e) {
    print("💥 Exception in getChemicalUsagesByFarmer: $e");
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> getFertilizerUsagesByFarmer(String farmerId) async {
  final url = Uri.parse("$baseUrl/fertilizer-usages/$farmerId");

  try {
    final token = await StorageService.getToken();

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return {
        "ok": true,
        "data": data['data'],
      };
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to fetch fertilizer usage data",
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> storeFertilizerUsage({
  required int farmerId,
  required int inputName,
  required int inputType,
  double? quantityUsed,
  required int unitType,
  double? perUnitCost,
  double? totalCost,
}) async {
  final url = Uri.parse("$baseUrl/fertilizer-usages");

  try {
    final token = await StorageService.getToken();

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "farmer_id": farmerId,
        "input_name": inputName,
        "input_type": inputType,
        "quantity_used": quantityUsed,
        "unit_type": unitType,
        "per_unit_cost": perUnitCost,
        "total_cost": totalCost,
      }),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"ok": true, "data": data};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to store fertilizer usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> updateFertilizerUsage({
  required int id,
  required Map<String, dynamic> updates,
}) async {
  final url = Uri.parse("$baseUrl/fertilizer-usages/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.put(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return {"ok": true, "data": data};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to update fertilizer usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> deleteFertilizerUsage(int id) async {
  final url = Uri.parse("$baseUrl/fertilizer-usages/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.delete(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return {"ok": true, "message": "Deleted successfully"};
    } else {
      return {"ok": false, "message": data["message"] ?? "Delete failed"};
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> storeChemicalUsage({
  required int farmerId,
  required int inputName,
  required int inputType,
  double? quantityUsed,
  required int unitType,
  double? perUnitCost,
  double? totalCost,
}) async {
  final url = Uri.parse("$baseUrl/chemical-usage");

  try {
    final token = await StorageService.getToken();

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "farmer_id": farmerId,
        "inptname": inputName,
        "inptyp": inputType,
        "qntyusd": quantityUsed,
        "unttyp": unitType,
        "pruntcst": perUnitCost,
        "totlcost": totalCost,
      }),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"ok": true, "data": data};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to store chemical usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> updateChemicalUsage({
  required int id,
  required Map<String, dynamic> updates,
}) async {
  final url = Uri.parse("$baseUrl/chemical-usage/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.put(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return {"ok": true, "data": data};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to update chemical usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> deleteChemicalUsage(int id) async {
  final url = Uri.parse("$baseUrl/chemical-usage/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.delete(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 && data["status"] == "success") {
      return {"ok": true, "message": data["message"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Delete failed",
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> storeSustainableFertiliser({
  required int farmerId,
  required int inputNameId,
  required int inputTypeId,
  double? quantityUsed,
  required int unitTypeId,
  double? perUnitCost,
  double? totalCost,
}) async {
  final url = Uri.parse("$baseUrl/sustainable-fertiliser");

  try {
    final token = await StorageService.getToken();

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "farmer_id": farmerId,
        "inputnamee": inputNameId,
        "inputtypee": inputTypeId,
        "quantityuseed": quantityUsed,
        "unittypee": unitTypeId,
        "perunitcoste": perUnitCost,
        "totalcostee": totalCost,
      }),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 201) {
      return {"ok": true, "data": data["data"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to store fertiliser",
        "errors": data["errors"]
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> updateSustainableFertiliser({
  required int id,
  required Map<String, dynamic> updates,
}) async {
  final url = Uri.parse("$baseUrl/sustainable-fertiliser/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.put(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return {"ok": true, "data": data["data"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to update fertiliser",
        "errors": data["errors"]
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> deleteSustainableFertiliser(int id) async {
  final url = Uri.parse("$baseUrl/sustainable-fertiliser/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.delete(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 && data["status"] == "success") {
      return {"ok": true, "message": data["message"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Delete failed"
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}
static Future<Map<String, dynamic>> getSustainableFertilisersByFarmer(int farmerId) async {
  final url = Uri.parse("$baseUrl/sustainable-fertiliser/$farmerId");

  try {
    final token = await StorageService.getToken();

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 && data["status"] == "success") {
      return {"ok": true, "data": data["data"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to fetch fertilisers"
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// 🌿 Get all pesticide records for a farmer
static Future<Map<String, dynamic>> getPesticidesByFarmer(String farmerId) async {
  final url = Uri.parse("$baseUrl/pesticides/$farmerId");

  try {
    final token = await StorageService.getToken();

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 && data["status"] == "success") {
      return {
        "ok": true,
        "data": data['data'],
      };
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to fetch pesticide data",
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// 🌿 Store a new pesticide usage record
static Future<Map<String, dynamic>> storePesticide({
  required int farmerId,
  required int inputId,
  required int inputType,
  double? quantityUsed,
  required int unitType,
  double? perUnitCost,
  double? totalCost,
}) async {
  final url = Uri.parse("$baseUrl/pesticides");

  try {
    final token = await StorageService.getToken();

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "farmer_id": farmerId,
        "inputttt": inputId,
        "inpuuttype": inputType,
        "quantiiityused": quantityUsed,
        "unittyppp": unitType,
        "prunitcoost": perUnitCost,
        "totalccosttt": totalCost,
      }),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"ok": true, "data": data["data"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to store pesticide usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// ✏️ Update existing pesticide record
static Future<Map<String, dynamic>> updatePesticide({
  required int id,
  required Map<String, dynamic> updates,
}) async {
  final url = Uri.parse("$baseUrl/pesticides/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.put(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return {"ok": true, "data": data["data"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Failed to update pesticide usage",
        "errors": data["errors"],
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}

// ❌ Delete a pesticide record
static Future<Map<String, dynamic>> deletePesticide(int id) async {
  final url = Uri.parse("$baseUrl/pesticides/$id");

  try {
    final token = await StorageService.getToken();

    final response = await http.delete(
      url,
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 20));

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 && data["status"] == "success") {
      return {"ok": true, "message": data["message"] ?? "Deleted successfully"};
    } else {
      return {"ok": false, "message": data["message"] ?? "Delete failed"};
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
  }
}


// 📌 Farmer Summary API
static Future<Map<String, dynamic>> getFarmerSummary(String farmerId) async {
  final url = Uri.parse('$baseUrl/farmer-summary/$farmerId'); // Laravel route
  try {
    final token = await StorageService.getToken();
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode == 200 && data["status"] == "success") {
      return {"ok": true, "data": data};
    } else {
      return {"ok": false, "message": data["message"] ?? "Error fetching summary"};
    }
  } catch (e) {
    return {"ok": false, "message": e.toString()};
  }
}






}