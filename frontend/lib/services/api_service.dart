import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' if (dart.library.html) 'dart:html' show Platform; // Conditional import helper or just use kIsWeb

class ApiService {
  static String _customBaseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customBaseUrl = prefs.getString('custom_ip') ?? '';
    debugPrint('ApiService initialized with baseUrl: $baseUrl');
  }

  static Future<void> setCustomIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_ip', ip);
    _customBaseUrl = ip;
  }

  static const String _primaryServer = 'https://nearnest-api.onrender.com/api';

  // Dynamic baseUrl for web and mobile
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return 'https://$_customBaseUrl/api';
    }
    return _primaryServer;
  }

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

  static Future<http.Response> getRaw(String fullUrl) async {
    try {
      final res = await http.get(Uri.parse(fullUrl), headers: {'User-Agent': 'NearNest App'});
      if (res.statusCode >= 500) throw Exception('Server error');
      return res;
    } catch (e) {
      // For fullUrl we can't easily swap the domain, but we retry once
      return await http.get(Uri.parse(fullUrl), headers: {'User-Agent': 'NearNest App'});
    }
  }

  // Caching mechanism: Stale-While-Revalidate
  static Future<void> getWithCache({
    required String endpoint,
    required Function(dynamic) onCacheHit,
    required Function(dynamic) onSourceUpdate,
  }) async {
    final cacheKey = 'cache_$endpoint';
    
    // 1. Get SharedPreferences instance once
    final prefs = await SharedPreferences.getInstance();

    // 2. Immediate cache hit
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData);
        onCacheHit(decoded);
      } catch (e) {
        print('Cache Decode Error: $e');
      }
    }

    // 3. Background fetch (don't await this if you want immediate UI return, 
    // but here we want to handle the result)
    _performBackgroundFetch(endpoint, cacheKey, prefs, onSourceUpdate);
  }

  static Future<void> _performBackgroundFetch(
    String endpoint, 
    String cacheKey, 
    SharedPreferences prefs,
    Function(dynamic) onSourceUpdate
  ) async {
    try {
      final response = await get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString(cacheKey, response.body);
        onSourceUpdate(data);
      }
    } catch (e) {
      print('API Fetch Error: $e');
    }
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
