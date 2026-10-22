import 'package:flutter/material.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  List<User> _items = [];
  bool _loading = false;

  List<User> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await UserRepository.instance.getAll();
    } catch (_) {
      _items = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    await UserRepository.instance.create(
      username: username,
      password: password,
      fullName: fullName,
      role: role,
    );
    await load();
  }

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String role,
    String? newPassword,
  }) async {
    await UserRepository.instance.updateProfile(
      id: id,
      fullName: fullName,
      role: role,
      newPassword: newPassword,
    );
    await load();
  }

  Future<void> delete(int id, {required int currentUserId}) async {
    await UserRepository.instance.delete(id, currentUserId: currentUserId);
    await load();
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    await UserRepository.instance.changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
