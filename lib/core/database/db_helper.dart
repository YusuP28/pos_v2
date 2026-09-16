import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../security/hash.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const _dbName = 'pos_v2.db';
  static const _dbVersion = 4;

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
    await _createOrderTables(db);
    await _createShiftTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await _createCategoryTables(db);
      await _seedDefaultCategory(db);
    }
    if (oldV < 3) {
      await _createOrderTables(db);
    }
    if (oldV < 4) {
      await _createShiftTable(db);
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
        'CREATE INDEX idx_products_barcode ON products (barcode)');
    await db.execute('CREATE INDEX idx_products_sku ON products (sku)');
  }

  Future<void> _seedDefaultCategory(Database db) async {
    await db.insert('categories', {
      'name': 'Umum',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _createOrderTables(Database db) async {
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        user_id INTEGER NOT NULL,
        shift_id INTEGER,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        change_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'paid',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_orders_created_at ON orders (created_at)');
    await db.execute(
        'CREATE INDEX idx_order_items_order_id ON order_items (order_id)');
  }

  Future<void> _createShiftTable(Database db) async {
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        opening_cash REAL NOT NULL DEFAULT 0,
        closing_cash REAL,
        expected_cash REAL,
        difference REAL,
        status TEXT NOT NULL DEFAULT 'open',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_shifts_status ON shifts (status)');
    await db.execute(
        'CREATE INDEX idx_shifts_opened_at ON shifts (opened_at)');
  }

  /// Tutup database (untuk backup/restore).
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Buka ulang database setelah close.
  Future<void> reopen() async {
    _db ??= await _open();
  }
}
