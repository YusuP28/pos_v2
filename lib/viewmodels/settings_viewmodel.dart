import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  String storeName = SettingsService.defaultStoreName;
  String storeAddress = SettingsService.defaultStoreAddress;
  String storePhone = SettingsService.defaultStorePhone;
  String receiptFooter = SettingsService.defaultFooter;
  String logoMode = 'text'; // 'text' | 'image'
  Uint8List? logoBytes;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final s = SettingsService.instance;
    storeName = await s.getStoreName();
    storeAddress = await s.getStoreAddress();
    storePhone = await s.getStorePhone();
    receiptFooter = await s.getReceiptFooter();
    logoMode = await s.getLogoMode();
    logoBytes = await s.readLogoBytes();
    loading = false;
    notifyListeners();
  }

  Future<void> save({
    required String name,
    required String address,
    required String phone,
    required String footer,
    required String mode,
  }) async {
    final s = SettingsService.instance;
    await s.setStoreName(name);
    await s.setStoreAddress(address);
    await s.setStorePhone(phone);
    await s.setReceiptFooter(footer);
    await s.setLogoMode(mode);
    await load();
  }

  Future<void> setLogoFromFile(File file) async {
    await SettingsService.instance.saveLogoFrom(file);
    logoBytes = await SettingsService.instance.readLogoBytes();
    notifyListeners();
  }

  Future<void> clearLogo() async {
    await SettingsService.instance.setLogoPath(null);
    logoBytes = null;
    notifyListeners();
  }
}
