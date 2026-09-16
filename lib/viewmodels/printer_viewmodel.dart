import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

import '../core/services/bt_scanner_service.dart';
import '../core/services/printer_service.dart';
import '../core/services/settings_service.dart';

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
  bool get isConnected =>
      PrinterService.instance.isConnected || _connected != null;
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
      _paper80mm = await SettingsService.instance.getPaper80mm();
    } catch (_) {
      _devices = [];
    }
    _loading = false;
    notifyListeners();
  }

  /// Auto-connect ke printer terakhir yang tersimpan.
  Future<void> autoConnect() async {
    try {
      final lastId = await SettingsService.instance.getLastPrinterId();
      if (lastId == null) return;

      // Jika sudah connect, skip.
      if (PrinterService.instance.isConnected) return;

      _devices = await PrinterService.instance.getPairedDevices();
      final target = _devices.firstWhere(
        (d) => d.address == lastId,
        orElse: () => _devices.firstWhere(
          (d) => d.name?.contains('RPP') ?? false,
          orElse: () => _devices.isEmpty
              ? BluetoothDevice(name: '', address: '')
              : _devices.first,
        ),
      );
      if ((target.address ?? '').isEmpty) return;

      final ok = await PrinterService.instance.connect(target);
      if (ok) {
        _connected = target;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> connect(BluetoothDevice device) async {
    _loading = true;
    notifyListeners();
    final ok = await PrinterService.instance.connect(device);
    if (ok) {
      _connected = device;
      await SettingsService.instance.setLastPrinter(
        device.address,
        device.name,
      );
    }
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

  Future<void> setPaper80mm(bool v) async {
    _paper80mm = v;
    await SettingsService.instance.setPaper80mm(v);
    notifyListeners();
  }

  Future<bool> testPrint() async {
    if (!isConnected) return false;
    final s = SettingsService.instance;
    return PrinterService.instance.printTestPage(
      paper80mm: _paper80mm,
      storeName: await s.getStoreName(),
      storeAddress: await s.getStoreAddress(),
      storePhone: await s.getStorePhone(),
      footer: await s.getReceiptFooter(),
    );
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
    final s = SettingsService.instance;
    final logoMode = await s.getLogoMode();
    final logoBytes =
        logoMode == 'image' ? await s.readLogoBytes() : null;

    return PrinterService.instance.printReceipt(
      storeName: await s.getStoreName(),
      storeAddress: await s.getStoreAddress(),
      storePhone: await s.getStorePhone(),
      invoiceNumber: invoiceNumber,
      cashierName: cashierName,
      dateTime: dateTime,
      items: items,
      subtotal: subtotal,
      total: total,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      footer: await s.getReceiptFooter(),
      paper80mm: _paper80mm,
      logoBytes: logoBytes,
    );
  }

  // ---- Scan & Pair ----

  Future<void> startScan() async {
    _scanning = true;
    _found = [];
    notifyListeners();
    try {
      final svc = BtScannerService.instance;
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
    await BtScannerService.instance.pair(device.id);
    await load(silent: true);
    try {
      final target = _devices.firstWhere((d) => d.address == device.id);
      await connect(target);
    } catch (_) {}
  }
}
