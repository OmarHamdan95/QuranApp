import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local persistence using SharedPreferences.
///
/// Acts as a lightweight local storage layer for bookmarks and settings,
/// avoiding the complexity of native Isar code generation in this project phase.
class IsarService {
  static IsarService? _instance;
  static SharedPreferences? _prefs;

  IsarService._();

  /// Returns the singleton instance. Call [initialize] first.
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  /// Initializes the local persistence layer.
  static Future<IsarService> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // Obtain app documents directory (used for future Isar migration).
      await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('IsarService init error: $e');
    }
    _instance = IsarService._();
    return _instance!;
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'IsarService not initialized. Call IsarService.initialize() first.',
      );
    }
    return _prefs!;
  }

  /// Stores a string value.
  Future<bool> setString(String key, String value) =>
      prefs.setString(key, value);

  /// Retrieves a string value.
  String? getString(String key) => prefs.getString(key);

  /// Stores a list of strings.
  Future<bool> setStringList(String key, List<String> value) =>
      prefs.setStringList(key, value);

  /// Retrieves a list of strings.
  List<String> getStringList(String key) =>
      prefs.getStringList(key) ?? [];

  /// Removes a key.
  Future<bool> remove(String key) => prefs.remove(key);

  /// Checks whether a key exists.
  bool containsKey(String key) => prefs.containsKey(key);

  /// Clears all stored data (use with caution).
  Future<bool> clear() => prefs.clear();
}
