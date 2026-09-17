import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
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
  static const int _pinLength = 4;

  void _onDigit(String d) {
    if (_pin.length >= _pinLength) return;
    setState(() => _pin += d);
    if (_pin.length == _pinLength) _submit();
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
          'PIN akan DIHAPUS dan Anda akan logout.\n\n'
          'Setelah login ulang, Anda langsung masuk tanpa PIN.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus PIN & Logout',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await context.read<AuthViewModel>().forgotPin();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.deepPurple : Colors.transparent,
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  Widget _key(String label,
      {VoidCallback? onTap, IconData? icon, bool empty = false}) {
    if (empty) {
      return const SizedBox(width: 70, height: 56);
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 70,
            height: 56,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 22, color: Colors.black87)
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500)),
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
        child: Row(
          children: [
            // === KIRI: Info + Lupa PIN ===
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 56, color: Colors.deepPurple),
                    const SizedBox(height: 12),
                    const Text(
                      'Masukkan PIN',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PIN 4-digit untuk membuka aplikasi',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pinLength; i++) _dot(_pin.length > i),
                      ],
                    ),
                    const SizedBox(height: 24),
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
            // === KANAN: Keypad ===
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                          _key('', empty: true),
                          _key('0', onTap: () => _onDigit('0')),
                          _key('',
                              icon: Icons.backspace_outlined,
                              onTap: _onBackspace),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
