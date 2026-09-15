import 'package:flutter/material.dart';

class AppDialog {
  AppDialog._();

  static Future<void> error(
    BuildContext context,
    String message, {
    String title = 'Terjadi Kesalahan',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> info(
    BuildContext context,
    String message, {
    String title = 'Info',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
