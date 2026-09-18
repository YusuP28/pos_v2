import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/app_appbar.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: 'Tentang Aplikasi',
        subtitle: 'Informasi aplikasi & developer',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _info == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                    const SizedBox(height: 8),
                    _buildDeveloperSection(),
                    const SizedBox(height: 8),
                    _buildContactSection(),
                    const SizedBox(height: 8),
                    _buildTechSection(),
                    const SizedBox(height: 8),
                    _buildChangelogSection(),
                    const SizedBox(height: 8),
                    _buildLicenseSection(),
                    const SizedBox(height: 16),
                    _buildFooter(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.storefront,
                size: 48,
                color: Colors.deepPurple.shade400,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'POS v2',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Versi ${_info?.version ?? "-"} (Build ${_info?.buildNumber ?? "-"})',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi Point of Sale (POS) offline-first untuk Android. '
              'Dibangun dengan Flutter, data tersimpan lokal tanpa butuh internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return _section(
      title: 'Informasi',
      icon: Icons.info_outline,
      children: [
        _row('Nama Aplikasi', _info?.appName ?? 'POS v2'),
        _row('Package', _info?.packageName ?? '-'),
        _row('Versi', _info?.version ?? '-'),
        _row('Build', _info?.buildNumber ?? '-'),
        _row('Platform', 'Android'),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return _section(
      title: 'Developer',
      icon: Icons.person_outline,
      children: [
        _row('Nama', 'YusuP28'),
        _row('GitHub', 'github.com/YusuP28'),
      ],
    );
  }

  Widget _buildContactSection() {
    return _section(
      title: 'Kontak',
      icon: Icons.email_outlined,
      children: [
        _row('Email', 'yusup28editz@gmail.com'),
        _row('WhatsApp', '-'),
        _row('Website', '-'),
      ],
    );
  }

  Widget _buildTechSection() {
    return _section(
      title: 'Teknologi',
      icon: Icons.build_outlined,
      children: [
        _row('Framework', 'Flutter + Dart'),
        _row('Database', 'SQLite (sqflite)'),
        _row('State', 'Provider'),
        _row('CI/CD', 'GitHub Actions'),
      ],
    );
  }

  Widget _buildChangelogSection() {
    return _section(
      title: 'Riwayat Update',
      icon: Icons.history,
      children: [
        _row('v1.0.2', 'Halaman Tentang Aplikasi'),
        _row('v1.0.1', 'Icon aplikasi baru'),
        _row('v1.0.0', 'Rilis pertama (beta)'),
      ],
    );
  }

  Widget _buildLicenseSection() {
    return _section(
      title: 'Lisensi',
      icon: Icons.description_outlined,
      children: [
        _row('Lisensi', 'MIT License'),
        _row('Copyright', '© 2026 YusuP28'),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 14, color: Colors.red.shade300),
            const SizedBox(width: 4),
            const Text(
              'Dibuat dengan cinta dari HP',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Termux + GitHub Actions',
          style: TextStyle(fontSize: 9, color: Colors.grey),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
