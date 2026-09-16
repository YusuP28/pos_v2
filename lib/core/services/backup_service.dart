import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _dbName = 'pos_v2.db';
  static const _backupFolder = 'pos_v2_backup';

  Future<Directory> _externalFilesDir() async {
    // /storage/emulated/0/Android/data/com.yusup.posv2/files/
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('Tidak bisa akses folder eksternal app.');
    }
    return dir;
  }

  Future<Directory> getBackupDir() async {
    final base = await _externalFilesDir();
    final backup = Directory(p.join(base.path, _backupFolder));
    if (!await backup.exists()) {
      await backup.create(recursive: true);
    }
    return backup;
  }

  Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  Future<int> getDatabaseSize() async {
    final f = File(await getDatabasePath());
    if (!await f.exists()) return 0;
    return await f.length();
  }

  String _backupFileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'pos_v2_backup_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.db';
  }

  /// Daftar file backup, diurutkan terbaru dulu.
  Future<List<BackupFile>> listBackups() async {
    final dir = await getBackupDir();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.db'))
        .cast<File>()
        .toList();

    final list = <BackupFile>[];
    for (final f in files) {
      final stat = await f.stat();
      list.add(BackupFile(
        path: f.path,
        name: p.basename(f.path),
        size: stat.size,
        modified: stat.modified,
      ));
    }
    list.sort((a, b) => b.modified.compareTo(a.modified));
    return list;
  }

  /// Backup + simpan ke folder backup. Return path file backup.
  Future<String> backupNow() async {
    await DbHelper.instance.close();
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database tidak ditemukan.');
      }
      final backupDir = await getBackupDir();
      final backupPath = p.join(backupDir.path, _backupFileName());
      await dbFile.copy(backupPath);
      return backupPath;
    } finally {
      await DbHelper.instance.reopen();
    }
  }

  /// Cek apakah file benar-benar SQLite.
  Future<bool> isValidSqlite(String path) async {
    final f = File(path);
    if (!await f.exists()) return false;
    final raf = await f.open();
    try {
      final bytes = await raf.read(16);
      if (bytes.length < 16) return false;
      const sqliteHeader = [
        0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20,
        0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20,
        0x33, 0x00,
      ];
      for (var i = 0; i < sqliteHeader.length; i++) {
        if (bytes[i] != sqliteHeader[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  /// Restore dari file backup.
  Future<void> restoreFrom(String sourcePath) async {
    if (!await isValidSqlite(sourcePath)) {
      throw Exception('File backup tidak valid (bukan SQLite).');
    }

    await DbHelper.instance.close();
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        // Simpan salinan DB lama untuk safety
        final safety =
            '${dbFile.path}.before_restore_${DateTime.now().millisecondsSinceEpoch}';
        await dbFile.copy(safety);
      }
      await File(sourcePath).copy(dbPath);
    } finally {
      await DbHelper.instance.reopen();
    }
  }

  Future<void> deleteBackup(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<Map<String, dynamic>> getInfo() async {
    await DbHelper.instance.reopen();
    final db = await DbHelper.instance.database;
    final products = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products WHERE is_active = 1'));
    final orders =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders'));
    final shifts =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM shifts'));
    final size = await getDatabaseSize();
    return {
      'products': products ?? 0,
      'orders': orders ?? 0,
      'shifts': shifts ?? 0,
      'size': size,
    };
  }
}

class BackupFile {
  final String path;
  final String name;
  final int size;
  final DateTime modified;

  BackupFile({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
  });

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
