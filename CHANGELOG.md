# Changelog — POS v2

Semua perubahan penting pada project ini akan didokumentasikan di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/),
versi mengikuti [Semantic Versioning](https://semver.org/lang/id/).

## [1.0.0-beta] — 2026-09-18

Rilis beta pertama. Fitur lengkap untuk retail POS offline-first.

### Fitur Utama
- **Autentikasi** — Login single/multi user, session persistence (tetap login
  saat app ditutup), PIN Login (4-digit), PIN Admin (6-digit) untuk akses
  menu admin.
- **Manajemen User** — CRUD kasir & admin, role-based access (kasir dibatasi),
  ganti password, hapus user.
- **Produk & Kategori** — CRUD produk (nama, SKU, barcode, harga jual, harga
  modal, stok, satuan, aktif), CRUD kategori, soft-delete.
- **Retail POS** — Grid produk, filter kategori, search, cart, multi-metode
  pembayaran (Tunai, QRIS, Kartu).
- **QRIS Statis** — Upload gambar QRIS toko dari galeri/kamera, tampil saat
  pembayaran, verifikasi manual oleh kasir.
- **Shift Kas** — Buka shift (uang awal), tutup shift (uang fisik),
  rekonsiliasi otomatis, rekap selisih.
- **Pengeluaran Kas** — Catat pengeluaran (operasional, belanja, transport,
  gaji), kurangi uang seharusnya shift.
- **Riwayat Shift** — Daftar shift lampau + detail (penjualan, pengeluaran,
  rekap uang).
- **Stock Management** — Tambah stok (kasir & admin), riwayat pergerakan
  stok, laporan stok (low stock alert + semua stok).
- **Barcode Scanner** — Scan barcode via kamera HP (mobile_scanner).
- **Cetak Label Barcode** — Cetak label harga + barcode Code128 ke printer
  thermal (raw ESC/POS).
- **Printer Bluetooth** — Connect printer thermal, cetak struk otomatis,
  cetak ulang, custom logo, header/footer toko.
- **Info Toko** — Nama toko, alamat, telepon, footer struk, logo (gambar/
  teks), QRIS statis.
- **Laporan Penjualan** — Filter hari/7 hari/30 hari/kustom, search invoice,
  filter metode pembayaran, breakdown.
- **Export CSV** — Export transaksi, detail item, produk ke file CSV
  (bisa dibuka di Excel/Google Sheets).
- **Backup & Restore** — Backup database ke folder app, restore dari file
  backup.

### Teknis
- Offline-first (semua data di SQLite lokal)
- Build otomatis via GitHub Actions
- minSdk 23 (Android 6.0)
- targetSdk 35 (Android 14)
- Flutter 3.47.x
- State management: `provider`
- Database: `sqflite` v6 (migrasi otomatis)

### Catatan Beta
- Fitur **Laporan Profit** dan **Kategori Pengeluaran Custom** sudah ada di
  kode, tapi UI-nya belum lengkap (akan ditambahkan di versi berikutnya).
- F&B Mode (restaurant tables, hold order, kitchen notes) belum diimplementasi.

## [Unreleased]
### Akan Datang
- Tab Profit di halaman Laporan
- Tombol tambah/hapus Kategori Pengeluaran (UI)
- F&B Mode (meja, hold order, kitchen notes)
- Pajak/PPN otomatis
- QRIS Dinamis (via Midtrans/Xendit/DOKU)
- Log akses admin (audit PIN)
