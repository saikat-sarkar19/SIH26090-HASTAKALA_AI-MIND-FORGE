import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keySessionType = 'hastakala_session_type';
  static const String _keyArtisanSession = 'hastakala_artisan_session';
  static const String _keyBuyerSession = 'hastakala_buyer_session';

  /// Save Artisan Session to local persistent storage
  static Future<void> saveArtisanSession(Map<String, dynamic> session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionType, 'artisan');
      await prefs.setString(_keyArtisanSession, jsonEncode(session));
    } catch (e) {
      debugPrint('Error saving artisan session: $e');
    }
  }

  /// Save Buyer Session to local persistent storage
  static Future<void> saveBuyerSession(Map<String, dynamic> session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionType, 'buyer');
      await prefs.setString(_keyBuyerSession, jsonEncode(session));
    } catch (e) {
      debugPrint('Error saving buyer session: $e');
    }
  }

  /// Clear session data on Logout
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySessionType);
      await prefs.remove(_keyArtisanSession);
      await prefs.remove(_keyBuyerSession);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  /// Load session on App startup
  static Future<Map<String, dynamic>?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionType = prefs.getString(_keySessionType);

      if (sessionType == 'artisan') {
        final raw = prefs.getString(_keyArtisanSession);
        if (raw != null && raw.isNotEmpty) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          return {'type': 'artisan', 'data': data};
        }
      } else if (sessionType == 'buyer') {
        final raw = prefs.getString(_keyBuyerSession);
        if (raw != null && raw.isNotEmpty) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          return {'type': 'buyer', 'data': data};
        }
      }
    } catch (e) {
      debugPrint('Error loading saved session: $e');
    }
    return null;
  }
}
