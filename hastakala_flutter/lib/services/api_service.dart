import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Live Vercel Production Server URL
  static const String liveVercelUrl = 'https://sih-26090-hastakala-ai-mind-forge-8.vercel.app';

  // Base URL configuration for different environments
  static String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.contains('localhost') && !origin.contains('127.0.0.1') && !origin.contains(':3000')) {
        return origin;
      }
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:8000';
    }
    // Mobile Android / iOS App connects to live Vercel Cloud Backend
    return liveVercelUrl;
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

  // AI Image Enhancer & PhotoRoom Studio Background API
  static Future<Map<String, dynamic>?> enhanceImage(
    Uint8List bytes,
    String filename, {
    String bgStyle = 'white',
    String bgPrompt = '',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/image/enhance'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      request.fields['bg_style'] = bgStyle;
      request.fields['bg_prompt'] = bgPrompt;
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

  // Regional Translation & Language Auto-Detection API
  static Future<Map<String, dynamic>?> translateText(String text, {String sourceLang = 'auto', String targetLang = 'en'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source_lang': sourceLang,
          'target_lang': targetLang,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error translating text: $e');
    }
    return null;
  }

  // Multilingual & Multimodal Voice/Text Cataloger API (Gemini 3.8 Flash)
  static Future<Map<String, dynamic>?> generateCatalog(
    String voiceText, {
    String language = 'Auto-Detect',
    String imageUrl = '',
    String imageBase64 = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/catalog/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voice_text': voiceText,
          'language': language,
          'image_url': imageUrl,
          'image_base64': imageBase64,
        }),
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

  // Fetch Products (With Category & Search filtering)
  static Future<List<dynamic>> getProducts({
    int? artisanId,
    String? artisanUsername,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (artisanId != null) queryParams['artisan_id'] = artisanId.toString();
      if (artisanUsername != null && artisanUsername.isNotEmpty) {
        queryParams['artisan_username'] = artisanUsername;
      }
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        queryParams['category'] = category;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri);
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

  // Delete Product
  static Future<bool> deleteProduct(int productId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/products/$productId'));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting product: $e');
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

  // Fetch B2B Due Orders
  static Future<List<dynamic>> getDueOrders({int? artisanId, String? artisanUsername}) async {
    try {
      final queryParams = <String, String>{};
      if (artisanId != null) queryParams['artisan_id'] = artisanId.toString();
      if (artisanUsername != null && artisanUsername.isNotEmpty) {
        queryParams['artisan_username'] = artisanUsername;
      }
      final uri = Uri.parse('$baseUrl/api/orders').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching due orders: $e');
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

  // --- Artisan Auth APIs ---

  static Future<Map<String, dynamic>?> loginArtisan(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        try {
          final err = jsonDecode(res.body);
          return {'status': 'error', 'detail': err['detail'] ?? 'Login failed'};
        } catch (_) {
          return {'status': 'error', 'detail': 'Invalid login credentials'};
        }
      }
    } catch (e) {
      debugPrint('Error logging in: $e');
      return {'status': 'error', 'detail': 'Server connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> registerArtisan({
    required String fullName,
    required String username,
    required String phone,
    required String gender,
    required String craftType,
    required String address,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'username': username,
          'phone': phone,
          'gender': gender,
          'craft_type': craftType,
          'address': address,
          'password': password,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        try {
          final err = jsonDecode(res.body);
          return {'status': 'error', 'detail': err['detail'] ?? 'Registration failed'};
        } catch (_) {
          return {'status': 'error', 'detail': 'Registration failed'};
        }
      }
    } catch (e) {
      debugPrint('Error registering artisan: $e');
      return {'status': 'error', 'detail': 'Server connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> updateArtisanProfile({
    required String username,
    String? fullName,
    String? phone,
    String? gender,
    String? craftType,
    String? location,
    String? profilePicture,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/update_profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (craftType != null) 'craft_type': craftType,
          if (location != null) 'location': location,
          if (profilePicture != null) 'profile_picture': profilePicture,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        try {
          final err = jsonDecode(res.body);
          return {'status': 'error', 'detail': err['detail'] ?? 'Profile update failed'};
        } catch (_) {
          return {'status': 'error', 'detail': 'Profile update failed'};
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'status': 'error', 'detail': 'Server connection error: $e'};
    }
  }

  // --- Buyer Auth APIs ---

  static Future<Map<String, dynamic>?> loginBuyer(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/buyer/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        try {
          final err = jsonDecode(res.body);
          return {'status': 'error', 'detail': err['detail'] ?? 'Buyer login failed'};
        } catch (_) {
          return {'status': 'error', 'detail': 'Invalid buyer credentials'};
        }
      }
    } catch (e) {
      debugPrint('Error logging in buyer: $e');
      return {'status': 'error', 'detail': 'Server connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> registerBuyer({
    required String organizationName,
    required String contactPerson,
    required String username,
    required String password,
    String phone = '',
    String contactEmail = '',
    String buyerType = 'Corporate Wholesale Buyer',
    String location = 'India',
    String targetCategory = 'Handicrafts & Handloom',
    int minOrderQty = 25,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/buyer/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'organization_name': organizationName,
          'contact_person': contactPerson,
          'username': username,
          'password': password,
          'phone': phone,
          'contact_email': contactEmail,
          'buyer_type': buyerType,
          'location': location,
          'target_category': targetCategory,
          'min_order_qty': minOrderQty,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        try {
          final err = jsonDecode(res.body);
          return {'status': 'error', 'detail': err['detail'] ?? 'Buyer registration failed'};
        } catch (_) {
          return {'status': 'error', 'detail': 'Buyer registration failed'};
        }
      }
    } catch (e) {
      debugPrint('Error registering buyer: $e');
      return {'status': 'error', 'detail': 'Server connection error: $e'};
    }
  }

  // --- B2B Enquiries APIs (The Heart of the Marketplace) ---

  static Future<Map<String, dynamic>?> createEnquiry(Map<String, dynamic> enquiryData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/enquiries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(enquiryData),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        try {
          final err = jsonDecode(res.body);
          return {'status': 'error', 'detail': err['detail'] ?? 'Failed to send enquiry'};
        } catch (_) {
          return {'status': 'error', 'detail': 'Failed to send enquiry'};
        }
      }
    } catch (e) {
      debugPrint('Error creating enquiry: $e');
      return {'status': 'error', 'detail': 'Server connection error: $e'};
    }
  }

  static Future<List<dynamic>> getEnquiries({
    int? productId,
    int? artisanId,
    String? artisanUsername,
    int? buyerId,
    String? buyerName,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (productId != null) queryParams['product_id'] = productId.toString();
      if (artisanId != null) queryParams['artisan_id'] = artisanId.toString();
      if (artisanUsername != null && artisanUsername.isNotEmpty) {
        queryParams['artisan_username'] = artisanUsername;
      }
      if (buyerId != null) queryParams['buyer_id'] = buyerId.toString();
      if (buyerName != null && buyerName.isNotEmpty) {
        queryParams['buyer_name'] = buyerName;
      }
      final uri = Uri.parse('$baseUrl/api/enquiries').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching enquiries: $e');
    }
    return [];
  }

  static Future<bool> updateEnquiryStatus(int enquiryId, String newStatus, {String rejectionReason = ''}) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/api/enquiries/$enquiryId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': newStatus,
          if (rejectionReason.isNotEmpty) 'rejection_reason': rejectionReason,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating enquiry status: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getRecommendations({String? category, int limit = 4}) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        queryParams['category'] = category;
      }
      final uri = Uri.parse('$baseUrl/api/recommendations').replace(queryParameters: queryParams);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
    }
    return [];
  }
}
