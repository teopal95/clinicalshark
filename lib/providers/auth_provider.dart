import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _profileService = ProfileService();

  UserProfile? _profile;
  // Cached for profile setup when profile hasn't been saved yet
  String _pendingName = '';
  String _pendingEmail = '';

  bool get isLoggedIn => _authService.isLoggedIn;
  UserProfile? get profile => _profile;
  String? get currentUid => _authService.currentUid;
  String get pendingName => _pendingName;
  String get pendingEmail => _pendingEmail;

  Future<void> init() async {
    await _authService.init();
    if (_authService.isLoggedIn) {
      _profile = await _profileService.getProfile(_authService.currentUid!);
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authService.login(email, password);
    _profile = await _profileService.getProfile(_authService.currentUid!);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    await _authService.register(name, email, password);
    _pendingName = name.trim();
    _pendingEmail = email.trim().toLowerCase();
    _profile = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _profile = null;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profileService.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!_authService.isLoggedIn) return;
    _profile = await _profileService.getProfile(_authService.currentUid!);
    notifyListeners();
  }
}
