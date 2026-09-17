import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_storage.dart';

class SessionService {
  static const String _keySessionType = 'hastakala_session_type';
  static const String _keyArtisanSession = 'hastakala_artisan_session';
  static const String _keyBuyerSession = 'hastakala_buyer_session';

  /// Save Artisan Session to persistent storage (both Web localStorage and SharedPreferences)
  static Future<void> saveArtisanSession(Map<String, dynamic> session) async {
    try {
      final jsonStr = jsonEncode(session);
      // 1. Direct synchronous Web localStorage write
      WebStorage.setItem(_keySessionType, 'artisan');
      WebStorage.setItem(_keyArtisanSession, jsonStr);

      // 2. Cross-platform SharedPreferences write
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionType, 'artisan');
      await prefs.setString(_keyArtisanSession, jsonStr);
    } catch (e) {
      debugPrint('Error saving artisan session: $e');
    }
  }

  /// Save Buyer Session to persistent storage (both Web localStorage and SharedPreferences)
  static Future<void> saveBuyerSession(Map<String, dynamic> session) async {
    try {
      final jsonStr = jsonEncode(session);
      // 1. Direct synchronous Web localStorage write
      WebStorage.setItem(_keySessionType, 'buyer');
      WebStorage.setItem(_keyBuyerSession, jsonStr);

      // 2. Cross-platform SharedPreferences write
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionType, 'buyer');
      await prefs.setString(_keyBuyerSession, jsonStr);
    } catch (e) {
      debugPrint('Error saving buyer session: $e');
    }
  }

  /// Clear all session data on Logout
  static Future<void> clearSession() async {
    try {
      // 1. Direct synchronous Web localStorage removal
      WebStorage.removeItem(_keySessionType);
      WebStorage.removeItem(_keyArtisanSession);
      WebStorage.removeItem(_keyBuyerSession);

      // 2. Cross-platform SharedPreferences removal
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
    // 1. First check synchronous Web localStorage
    try {
      final webSessionType = WebStorage.getItem(_keySessionType);
      if (webSessionType == 'artisan') {
        final raw = WebStorage.getItem(_keyArtisanSession);
        if (raw != null && raw.isNotEmpty) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          return {'type': 'artisan', 'data': data};
        }
      } else if (webSessionType == 'buyer') {
        final raw = WebStorage.getItem(_keyBuyerSession);
        if (raw != null && raw.isNotEmpty) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          return {'type': 'buyer', 'data': data};
        }
      }
    } catch (e) {
      debugPrint('WebStorage check error: $e');
    }

    // 2. Check SharedPreferences as secondary/primary cross-platform store
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
      debugPrint('SharedPreferences check error: $e');
    }

    return null;
  }
}
