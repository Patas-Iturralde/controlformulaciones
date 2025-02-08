// db_helper.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;
  static final DBHelper _instance = DBHelper._internal();

  // Nombres de las tablas
  static const String tableProcesos = 'procesos';
  static const String tableSecuencias = 'secuencias';
  static const String tableTrabajoAdicional = 'trabajo_adicional';
  static const String tableProductos = 'productos';

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'formulaciones.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de procesos principales
    await db.execute('''
      CREATE TABLE $tableProcesos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nrOp INTEGER NOT NULL,
        numeroPesaje INTEGER NOT NULL,
        maquina TEXT NOT NULL,
        producto TEXT NOT NULL,
        codProducto TEXT NOT NULL,
        fecha_guardado TEXT NOT NULL,
        fecha_proceso TEXT NOT NULL,
        situacion TEXT,
        pdfPath TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');

    // Tabla de secuencias del proceso
    await db.execute('''
      CREATE TABLE $tableSecuencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proceso_id INTEGER NOT NULL,
        secuencia REAL NOT NULL,
        instruccion TEXT NOT NULL,
        producto TEXT,
        temperatura REAL NOT NULL,
        tiempo INTEGER NOT NULL,
        ctd_explosion REAL,
        observacion TEXT,
        codigo_escaneado TEXT,
        hora_inicio TEXT,
        hora_fin TEXT,
        completado INTEGER DEFAULT 0,
        FOREIGN KEY (proceso_id) REFERENCES $tableProcesos (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de trabajo adicional
    await db.execute('''
      CREATE TABLE $tableTrabajoAdicional (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proceso_id INTEGER NOT NULL,
        secuencia_id INTEGER NOT NULL,
        instruccion TEXT NOT NULL,
        producto TEXT,
        temperatura REAL,
        tiempo INTEGER,
        observacion TEXT,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (proceso_id) REFERENCES $tableProcesos (id) ON DELETE CASCADE,
        FOREIGN KEY (secuencia_id) REFERENCES $tableSecuencias (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de productos (cache local)
    await db.execute('''
      CREATE TABLE $tableProductos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        ultima_actualizacion TEXT NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_procesos_nrop ON $tableProcesos (nrOp)');
    await db.execute('CREATE INDEX idx_procesos_pesaje ON $tableProcesos (numeroPesaje)');
    await db.execute('CREATE INDEX idx_secuencias_proceso ON $tableSecuencias (proceso_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar nuevas columnas si es necesario
      await db.execute('ALTER TABLE $tableProcesos ADD COLUMN sincronizado INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $tableSecuencias ADD COLUMN completado INTEGER DEFAULT 0');
    }
  }

  // Métodos para Procesos

  Future<int> insertProceso(Map<String, dynamic> proceso) async {
    final db = await database;
    return await db.insert(tableProcesos, proceso);
  }

  Future<Map<String, dynamic>?> getProceso(int id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      tableProcesos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllProcesos() async {
    final db = await database;
    return await db.query(
      tableProcesos,
      orderBy: 'fecha_guardado DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getProcesosByFecha(DateTime fecha) async {
    final db = await database;
    String fechaStr = fecha.toIso8601String().split('T')[0];
    return await db.query(
      tableProcesos,
      where: "date(fecha_proceso) = ?",
      whereArgs: [fechaStr],
      orderBy: 'fecha_guardado DESC'
    );
  }

  Future<int> updateProceso(int id, Map<String, dynamic> proceso) async {
    final db = await database;
    return await db.update(
      tableProcesos,
      proceso,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProceso(int id) async {
    final db = await database;
    return await db.delete(
      tableProcesos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para Secuencias

  Future<int> insertSecuencia(Map<String, dynamic> secuencia) async {
    final db = await database;
    return await db.insert(tableSecuencias, secuencia);
  }

  Future<List<Map<String, dynamic>>> getSecuenciasByProceso(int procesoId) async {
    final db = await database;
    return await db.query(
      tableSecuencias,
      where: 'proceso_id = ?',
      whereArgs: [procesoId],
      orderBy: 'secuencia ASC'
    );
  }

  Future<int> updateSecuencia(int id, Map<String, dynamic> secuencia) async {
    final db = await database;
    return await db.update(
      tableSecuencias,
      secuencia,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> completarSecuencia(int id, DateTime horaFin) async {
    final db = await database;
    return await db.update(
      tableSecuencias,
      {
        'completado': 1,
        'hora_fin': horaFin.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para Trabajo Adicional

  Future<int> insertTrabajoAdicional(Map<String, dynamic> trabajo) async {
    final db = await database;
    trabajo['fecha_creacion'] = DateTime.now().toIso8601String();
    return await db.insert(tableTrabajoAdicional, trabajo);
  }

  Future<List<Map<String, dynamic>>> getTrabajoAdicionalBySecuencia(int secuenciaId) async {
    final db = await database;
    return await db.query(
      tableTrabajoAdicional,
      where: 'secuencia_id = ?',
      whereArgs: [secuenciaId],
      orderBy: 'fecha_creacion ASC'
    );
  }

  // Métodos para Productos

  Future<int> insertProducto(Map<String, dynamic> producto) async {
    final db = await database;
    producto['ultima_actualizacion'] = DateTime.now().toIso8601String();
    return await db.insert(
      tableProductos,
      producto,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllProductos() async {
    final db = await database;
    return await db.query(tableProductos, orderBy: 'nombre ASC');
  }

  // Métodos para Reportes

  Future<Map<String, dynamic>> getReporteCompleto(int procesoId) async {
    final db = await database;
    final proceso = await getProceso(procesoId);
    if (proceso == null) throw Exception('Proceso no encontrado');

    final secuencias = await getSecuenciasByProceso(procesoId);
    final trabajosAdicionales = await db.query(
      tableTrabajoAdicional,
      where: 'proceso_id = ?',
      whereArgs: [procesoId],
    );

    return {
      'proceso': proceso,
      'secuencias': secuencias,
      'trabajos_adicionales': trabajosAdicionales,
    };
  }

  Future<List<Map<String, dynamic>>> getReportesPendientesSincronizar() async {
    final db = await database;
    return await db.query(
      tableProcesos,
      where: 'sincronizado = 0',
    );
  }

  // Métodos de utilidad

  Future<void> marcarProcesoSincronizado(int procesoId) async {
    final db = await database;
    await db.update(
      tableProcesos,
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [procesoId],
    );
  }

  Future<String> backupDatabase() async {
    final db = await database;
    await db.close();
    
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'formulaciones.db');
    
    // Aquí puedes implementar la lógica para crear una copia de seguridad
    // Por ejemplo, copiar el archivo a otro directorio o enviarlo a un servidor
    
    // Reabrir la base de datos
    _db = null;
    await database;
    
    return dbPath;
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableTrabajoAdicional);
      await txn.delete(tableSecuencias);
      await txn.delete(tableProcesos);
      await txn.delete(tableProductos);
    });
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}