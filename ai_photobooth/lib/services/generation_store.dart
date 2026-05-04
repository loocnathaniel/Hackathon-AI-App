import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/generation_record.dart';

/// Shared history across all accounts on this device.
/// Favorites are stored per signed-in email.
class GenerationStore extends ChangeNotifier {
  GenerationStore._();
  static final GenerationStore instance = GenerationStore._();

  static const _historyKey = 'generation_history_json_v1';
  static String _favoritesKey(String email) =>
      'generation_favorites_${email.trim().toLowerCase()}';

  SharedPreferences? _prefs;
  List<GenerationRecord> _history = [];

  bool get isInitialized => _prefs != null;
  List<GenerationRecord> get history => List.unmodifiable(_history);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final raw = _prefs!.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      _history = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _history = list
          .map((e) => GenerationRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _history = [];
    }
  }

  Future<void> _saveHistory() async {
    final encoded =
    jsonEncode(_history.map((r) => r.toJson()).toList(growable: false));
    await _prefs!.setString(_historyKey, encoded);
  }

  static const int maxEntries = 30;

  /// Add a new generation (supports both normal and remix)
  Future<String> addSuccessfulGeneration({
    required String createdByEmail,
    required String prompt,
    required String outputBase64,
    String? originalImageBase64,
  }) async {
    final id = const Uuid().v4();
    final entry = GenerationRecord(
      id: id,
      createdByEmail: createdByEmail.trim().toLowerCase(),
      prompt: prompt.trim(),
      outputImageBase64: outputBase64,
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
      likedByEmails: [],
      originalImageBase64: originalImageBase64,
    );

    _history.insert(0, entry);
    if (_history.length > maxEntries) {
      _history = _history.sublist(0, maxEntries);
    }
    await _saveHistory();
    notifyListeners();
    return id;
  }

  Future<void> toggleLike({
    required String recordId,
    required String userEmail,
  }) async {
    final email = userEmail.trim().toLowerCase();
    final idx = _history.indexWhere((r) => r.id == recordId);
    if (idx < 0) return;

    final r = _history[idx];
    final likes = List<String>.from(r.likedByEmails);
    final already = likes.any((x) => x.toLowerCase() == email);
    if (already) {
      likes.removeWhere((x) => x.toLowerCase() == email);
    } else {
      likes.add(email);
    }
    _history[idx] = r.copyWith(likedByEmails: likes);
    await _saveHistory();
    notifyListeners();
  }

  List<String> _readFavoriteIds(String email) {
    final raw = _prefs!.getString(_favoritesKey(email));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeFavoriteIds(String email, List<String> ids) async {
    await _prefs!.setString(_favoritesKey(email), jsonEncode(ids));
  }

  Future<void> toggleFavorite({
    required String recordId,
    required String userEmail,
  }) async {
    final email = userEmail.trim().toLowerCase();
    final ids = _readFavoriteIds(email);
    if (ids.contains(recordId)) {
      ids.remove(recordId);
    } else {
      ids.insert(0, recordId);
    }
    await _writeFavoriteIds(email, ids);
    notifyListeners();
  }

  bool isFavorite({
    required String recordId,
    required String userEmail,
  }) {
    return _readFavoriteIds(userEmail).contains(recordId);
  }

  List<GenerationRecord> favoritesFor(String userEmail) {
    final ids = _readFavoriteIds(userEmail);
    final map = {for (final r in _history) r.id: r};
    return ids.map((id) => map[id]).whereType<GenerationRecord>().toList();
  }
}