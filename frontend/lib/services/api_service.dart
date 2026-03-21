import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Set to real production Render.com URL
  static const String baseUrl = 'https://nearnest-api.onrender.com/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: headers, body: jsonEncode(data));
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.put(url, headers: headers, body: jsonEncode(data));
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(url, headers: headers);
  }
}
