import 'package:flutter/material.dart';

import 'views/splash_view.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'POS v2',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          toolbarHeight: 48,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          iconTheme: IconThemeData(size: 18, color: Colors.black87),
          actionsPadding: EdgeInsets.symmetric(horizontal: 4),
          titleSpacing: 8,
        ),
        visualDensity: VisualDensity.standard,
      ),
      home: const SplashView(),
    );
  }
}
