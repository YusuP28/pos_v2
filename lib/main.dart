import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'viewmodels/auth_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const PosApp(),
    ),
  );
}
