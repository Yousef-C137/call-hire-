import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your computer's IP address when testing on a real device
  // Use 10.0.2.2 for Android emulator, localhost for web
  static const String baseUrl = 'http://10.0.2.2:3000';

  // ─── TOKEN MANAGEMENT ────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ─── HEADERS ─────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // ─── AUTH ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await saveToken(data['token']);
      await saveUser(data['user']);
    }
    return {'statusCode': res.statusCode, ...data};
  }

  // ─── JOBS ─────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getJobs({String? category, String? search}) async {
    String url = '$baseUrl/jobs';
    final params = <String, String>{};
    if (category != null && category != 'All') params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) url += '?${Uri(queryParameters: params).query}';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getMyJobs() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/jobs/employer/mine'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> postJob(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: headers,
      body: jsonEncode(data),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> deleteJob(int jobId) async {
    final headers = await _authHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/jobs/$jobId'), headers: headers);
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ─── APPLICATIONS ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> applyToJob(int jobId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/applications'),
      headers: headers,
      body: jsonEncode({'job_id': jobId}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  static Future<List<dynamic>> getMyApplications() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/applications/my'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getEmployerApplications() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/applications/employer'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(int applicationId, String status) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/applications/$applicationId'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }

  // ─── MESSAGES ─────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getInbox() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/messages'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getConversation(int otherUserId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/messages/$otherUserId'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage(int receiverId, String content) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: jsonEncode({'receiver_id': receiverId, 'content': content}),
    );
    return {'statusCode': res.statusCode, ...jsonDecode(res.body)};
  }
}
