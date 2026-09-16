import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_viewmodel.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';

class InfoTokoView extends StatefulWidget {
  const InfoTokoView({super.key});

  @override
  State<InfoTokoView> createState() => _InfoTokoViewState();
}

class _InfoTokoViewState extends State<InfoTokoView> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _footer = TextEditingController();
  final _qrisMerchant = TextEditingController();
  String _mode = 'text';
  bool _busy = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<SettingsViewModel>().load();
      if (!mounted) return;
      final vm = context.read<SettingsViewModel>();
      _name.text = vm.storeName;
      _address.text = vm.storeAddress;
      _phone.text = vm.storePhone;
      _footer.text = vm.receiptFooter;
      _qrisMerchant.text = vm.qrisMerchantName;
      setState(() {
        _mode = vm.logoMode;
        _initialized = true;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _footer.dispose();
    _qrisMerchant.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      await context.read<SettingsViewModel>().setLogoFromFile(File(picked.path));
      if (!mounted) return;
      AppToast.show(context, 'Logo tersimpan.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal memilih gambar: $e',
          title: 'Gagal Upload Logo');
    }
  }

  Future<void> _pickQris({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 95);
      if (picked == null) return;
      await context.read<SettingsViewModel>().setQrisFromFile(File(picked.path));
      if (!mounted) return;
      AppToast.show(context, 'QRIS tersimpan.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal memilih gambar: $e',
          title: 'Gagal Upload QRIS');
    }
  }

  Future<void> _saveQrisMerchant() async {
    await context.read<SettingsViewModel>().saveQrisMerchant(_qrisMerchant.text.trim());
    if (!mounted) return;
    AppToast.show(context, 'Nama merchant tersimpan.');
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      await AppDialog.error(context, 'Nama toko wajib diisi.',
          title: 'Data Tidak Lengkap');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<SettingsViewModel>().save(
            name: _name.text.trim(),
            address: _address.text.trim(),
            phone: _phone.text.trim(),
            footer: _footer.text,
            mode: _mode,
          );
      if (!mounted) return;
      AppToast.show(context, 'Info toko tersimpan.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal simpan: $e', title: 'Gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    const denseInput = InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: TextStyle(fontSize: 12),
    );

    if (!_initialized || vm.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppAppBar(
        title: 'Info Toko',
        subtitle: 'Nama, alamat, logo, footer struk',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: bottomInset + 16,
            ),
            children: [
              // === Data toko ===
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text('Data Toko',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              TextField(
                controller: _name,
                decoration: denseInput.copyWith(labelText: 'Nama toko *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _address,
                decoration: denseInput.copyWith(labelText: 'Alamat'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                decoration: denseInput.copyWith(labelText: 'Telepon'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _footer,
                decoration: denseInput.copyWith(
                  labelText: 'Footer struk',
                  hintText: 'Terima kasih',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // === Mode logo ===
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text('Logo Struk',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: 'text',
                        groupValue: _mode,
                        onChanged: (v) => setState(() => _mode = v ?? 'text'),
                        title: const Text('Pakai nama toko sebagai header',
                            style: TextStyle(fontSize: 12)),
                      ),
                      RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: 'image',
                        groupValue: _mode,
                        onChanged: (v) => setState(() => _mode = v ?? 'text'),
                        title: const Text('Pakai gambar logo dari galeri',
                            style: TextStyle(fontSize: 12)),
                      ),
                      if (_mode == 'image') ...[
                        const Divider(height: 12),
                        if (vm.logoBytes != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Image.memory(
                              vm.logoBytes!,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Belum ada logo. Upload dulu.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: _pickLogo,
                                  icon: const Icon(Icons.image, size: 16),
                                  label: const Text('Pilih dari Galeri',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                            if (vm.logoBytes != null) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await context
                                        .read<SettingsViewModel>()
                                        .clearLogo();
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  label: const Text('Hapus',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),


              // === QRIS Toko ===
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text('QRIS Toko',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.qrisBytes != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.memory(
                            vm.qrisBytes!,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Belum ada QRIS. Upload gambar QRIS toko.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qrisMerchant,
                        decoration: denseInput.copyWith(
                          labelText: 'Nama merchant (opsional)',
                          hintText: 'Contoh: Toko Maju Jaya',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save, size: 18),
                            onPressed: _saveQrisMerchant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickQris(source: ImageSource.gallery),
                                icon: const Icon(Icons.image, size: 16),
                                label: const Text('Dari Galeri',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickQris(source: ImageSource.camera),
                                icon: const Icon(Icons.photo_camera, size: 16),
                                label: const Text('Dari Kamera',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                          if (vm.qrisBytes != null) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await context
                                      .read<SettingsViewModel>()
                                      .clearQris();
                                },
                                icon: const Icon(Icons.delete_outline,
                                    size: 16),
                                label: const Text('Hapus',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // === Preview ===
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text('Preview Struk (teks)',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_mode == 'image' && vm.logoBytes != null)
                        Image.memory(vm.logoBytes!, height: 60)
                      else
                        Text(
                          _name.text.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 2),
                      if (_address.text.isNotEmpty)
                        Text(_address.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11)),
                      if (_phone.text.isNotEmpty)
                        Text('Telp: ${_phone.text}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11)),
                      const Divider(height: 14),
                      const Text('-- Item --',
                          style: TextStyle(fontSize: 11)),
                      const Divider(height: 14),
                      Text(
                        _footer.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN',
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
