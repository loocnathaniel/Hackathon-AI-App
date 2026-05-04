import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _keyAccounts = 'auth_accounts_json';
  static const _keySession = 'auth_session_email';

  SharedPreferences? _prefs;
  String? _sessionEmail;

  bool get isInitialized => _prefs != null;
  bool get isLoggedIn =>
      _sessionEmail != null && _sessionEmail!.trim().isNotEmpty;
  String? get currentEmail => _sessionEmail;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionEmail = _prefs!.getString(_keySession);
    notifyListeners();
  }

  Map<String, String> _readAccounts() {
    final raw = _prefs!.getString(_keyAccounts);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAccounts(Map<String, String> accounts) async {
    await _prefs!.setString(_keyAccounts, jsonEncode(accounts));
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) {
      return false;
    }
    if (password.length < 6) {
      return false;
    }
    if (password != confirmPassword) {
      return false;
    }

    final accounts = _readAccounts();
    if (accounts.containsKey(e)) {
      return false;
    }

    accounts[e] = _hashPassword(password);
    await _writeAccounts(accounts);

    _sessionEmail = e;
    await _prefs!.setString(_keySession, e);
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    final accounts = _readAccounts();
    final stored = accounts[e];
    if (stored == null) return false;
    if (stored != _hashPassword(password)) return false;

    _sessionEmail = e;
    await _prefs!.setString(_keySession, e);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _sessionEmail = null;
    await _prefs!.remove(_keySession);
    notifyListeners();
  }
}
