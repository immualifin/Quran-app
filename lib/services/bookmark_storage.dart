import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkStorage {
  static final BookmarkStorage _instance = BookmarkStorage._internal();
  factory BookmarkStorage() => _instance;
  BookmarkStorage._internal();

  // In-memory cache as fallback
  static List<String> _cachedBookmarks = [];
  static bool _cacheEnabled = false;

  Future<List<String>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarks') ?? [];

      // Sync cache with SharedPreferences
      if (!_cacheEnabled) {
        _cachedBookmarks = List.from(bookmarks);
        _cacheEnabled = true;
      }

      return bookmarks;
    } catch (e) {
      print('SharedPreferences failed, using cache: $e');
      _cacheEnabled = true;
      return List.from(_cachedBookmarks);
    }
  }

  Future<bool> saveBookmarks(List<String> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool success = await prefs.setStringList('bookmarks', bookmarks);

      if (success) {
        _cachedBookmarks = List.from(bookmarks);
      }

      return success;
    } catch (e) {
      print('SharedPreferences save failed, using cache: $e');
      _cachedBookmarks = List.from(bookmarks);
      _cacheEnabled = true;
      return true; // Return true to indicate "saved" to cache
    }
  }

  Future<bool> clearBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool success = await prefs.remove('bookmarks');

      if (success) {
        _cachedBookmarks.clear();
      }

      return success;
    } catch (e) {
      print('SharedPreferences clear failed, clearing cache: $e');
      _cachedBookmarks.clear();
      _cacheEnabled = true;
      return true;
    }
  }

  // For debugging
  void printDebugInfo() {
    print('=== BookmarkStorage Debug ===');
    print('Cache enabled: $_cacheEnabled');
    print('Cached bookmarks count: ${_cachedBookmarks.length}');
    print('===========================');
  }
}