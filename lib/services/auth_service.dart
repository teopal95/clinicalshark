import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _usersKey = 'cs_users';
  static const _sessionKey = 'cs_session';

  String? _currentUid;

  String? get currentUid => _currentUid;
  bool get isLoggedIn => _currentUid != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUid = prefs.getString(_sessionKey);
  }

  Future<void> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final Map<String, dynamic> users = usersJson != null
        ? json.decode(usersJson) as Map<String, dynamic>
        : {};

    final normalizedEmail = email.trim().toLowerCase();
    if (users.containsKey(normalizedEmail)) {
      throw Exception('An account with this email already exists.');
    }

    final uid = _generateUid(normalizedEmail);
    users[normalizedEmail] = {
      'uid': uid,
      'passwordHash': _hash(password),
      'name': name.trim(),
    };

    await prefs.setString(_usersKey, json.encode(users));
    await prefs.setString(_sessionKey, uid);
    _currentUid = uid;
  }

  Future<void> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) {
      throw Exception('No account found with this email.');
    }

    final Map<String, dynamic> users =
        json.decode(usersJson) as Map<String, dynamic>;
    final normalizedEmail = email.trim().toLowerCase();
    final entry = users[normalizedEmail] as Map<String, dynamic>?;

    if (entry == null) {
      throw Exception('No account found with this email.');
    }
    if (entry['passwordHash'] != _hash(password)) {
      throw Exception('Incorrect password.');
    }

    final uid = entry['uid'] as String;
    await prefs.setString(_sessionKey, uid);
    _currentUid = uid;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUid = null;
  }

  String _hash(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  String _generateUid(String email) =>
      sha256.convert(utf8.encode('$email${DateTime.now().millisecondsSinceEpoch}')).toString().substring(0, 32);
}
