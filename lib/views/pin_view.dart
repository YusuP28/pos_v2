import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_toast.dart';
import 'home_view.dart';
import 'login_view.dart';

class PinView extends StatefulWidget {
  const PinView({super.key});

  @override
  State<PinView> createState() => _PinViewState();
}

class _PinViewState extends State<PinView> {
  String _pin = '';
  int _attempts = 0;

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final auth = context.read<AuthViewModel>();
    final ok = await auth.unlockWithPin(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } else {
      _attempts++;
      setState(() => _pin = '');
      AppToast.show(context, 'PIN salah ($_attempts)', success: false);
    }
  }

  Future<void> _forgotPin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa PIN?', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Anda akan logout dan harus login ulang dengan '
          'username & password.\n\nPIN tetap tersimpan — setelah login, '
          'Anda akan diminta PIN lagi. Untuk ganti/hapus PIN, buka '
          'Pengaturan setelah login.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final auth = context.read<AuthViewModel>();
    await auth.forgotPin();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.deepPurple : Colors.transparent,
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  Widget _key(String label, {VoidCallback? onTap, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 70,
            height: 60,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 24, color: Colors.black87)
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 48, color: Colors.deepPurple),
                const SizedBox(height: 12),
                const Text(
                  'Masukkan PIN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PIN 4-digit untuk membuka aplikasi',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(_pin.length >= 1),
                    _dot(_pin.length >= 2),
                    _dot(_pin.length >= 3),
                    _dot(_pin.length >= 4),
                  ],
                ),
                const SizedBox(height: 24),
                // Keypad 3x4
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _key('1', onTap: () => _onDigit('1')),
                        _key('2', onTap: () => _onDigit('2')),
                        _key('3', onTap: () => _onDigit('3')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _key('4', onTap: () => _onDigit('4')),
                        _key('5', onTap: () => _onDigit('5')),
                        _key('6', onTap: () => _onDigit('6')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _key('7', onTap: () => _onDigit('7')),
                        _key('8', onTap: () => _onDigit('8')),
                        _key('9', onTap: () => _onDigit('9')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _key('', onTap: _forgotPin),
                        _key('0', onTap: () => _onDigit('0')),
                        _key('',
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _forgotPin,
                  icon: const Icon(Icons.help_outline, size: 14),
                  label: const Text('Lupa PIN?',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
