import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/error_utils.dart';

String _errorFromDio(dynamic e) => userFriendlyErrorMessage(e);

/// Provider auth: stato login, user, login/register/logout.
/// Notifica cambiamenti per GoRouter redirect.
class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _auth.onUnauthorized = () {
      _user = null;
      notifyListeners();
    };
    _loadStoredUser();
  }

  final AuthService _auth = AuthService();
  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthService get authService => _auth;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> _loadStoredUser() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _user = await _auth.getMe();
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(email, password);
      _user = await _auth.getMe();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _errorFromDio(e);
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register(String email, String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.register(email, username, password);
      _user = await _auth.getMe();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _errorFromDio(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Login mock per sviluppo: imposta un utente fittizio senza chiamare il backend.
  /// Nome mostrato in home: "Ciao, Marco" (come design originale).
  void setMockLoggedIn(String email) {
    _user = UserModel(
      id: 'mock-${email.hashCode.abs()}',
      email: email,
      username: 'Marco',
      isActive: true,
      isAdmin: false,
      createdAt: DateTime.now(),
    );
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
