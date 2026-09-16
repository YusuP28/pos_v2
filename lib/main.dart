import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';
import 'viewmodels/printer_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/shift_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => ShiftViewModel()),
        ChangeNotifierProvider(create: (_) => PrinterViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const PosApp(),
    ),
  );
}
