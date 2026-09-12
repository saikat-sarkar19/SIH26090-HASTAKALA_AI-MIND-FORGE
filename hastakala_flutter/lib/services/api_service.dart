import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL configuration for different environments
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // Check connection status
  static Future<bool> checkBackendConnection() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/dashboard/stats'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error getting stats: $e');
    }
    return {
      'total_products': 0,
      'total_enquiries': 0,
      'total_buyers': 0,
      'ai_opportunity': {
        'title': 'Your handloom products are trending',
        'subtitle': 'Add 2 more designs to attract more buyers.',
      }
    };
  }

  // AI Image Enhancer API
  static Future<Map<String, dynamic>?> enhanceImage(Uint8List bytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/image/enhance'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error enhancing image: $e');
    }
    return null;
  }

  // Multilingual Voice/Text Cataloger API
  static Future<Map<String, dynamic>?> generateCatalog(String voiceText, {String language = 'Hindi'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/catalog/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'voice_text': voiceText, 'language': language}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error generating catalog: $e');
    }
    return null;
  }

  // Audio Voice Note Cataloger API
  static Future<Map<String, dynamic>?> generateCatalogFromAudio(List<int> audioBytes, String filename, {String language = 'Hindi'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/catalog/generate_audio'));
      request.files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: filename));
      request.fields['language'] = language;
      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error generating catalog from audio: $e');
    }
    return null;
  }

  // Dynamic Pricing Assistant API
  static Future<Map<String, dynamic>?> calculatePricing({
    required String category,
    required String materials,
    double rawMaterialCost = 0.0,
    double laborHours = 8.0,
    double laborRate = 100.0,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/pricing/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category,
          'materials': materials,
          'raw_material_cost': rawMaterialCost,
          'labor_hours': laborHours,
          'labor_rate_per_hour': laborRate,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error calculating pricing: $e');
    }
    return null;
  }

  // Fetch Products
  static Future<List<dynamic>> getProducts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/products'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    return [];
  }

  // Create/Publish Product
  static Future<bool> publishProduct(Map<String, dynamic> product) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error publishing product: $e');
      return false;
    }
  }

  // AI Assistant Chat API
  static Future<Map<String, dynamic>?> chatAssistant(String query, {String language = 'Hindi'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/assistant/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'language': language}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error chatting with assistant: $e');
    }
    return null;
  }

  // Fetch Verified Buyers
  static Future<List<dynamic>> getBuyers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/buyers'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching buyers: $e');
    }
    return [];
  }

  // Helper to full image URL
  static String getFullImageUrl(String relativePath) {
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    if (!relativePath.startsWith('/')) {
      relativePath = '/$relativePath';
    }
    return '$baseUrl$relativePath';
  }
}
