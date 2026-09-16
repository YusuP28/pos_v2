import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

import '../core/services/bt_scanner_service.dart';
import '../core/services/printer_service.dart';

class PrinterViewModel extends ChangeNotifier {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connected;
  bool _loading = false;
  bool _paper80mm = false;

  bool _scanning = false;
  List<BtDevice> _found = [];

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get connected => _connected;
  bool get loading => _loading;
  bool get isConnected => _connected != null;
  bool get paper80mm => _paper80mm;
  bool get scanning => _scanning;
  List<BtDevice> get found => _found;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _devices = await PrinterService.instance.getPairedDevices();
      if (PrinterService.instance.isConnected) {
        _connected = PrinterService.instance.connectedDevice;
      }
    } catch (_) {
      _devices = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> connect(BluetoothDevice device) async {
    _loading = true;
    notifyListeners();
    final ok = await PrinterService.instance.connect(device);
    if (ok) _connected = device;
    _loading = false;
    notifyListeners();
    return ok;
  }

  Future<void> disconnect() async {
    _loading = true;
    notifyListeners();
    await PrinterService.instance.disconnect();
    _connected = null;
    _loading = false;
    notifyListeners();
  }

  void setPaper80mm(bool v) {
    _paper80mm = v;
    notifyListeners();
  }

  Future<bool> testPrint() async {
    if (!isConnected) return false;
    return PrinterService.instance.printTestPage(paper80mm: _paper80mm);
  }

  Future<bool> printReceipt({
    required String invoiceNumber,
    required String cashierName,
    required String dateTime,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double total,
    required String paymentMethod,
    required double paidAmount,
    required double changeAmount,
  }) async {
    if (!isConnected) return false;
    return PrinterService.instance.printReceipt(
      storeName: 'POS v2',
      storeAddress: 'Jl. Contoh No. 123',
      storePhone: '0812-3456-7890',
      invoiceNumber: invoiceNumber,
      cashierName: cashierName,
      dateTime: dateTime,
      items: items,
      subtotal: subtotal,
      total: total,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      footer:
          'Terima kasih\nBarang yang sudah dibeli\ntidak dapat dikembalikan',
      paper80mm: _paper80mm,
    );
  }

  // ---- Scan & Pair ----

  Future<void> startScan() async {
    _scanning = true;
    _found = [];
    notifyListeners();
    try {
      final svc = BtScannerService.instance;
      // stream update setiap 500ms agar UI live
      final timer = Stream.periodic(const Duration(milliseconds: 500));
      final sub = timer.listen((_) {
        _found = svc.found;
        notifyListeners();
      });
      await svc.startScan(timeout: const Duration(seconds: 12));
      await sub.cancel();
      _found = svc.found;
    } catch (e) {
      _found = [];
      rethrow;
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await BtScannerService.instance.stopScan();
    _scanning = false;
    _found = BtScannerService.instance.found;
    notifyListeners();
  }

  Future<void> pairAndConnect(BtDevice device) async {
    // 1) Pair (munculkan dialog Android)
    await BtScannerService.instance.pair(device.id);
    // 2) Reload daftar paired dari blue_thermal_printer
    await load(silent: true);
    // 3) Connect ke device yang baru dipairing
    try {
      final target = _devices.firstWhere(
        (d) => d.address == device.id,
      );
      await connect(target);
    } catch (_) {
      // device mungkin tidak ketemu di daftar bonded; abaikan
    }
  }
}
