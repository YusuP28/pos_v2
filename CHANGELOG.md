# Changelog — POS v2

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/),
versi mengikuti [Semantic Versioning](https://semver.org/lang/id/).

## [1.0.0] — 2026-09-18

Rilis stabil pertama. Aplikasi POS offline-first lengkap untuk retail.

### Fitur Utama

**Autentikasi & Keamanan**
- Login multi-user + session persistence (tetap login saat app ditutup)
- PIN Login (4-digit, per-device) untuk buka aplikasi
- PIN Admin (6-digit, per-device) untuk akses menu admin oleh kasir
- Logout konfirmasi

**Manajemen Data**
- Produk CRUD (nama, SKU, barcode, harga jual, modal, stok, satuan, aktif)
- Kategori CRUD
- Manajemen User (kasir & admin) + role restriction
- Soft delete (nonaktifkan tanpa hapus)

**Retail POS**
- Grid produk adaptif + filter kategori + search
- Cart panel kanan (selalu tampil)
- Checkout multi-metode: Tunai, QRIS, Kartu
- Checkout tunai: kembalian otomatis, uang cepat
- QRIS statis: upload gambar + verifikasi manual
- Kartu EDC: verifikasi manual
- Tombol "BAYAR" dan "BAYAR + CETAK" (cetak otomatis)

**Shift & Kas**
- Shift Kas: buka dengan uang awal, tutup dengan uang fisik
- Rekonsiliasi otomatis (uang awal + tunai − pengeluaran)
- Rekap selisih (cocok/lebih/kurang)
- Pengeluaran Kas + kategori default & custom
- Riwayat Shift: daftar + detail (penjualan per metode, pengeluaran, rekap)

**Stock Management**
- Tambah stok (kasir & admin) dengan catatan supplier
- Riwayat pergerakan stok per produk (in/out)
- Laporan Stok: low stock alert (threshold custom) + semua stok

**Barcode & Printer**
- Barcode scanner via kamera
- Cetak label harga + barcode Code128 (raw ESC/POS)
- Printer thermal Bluetooth (58mm & 80mm)
- Cetak struk otomatis setelah bayar
- Cetak ulang struk dari riwayat
- Logo struk (gambar galeri atau teks nama toko)
- Custom header (nama toko, alamat, telepon) + footer struk

**Laporan**
- Laporan Penjualan: filter hari/7h/30h/kustom + search invoice + filter metode
- **Laporan Profit**: penjualan − modal (HPP), margin %
- Export CSV: transaksi, detail item, produk

**Backup & Restore**
- Backup database ke folder app
- Restore dari file backup dengan verifikasi integritas SQLite

### Teknis
- Offline-first (semua data di SQLite lokal, tanpa internet)
- State: `provider`
- Build otomatis via GitHub Actions
- minSdk 23 (Android 6.0), targetSdk 35 (Android 14)
- Flutter 3.47.x, Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20

### Perubahan dari 1.0.0-beta
- Tab Profit di halaman Laporan
- Tombol Kelola Kategori di Pengeluaran (tambah + hapus kategori custom)
- Dialog Rekap Shift dirapikan (maxHeight + scrollable)
- Notifikasi custom toast (di tengah layar, auto-dismiss)
- Logout konfirmasi

## [1.0.0-beta] — 2026-09-18

Rilis beta pertama. Lihat commit history untuk detail.

## [Unreleased]
### Akan Datang
- F&B Mode (meja, hold order, kitchen notes)
- Pajak/PPN otomatis
- QRIS Dinamis (via Midtrans/Xendit/DOKU)
- Log akses admin (audit PIN)
- Optimasi ukuran APK (split-ABI → ~30 MB)
