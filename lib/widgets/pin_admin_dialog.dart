import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import 'app_dialog.dart';

class PinAdminDialog {
  PinAdminDialog._();

  /// Return true kalau PIN Admin benar.
  static Future<bool> verify(BuildContext context) async {
    final has = await AuthService.instance.hasPinAdmin();
    if (!has) {
      if (!context.mounted) return false;
      await AppDialog.error(
        context,
        'PIN Admin belum diatur.\n\n'
        'Hubungi admin untuk mengatur PIN Admin di menu Pengaturan.',
        title: 'Akses Admin Belum Aktif',
      );
      return false;
    }

    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinAdminDialog(),
    );
    return result ?? false;
  }
}

class _PinAdminDialog extends StatefulWidget {
  const _PinAdminDialog();

  @override
  State<_PinAdminDialog> createState() => _PinAdminDialogState();
}

class _PinAdminDialogState extends State<_PinAdminDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'PIN harus 6 digit.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AuthService.instance.verifyPinAdmin(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = 'PIN Admin salah.';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.admin_panel_settings, size: 20),
          SizedBox(width: 8),
          Text('Akses Admin', style: TextStyle(fontSize: 15)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan PIN Admin (6 digit) untuk mengakses menu ini.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'PIN Admin',
              border: const OutlineInputBorder(),
              isDense: true,
              counterText: '',
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(fontSize: 12)),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verifikasi', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
