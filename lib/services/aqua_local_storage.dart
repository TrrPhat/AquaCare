import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent Offline-First local storage adapter backed by SharedPreferences (`1A`).
class AquaLocalStorage {
  AquaLocalStorage({this.storageKey = defaultStorageKey});

  static const String defaultStorageKey = 'aquacare_app_state_v1';

  final String storageKey;

  Future<Map<String, dynamic>?> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Safe fallback to default state if storage is empty or corrupted.
    }
    return null;
  }

  Future<void> saveState(Map<String, dynamic> stateJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(stateJson));
    } catch (_) {
      // Ignore storage write errors in constrained/headless environments.
    }
  }

  Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (_) {
      // Ignore cleanup errors.
    }
  }
}
