import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BtDevice {
  final String id;
  final String name;
  final bool isPaired;
  BtDevice({required this.id, required this.name, required this.isPaired});
}

class BtScannerService {
  BtScannerService._();
  static final BtScannerService instance = BtScannerService._();

  bool _scanning = false;
  StreamSubscription<List<ScanResult>>? _sub;
  final Map<String, BtDevice> _found = {};

  bool get scanning => _scanning;
  List<BtDevice> get found => _found.values.toList();

  Future<bool> _ensurePermission() async {
    // Android 12+ butuh BLUETOOTH_SCAN & BLUETOOTH_CONNECT.
    // flutter_blue_plus otomatis minta lewat adapterState.
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_scanning) return;
    final ok = await _ensurePermission();
    if (!ok) {
      throw Exception('Bluetooth tidak aktif. Nyalakan Bluetooth dulu.');
    }
    _found.clear();
    _scanning = true;

    _sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final id = r.device.remoteId.str;
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : '(tanpa nama)');
        _found[id] = BtDevice(id: id, name: name, isPaired: false);
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      _scanning = false;
      rethrow;
    }

    // Tunggu sampai scan selesai
    await Future.delayed(timeout + const Duration(seconds: 1));
    await stopScan();
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _sub?.cancel();
    _sub = null;
    _scanning = false;
  }

  /// Trigger pairing. Di Android akan muncul dialog sistem.
  Future<void> pair(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      // Setelah connect, kita lepas supaya blue_thermal_printer
      // bisa connect sendiri.
      await Future.delayed(const Duration(milliseconds: 500));
      await device.disconnect();
    } catch (e) {
      rethrow;
    }
  }
}
