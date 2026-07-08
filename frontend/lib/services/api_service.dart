import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';
import '../models/claim_model.dart';

class ApiConfig {
  static String _baseUrl = 'http://127.0.0.1:8000/api';
  static String _hostUrl = 'http://127.0.0.1:8000';

  static String get baseUrl => _baseUrl;
  static String get hostUrl => _hostUrl;

  static void setCustomIp(String host) {
    if (host.startsWith('http://') || host.startsWith('https://')) {
      _hostUrl = host;
    } else {
      _hostUrl = 'http://$host:8000';
    }
    _baseUrl = '$_hostUrl/api';
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final customHost = prefs.getString('custom_host_url');
    if (customHost != null && customHost.isNotEmpty) {
      _hostUrl = customHost;
      _baseUrl = '$_hostUrl/api';
      if (kDebugMode) print('API config loaded from saved preferences: $_baseUrl');
      return;
    }

    if (kIsWeb) {
      _baseUrl = 'http://localhost:8000/api';
      _hostUrl = 'http://localhost:8000';
      return;
    }

    if (Platform.isAndroid) {
      // Test if 10.0.2.2 (Android Emulator loopback) is active
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(milliseconds: 800);
        final request = await client.getUrl(Uri.parse('http://10.0.2.2:8000/api/items'));
        final response = await request.close();
        if (response.statusCode >= 200) {
          _baseUrl = 'http://10.0.2.2:8000/api';
          _hostUrl = 'http://10.0.2.2:8000';
          if (kDebugMode) print('API config resolved to emulator: $_baseUrl');
          return;
        }
      } catch (_) {}

      // Fall back to physical device IP with ADB Reverse
      _baseUrl = 'http://127.0.0.1:8000/api';
      _hostUrl = 'http://127.0.0.1:8000';
      if (kDebugMode) print('API config resolved to physical (adb reverse): $_baseUrl');
    } else {
      _baseUrl = 'http://127.0.0.1:8000/api';
      _hostUrl = 'http://127.0.0.1:8000';
    }
  }
}

class ApiService {
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth API ---

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String nim,
    required String batch,
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'nim': nim,
        'batch': batch,
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 201 && responseData.containsKey('access_token')) {
      await saveToken(responseData['access_token']);
    }
    return responseData;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200 && responseData.containsKey('access_token')) {
      await saveToken(responseData['access_token']);
    }
    return responseData;
  }

  static Future<bool> logout() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/logout');
      final headers = await _headers();
      final response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        await clearToken();
        return true;
      }
    } catch (_) {}
    await clearToken(); // Clear token locally anyway
    return true;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/user');
      final headers = await _headers();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      if (kDebugMode) print('Profile fetch error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String name,
    required String email,
    required String nim,
    required String phoneNumber,
    String? imagePath,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/user/update');
      final token = await getToken();
      
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['nim'] = nim;
      request.fields['phone_number'] = phoneNumber;

      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) print('Profile update status: ${response.statusCode}, body: ${response.body}');
      
      return json.decode(response.body);
    } catch (e) {
      if (kDebugMode) print('Profile update error: $e');
    }
    return null;
  }

  // --- OTP Verification & Password Reset ---

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String type,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'type': type,
      }),
    );
    final responseData = json.decode(response.body);
    if (response.statusCode == 200 && responseData.containsKey('access_token')) {
      await saveToken(responseData['access_token']);
    }
    return responseData;
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'email': email,
      }),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'password': password,
      }),
    );
    return json.decode(response.body);
  }

  // --- Items API ---

  static Future<List<ItemModel>> getItems({
    String? search,
    String? type,
    String? category,
    String? location,
    String? date,
    String? status,
  }) async {
    final queryParams = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null && type.isNotEmpty) 'type': type,
      if (category != null && category.isNotEmpty) 'category': category,
      if (location != null && location.isNotEmpty) 'location': location,
      if (date != null && date.isNotEmpty) 'date': date,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/items').replace(queryParameters: queryParams);
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ItemModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<ItemModel>> getHistory() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/history');
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ItemModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<ItemModel?> getItemDetail(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/items/$id');
      final headers = await _headers();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return ItemModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      if (kDebugMode) print('Item detail fetch error: $e');
    }
    return null;
  }

  static Future<List<ItemModel>> getMyItems() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/my-items');
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ItemModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createItem({
    required String type,
    required String name,
    required String category,
    required String location,
    required String date,
    required String description,
    String? verificationQuestion,
    String? custodianType,
    String? custodianName,
    File? imageFile,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/items');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['type'] = type;
    request.fields['name'] = name;
    request.fields['category'] = category;
    request.fields['location'] = location;
    request.fields['date'] = date;
    request.fields['description'] = description;

    if (verificationQuestion != null && verificationQuestion.isNotEmpty) {
      request.fields['verification_question'] = verificationQuestion;
    }
    if (custodianType != null && custodianType.isNotEmpty) {
      request.fields['custodian_type'] = custodianType;
    }
    if (custodianName != null && custodianName.isNotEmpty) {
      request.fields['custodian_name'] = custodianName;
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return json.decode(response.body);
  }

  static Future<bool> deleteItem(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/$id');
    final headers = await _headers();
    final response = await http.delete(uri, headers: headers);
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> updateItemStatus({
    required int itemId,
    required String status,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/$itemId');
    final headers = await _headers();
    final response = await http.put(
      uri,
      headers: headers,
      body: json.encode({
        'status': status,
      }),
    );
    return json.decode(response.body);
  }

  // --- Claims API ---

  static Future<Map<String, dynamic>> claimItem({
    required int itemId,
    required String verificationAnswer,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/$itemId/claim');
    final headers = await _headers();
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'verification_answer': verificationAnswer,
      }),
    );
    return json.decode(response.body);
  }

  static Future<List<ClaimModel>> getMyClaims() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/my-claims');
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ClaimModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<ClaimModel>> getItemClaims(int itemId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/items/$itemId/claims');
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ClaimModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateClaimStatus({
    required int claimId,
    required String status, // 'approved' or 'rejected'
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/claims/$claimId/status');
    final headers = await _headers();
    final response = await http.put(
      uri,
      headers: headers,
      body: json.encode({
        'status': status,
      }),
    );
    return json.decode(response.body);
  }

  // --- Admin APIs ---

  static Future<Map<String, dynamic>?> getAdminStats() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/stats');
      final headers = await _headers();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getAdminUsers() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
      final headers = await _headers();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteAdminUser(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users/$id');
      final headers = await _headers();
      final response = await http.delete(url, headers: headers);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<List<ItemModel>> getAdminItems() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/items');
      final headers = await _headers();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ItemModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteAdminItem(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/items/$id');
      final headers = await _headers();
      final response = await http.delete(url, headers: headers);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<List<ClaimModel>> getAdminClaims() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/claims');
      final headers = await _headers();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ClaimModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> updateAdminClaimStatus(int claimId, String status) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/claims/$claimId/status');
      final headers = await _headers();
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'status': status,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
