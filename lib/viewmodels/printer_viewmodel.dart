import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

import '../core/services/printer_service.dart';

class PrinterViewModel extends ChangeNotifier {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connected;
  bool _loading = false;
  bool _paper80mm = false;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get connected => _connected;
  bool get loading => _loading;
  bool get isConnected => _connected != null;
  bool get paper80mm => _paper80mm;

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
      footer: 'Terima kasih\nBarang yang sudah dibeli\ntidak dapat dikembalikan',
      paper80mm: _paper80mm,
    );
  }
}
