import 'package:flutter/material.dart';

class AppAppBar extends AppBar {
  AppAppBar({
    super.key,
    required String title,
    required String subtitle,
    super.leading,
    super.actions,
    super.bottom,
  }) : super(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
}
