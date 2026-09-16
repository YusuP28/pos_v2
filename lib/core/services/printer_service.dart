import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  BluetoothDevice? _connected;

  BluetoothDevice? get connectedDevice => _connected;
  bool get isConnected => _connected != null;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    final devices = await _printer.getBondedDevices();
    return devices;
  }

  Future<bool> checkConnection() async {
    try {
      final connected = await _printer.isConnected ?? false;
      if (!connected) _connected = null;
      return connected;
    } catch (_) {
      _connected = null;
      return false;
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      await Future.delayed(const Duration(milliseconds: 800));
      final ok = await _printer.isConnected ?? false;
      if (ok) {
        _connected = device;
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _printer.disconnect();
    } catch (_) {}
    _connected = null;
  }

  Future<Uint8List> _buildReceipt({
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String invoiceNumber,
    required String cashierName,
    required String dateTime,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double discount = 0,
    double tax = 0,
    required double total,
    required String paymentMethod,
    required double paidAmount,
    required double changeAmount,
    String footer = 'Terima kasih',
    bool paper80mm = false,
    Uint8List? logoBytes,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paper80mm ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    final bytes = <int>[];

    // Header toko — logo gambar atau nama toko
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        final decoded = img.decodeImage(logoBytes);
        if (decoded != null) {
          final maxWidth = paper80mm ? 576 : 384;
          final resized = img.copyResize(
            decoded,
            width: maxWidth,
          );
          bytes.addAll(generator.image(resized));
          bytes.addAll(generator.feed(1));
        } else {
          bytes.addAll(generator.text(
            storeName,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
          ));
        }
      } catch (_) {
        bytes.addAll(generator.text(
          storeName,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ));
      }
    } else {
      bytes.addAll(generator.text(
        storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ));
    }
    if (storeAddress.isNotEmpty) {
      bytes.addAll(generator.text(
        storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }
    if (storePhone.isNotEmpty) {
      bytes.addAll(generator.text(
        'Telp: $storePhone',
        styles: const PosStyles(align: PosAlign.center),
      ));
    }
    bytes.addAll(generator.hr());

    // Info transaksi
    bytes.addAll(generator.text('No: $invoiceNumber'));
    bytes.addAll(generator.text('Tgl: $dateTime'));
    bytes.addAll(generator.text('Kasir: $cashierName'));
    bytes.addAll(generator.hr());

    // Items
    for (final it in items) {
      final name = (it['name'] ?? '').toString();
      final qty = (it['qty'] as num?)?.toDouble() ?? 0;
      final price = (it['price'] as num?)?.toDouble() ?? 0;
      final lineTotal = qty * price;

      bytes.addAll(generator.text(name));
      bytes.addAll(generator.row([
        PosColumn(
          text: '  ${qty.toStringAsFixed(0)} x ${price.toStringAsFixed(0)}',
          width: 7,
        ),
        PosColumn(
          text: lineTotal.toStringAsFixed(0),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    bytes.addAll(generator.hr());

    // Ringkasan
    bytes.addAll(generator.row([
      PosColumn(text: 'Subtotal', width: 7),
      PosColumn(
        text: subtotal.toStringAsFixed(0),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    if (discount > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Diskon', width: 7),
        PosColumn(
          text: discount.toStringAsFixed(0),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    if (tax > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Pajak', width: 7),
        PosColumn(
          text: tax.toStringAsFixed(0),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    bytes.addAll(generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: total.toStringAsFixed(0),
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: 'Bayar (${paymentMethod.toUpperCase()})', width: 7),
      PosColumn(
        text: paidAmount.toStringAsFixed(0),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'Kembali', width: 7),
      PosColumn(
        text: changeAmount.toStringAsFixed(0),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    bytes.addAll(generator.hr());

    // Footer
    for (final line in footer.split('\n')) {
      bytes.addAll(generator.text(
        line,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  Future<bool> printReceipt({
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String invoiceNumber,
    required String cashierName,
    required String dateTime,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double discount = 0,
    double tax = 0,
    required double total,
    required String paymentMethod,
    required double paidAmount,
    required double changeAmount,
    String footer = 'Terima kasih',
    bool paper80mm = false,
    Uint8List? logoBytes,
  }) async {
    final realtime = await checkConnection();
    if (!realtime) return false;

    final data = await _buildReceipt(
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      invoiceNumber: invoiceNumber,
      cashierName: cashierName,
      dateTime: dateTime,
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      footer: footer,
      paper80mm: paper80mm,
      logoBytes: logoBytes,
    );

    await _printer.writeBytes(data);
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> printTestPage({
    bool paper80mm = false,
    String storeName = 'POS v2',
    String storeAddress = 'Jl. Contoh No. 123',
    String storePhone = '0812-3456-7890',
    String footer = 'TES CETAK BERHASIL\nPOS v2',
    Uint8List? logoBytes,
  }) async {
    return printReceipt(
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      invoiceNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: 'Administrator',
      dateTime: DateTime.now().toString().substring(0, 19),
      items: const [
        {'name': 'Contoh Produk A', 'qty': 1, 'price': 5000},
        {'name': 'Contoh Produk B', 'qty': 2, 'price': 3500},
      ],
      subtotal: 12000,
      total: 12000,
      paymentMethod: 'cash',
      paidAmount: 20000,
      changeAmount: 8000,
      footer: footer,
      paper80mm: paper80mm,
      logoBytes: logoBytes,
    );
  }
}
