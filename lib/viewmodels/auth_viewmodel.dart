import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  User? _currentUser;
  bool _loading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get loading => _loading;

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
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
