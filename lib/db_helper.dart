// db_helper.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  // Método para obtener la instancia de la base de datos
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  // Inicialización de la base de datos
  Future<Database> initDB() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'procesos.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await createTables(db);
      },
    );
  }

  // Creación de las tablas: 'procesos' y 'secuencias'
  Future<void> createTables(Database db) async {
    await db.execute("""
      CREATE TABLE procesos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nrOp INTEGER,
        maquina TEXT,
        producto TEXT,
        fecha_guardado TEXT,
        fecha_proceso TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE secuencias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proceso_id INTEGER,
        secuencia REAL,
        instruccion TEXT,
        producto TEXT,
        temperatura REAL,
        tiempo INTEGER,
        ctd_explosion REAL,
        observacion TEXT,
        codigo_escaneado TEXT,
        FOREIGN KEY (proceso_id) REFERENCES procesos (id)
      )
    """);
  }

  // Inserta un registro en la tabla 'procesos'
  Future<int> insertProceso(Map<String, dynamic> proceso) async {
    final db = await database;
    return await db.insert('procesos', proceso);
  }

  // Inserta un registro en la tabla 'secuencias'
  Future<int> insertSecuencia(Map<String, dynamic> secuencia) async {
    final db = await database;
    return await db.insert('secuencias', secuencia);
  }

  // Obtiene todos los procesos guardados
  Future<List<Map<String, dynamic>>> getProcesos() async {
    final db = await database;
    return await db.query('procesos');
  }

  // Obtiene las secuencias asociadas a un proceso
  Future<List<Map<String, dynamic>>> getSecuencias(int procesoId) async {
    final db = await database;
    return await db.query('secuencias', where: 'proceso_id = ?', whereArgs: [procesoId]);
  }

  // Limpia (elimina) todos los datos de las tablas
  Future<int> deleteAllData() async {
    final db = await database;
    int deletedSecuencias = await db.delete('secuencias');
    int deletedProcesos = await db.delete('procesos');
    return deletedSecuencias + deletedProcesos;
  }
}