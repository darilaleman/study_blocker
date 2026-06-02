import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:study_blocker/core/errors/exceptions.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('study_blocker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(path, version: 1, onCreate: _createDB);
    } catch (e) {
      throw DatabaseException(
        message:
            'No se pudo inicializar el almacenamiento de la base de datos: ${e.toString()}',
      );
    }
  }

  FutureOr<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // 1. TABLA DE PREGUNTAS (Con la columna 'repetitions' añadida de forma nativa)
    await db.execute('''
      CREATE TABLE table_questions (
        id $idType,
        question $textType,
        options $textType,       
        correct_answer $textType,
        subject $textType,          
        next_review $textType,     
        interval $intType,         
        ease_factor $realType,
        repetitions $intType      -- <-- CORRECCIÓN: Columna física mapeada en SQLite
      )
    ''');

    // 2. TABLA DE HISTORIAL DE RESPUESTAS
    await db.execute('''
      CREATE TABLE table_study_logs (
        id $idType,
        question_id $intType,
        is_correct $intType,       
        answered_at $textType,     
        FOREIGN KEY (question_id) REFERENCES table_questions (id) ON DELETE CASCADE
      )
    ''');
  }
}
