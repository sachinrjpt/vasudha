// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File, SocketException;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = "https://utthan.makemybizprojects.co.in/api";

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

  // 📝 Store Employee API (unchanged behaviour, added Accept header)
  /// ✅ Store Employee (aligned with Laravel apiStoreEmployee)
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

// 📌 Get Employee by ID
static Future<Map<String, dynamic>> getEmployeeById(String employeeId) async {
  final url = Uri.parse("$baseUrl/employee/$employeeId");

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

    print("📌 GET EMPLOYEE ($employeeId) Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200 && data["status"]?.toString().toLowerCase() == "success") {
      return {"ok": true, "employee": data["data"]};
    } else {
      return {
        "ok": false,
        "message": data["message"] ?? "Employee not found",
      };
    }
  } catch (e) {
    return {"ok": false, "message": "Error: $e"};
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



}
