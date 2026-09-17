import 'package:shared_preferences/shared_preferences.dart';

import '../security/hash.dart';
import '../../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kUserId = 'auth_user_id';
  static const _kUsername = 'auth_username';
  static const _kFullName = 'auth_full_name';
  static const _kRole = 'auth_role';
  static const _kLoggedIn = 'auth_logged_in';
  static const _kPinHash = 'auth_pin_hash';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ============ SESSION ============

  Future<void> saveSession(User user) async {
    final p = await _prefs;
    await p.setInt(_kUserId, user.id ?? 0);
    await p.setString(_kUsername, user.username);
    await p.setString(_kFullName, user.fullName);
    await p.setString(_kRole, user.role);
    await p.setBool(_kLoggedIn, true);
  }

  Future<User?> getSavedUser() async {
    final p = await _prefs;
    if (p.getBool(_kLoggedIn) != true) return null;
    final id = p.getInt(_kUserId);
    final username = p.getString(_kUsername);
    if (id == null || username == null) return null;
    return User(
      id: id,
      username: username,
      fullName: p.getString(_kFullName) ?? username,
      role: p.getString(_kRole) ?? 'kasir',
    );
  }

  Future<void> clearSession() async {
    final p = await _prefs;
    await p.remove(_kUserId);
    await p.remove(_kUsername);
    await p.remove(_kFullName);
    await p.remove(_kRole);
    await p.remove(_kLoggedIn);
  }

  // ============ PIN ============

  Future<bool> hasPin() async {
    final p = await _prefs;
    final h = p.getString(_kPinHash);
    return h != null && h.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final p = await _prefs;
    await p.setString(_kPinHash, Hash.sha256(pin));
  }

  Future<void> removePin() async {
    final p = await _prefs;
    await p.remove(_kPinHash);
  }

  Future<bool> verifyPin(String pin) async {
    final p = await _prefs;
    final saved = p.getString(_kPinHash);
    if (saved == null) return false;
    return saved == Hash.sha256(pin);
  }
}
