import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../services/logger_service.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'lacarreta_offline.db');

      Log.i('Inicializando base de datos SQLite optimizada en: $path');

      return await openDatabase(
        path,
        version: 4,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      Log.e('Error al inicializar SQLite Database', e);
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
      await db.rawQuery('PRAGMA synchronous = NORMAL');
      await db.rawQuery('PRAGMA temp_store = MEMORY');
      await db.rawQuery('PRAGMA cache_size = -32000');
    } catch (e) {
      Log.w('No se pudieron aplicar algunos PRAGMAs de optimización: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    Log.i('Creando tablas e índices SQLite optimizados para lacarretamovil...');

    await db.execute('''
      CREATE TABLE catalog_ciudades (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        state INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE catalog_deudores (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        codigo TEXT,
        empresa_id INTEGER,
        state INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE catalog_tiendas (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        codigo TEXT,
        deudor_id INTEGER,
        ciudad_id INTEGER,
        ruta_id INTEGER DEFAULT 0,
        pais_id INTEGER DEFAULT 0,
        state INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE catalog_productos (
        id INTEGER PRIMARY KEY,
        codigo TEXT,
        nombre TEXT NOT NULL,
        deudor_id INTEGER,
        precio REAL DEFAULT 0,
        unidad TEXT,
        state INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos_local (
        id INTEGER PRIMARY KEY,
        deudor_id INTEGER,
        tienda_id INTEGER,
        ciudad_id INTEGER,
        usuario_id INTEGER,
        comentario TEXT,
        estado_id INTEGER DEFAULT 1,
        estado_nombre TEXT DEFAULT 'Pendiente',
        fecha TEXT,
        raw_json TEXT NOT NULL,
        synced INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos_detalle_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id INTEGER,
        producto_id INTEGER,
        cantidad REAL,
        precio REAL,
        raw_json TEXT NOT NULL,
        synced INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT DEFAULT 'PENDING',
        retry_count INTEGER DEFAULT 0,
        created_at TEXT,
        last_error TEXT
      )
    ''');

    await _createProduccionTables(db);
    await _createIndexes(db);

    Log.i('Tablas e índices SQLite creados exitosamente.');
  }

  Future<void> _createProduccionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produccion_grupos_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        etapa_id INTEGER NOT NULL,
        id_grupo INTEGER,
        nombre_grupo TEXT,
        raw_json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS produccion_recetas_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id INTEGER NOT NULL,
        id_almacen INTEGER,
        raw_json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS produccion_mesas_activas_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS catalog_almacenes (
        id INTEGER PRIMARY KEY,
        codigo TEXT,
        nombre TEXT NOT NULL,
        state INTEGER DEFAULT 1,
        raw_json TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS produccion_metadata_local (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tiendas_deudor ON catalog_tiendas (deudor_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tiendas_ciudad ON catalog_tiendas (ciudad_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_productos_deudor ON catalog_productos (deudor_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedidos_deudor ON pedidos_local (deudor_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedidos_tienda ON pedidos_local (tienda_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedidos_synced ON pedidos_local (synced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos_local (estado_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_detalles_pedido ON pedidos_detalle_local (pedido_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue (status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prod_grupos_etapa ON produccion_grupos_local (etapa_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prod_recetas_pedido ON produccion_recetas_local (pedido_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Log.i('Actualizando SQLite de versión $oldVersion a $newVersion');
    if (oldVersion < 2) {
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE catalog_tiendas ADD COLUMN ruta_id INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE catalog_tiendas ADD COLUMN pais_id INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      await _createProduccionTables(db);
      await _createIndexes(db);
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('catalog_ciudades');
    await db.delete('catalog_deudores');
    await db.delete('catalog_tiendas');
    await db.delete('catalog_productos');
    await db.delete('pedidos_local');
    await db.delete('pedidos_detalle_local');
    await db.delete('sync_queue');
    await db.delete('produccion_grupos_local');
    await db.delete('produccion_recetas_local');
    await db.delete('produccion_mesas_activas_local');
    await db.delete('catalog_almacenes');
    await db.delete('produccion_metadata_local');
    Log.i('Todos los datos locales de SQLite fueron limpiados.');
  }
}
