import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Setting toko disimpan di SharedPreferences.
/// Logo disimpan sebagai file di folder app.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kStoreName = 'store_name';
  static const _kStoreAddress = 'store_address';
  static const _kStorePhone = 'store_phone';
  static const _kReceiptFooter = 'receipt_footer';
  static const _kLogoMode = 'logo_mode'; // 'text' | 'image'
  static const _kLogoPath = 'logo_path';
  static const _kLastPrinterId = 'last_printer_id';
  static const _kLastPrinterName = 'last_printer_name';
  static const _kPaper80mm = 'paper_80mm';

  static const defaultStoreName = 'POS v2';
  static const defaultStoreAddress = 'Jl. Contoh No. 123';
  static const defaultStorePhone = '0812-3456-7890';
  static const defaultFooter =
      'Terima kasih\nBarang yang sudah dibeli\ntidak dapat dikembalikan';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---- Store info ----
  Future<String> getStoreName() async =>
      (await _prefs).getString(_kStoreName) ?? defaultStoreName;
  Future<void> setStoreName(String v) async =>
      (await _prefs).setString(_kStoreName, v);

  Future<String> getStoreAddress() async =>
      (await _prefs).getString(_kStoreAddress) ?? defaultStoreAddress;
  Future<void> setStoreAddress(String v) async =>
      (await _prefs).setString(_kStoreAddress, v);

  Future<String> getStorePhone() async =>
      (await _prefs).getString(_kStorePhone) ?? defaultStorePhone;
  Future<void> setStorePhone(String v) async =>
      (await _prefs).setString(_kStorePhone, v);

  Future<String> getReceiptFooter() async =>
      (await _prefs).getString(_kReceiptFooter) ?? defaultFooter;
  Future<void> setReceiptFooter(String v) async =>
      (await _prefs).setString(_kReceiptFooter, v);

  // ---- Logo ----
  Future<String> getLogoMode() async =>
      (await _prefs).getString(_kLogoMode) ?? 'text';
  Future<void> setLogoMode(String v) async =>
      (await _prefs).setString(_kLogoMode, v);

  Future<String?> getLogoPath() async =>
      (await _prefs).getString(_kLogoPath);
  Future<void> setLogoPath(String? v) async {
    if (v == null) {
      await (await _prefs).remove(_kLogoPath);
    } else {
      await (await _prefs).setString(_kLogoPath, v);
    }
  }

  Future<Uint8List?> readLogoBytes() async {
    final path = await getLogoPath();
    if (path == null || path.isEmpty) return null;
    final f = File(path);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  /// Simpan logo dari file sumber ke folder app & return path tersimpan.
  Future<String> saveLogoFrom(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final logoDir = Directory(p.join(dir.path, 'pos_v2_logo'));
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }
    final dest =
        p.join(logoDir.path, 'logo_${DateTime.now().millisecondsSinceEpoch}.png');
    await source.copy(dest);
    await setLogoPath(dest);
    return dest;
  }

  // ---- Printer ----
  Future<String?> getLastPrinterId() async =>
      (await _prefs).getString(_kLastPrinterId);
  Future<String?> getLastPrinterName() async =>
      (await _prefs).getString(_kLastPrinterName);
  Future<void> setLastPrinter(String? id, String? name) async {
    final p = await _prefs;
    if (id == null) {
      await p.remove(_kLastPrinterId);
      await p.remove(_kLastPrinterName);
    } else {
      await p.setString(_kLastPrinterId, id);
      if (name != null) await p.setString(_kLastPrinterName, name);
    }
  }

  Future<bool> getPaper80mm() async =>
      (await _prefs).getBool(_kPaper80mm) ?? false;
  Future<void> setPaper80mm(bool v) async =>
      (await _prefs).setBool(_kPaper80mm, v);
}
