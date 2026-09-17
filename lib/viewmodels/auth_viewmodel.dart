import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

enum AuthState { initial, needPin, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  User? _currentUser;
  bool _loading = false;
  AuthState _state = AuthState.initial;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get loading => _loading;
  AuthState get state => _state;

  /// Dipanggil saat app start. Return true kalau session tersimpan.
  Future<bool> initSession() async {
    final saved = await AuthService.instance.getSavedUser();
    if (saved == null) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
    _currentUser = saved;
    // Cek apakah PIN di-set
    final hasPin = await AuthService.instance.hasPin();
    _state = hasPin ? AuthState.needPin : AuthState.authenticated;
    notifyListeners();
    return true;
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    notifyListeners();

    final user = await UserRepository.instance.verify(username, password);
    _loading = false;

    if (user == null) {
      notifyListeners();
      return false;
    }

    _currentUser = user;
    await AuthService.instance.saveSession(user);

    // Setelah login, cek apakah PIN ada
    final hasPin = await AuthService.instance.hasPin();
    _state = hasPin ? AuthState.needPin : AuthState.authenticated;
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await AuthService.instance.verifyPin(pin);
    if (ok) {
      _state = AuthState.authenticated;
      notifyListeners();
    }
    return ok;
  }

  Future<void> logout() async {
    _currentUser = null;
    _state = AuthState.unauthenticated;
    await AuthService.instance.clearSession();
    notifyListeners();
  }

  /// Lupa PIN — logout total, tapi PIN tetap tersimpan.
  Future<void> forgotPin() async {
    await logout();
  }
}
