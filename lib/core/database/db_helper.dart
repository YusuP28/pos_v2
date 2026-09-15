import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../security/hash.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const _dbName = 'pos_v2.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _seedAdmin(db);
    await _createCategoryTables(db);
    await _seedDefaultCategory(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await _createCategoryTables(db);
      await _seedDefaultCategory(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'kasir',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedAdmin(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password_hash': Hash.sha256('admin'),
      'full_name': 'Administrator',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _createCategoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        sku TEXT DEFAULT '',
        barcode TEXT DEFAULT '',
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        cost_price REAL NOT NULL DEFAULT 0,
        stock REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_products_barcode ON products (barcode)',
    );
    await db.execute('CREATE INDEX idx_products_sku ON products (sku)');
  }

  Future<void> _seedDefaultCategory(Database db) async {
    await db.insert('categories', {
      'name': 'Umum',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
