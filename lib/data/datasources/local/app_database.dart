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

    // 1. TABLA DE ASIGNATURAS (ACTUALIZADA)
    await db.execute('''
      CREATE TABLE table_subjects (
        id $idType,
        name $textType,
        exam_date $textType,
        created_at $textType,
        is_active $intType DEFAULT 0 -- 0 = inactiva, 1 = activa
      )
    ''');

    // 2. TABLA DE DOCUMENTOS PDF (NUEVA)
    await db.execute('''
      CREATE TABLE table_pdf_documents (
        id $idType,
        subject_id $intType,
        file_path $textType,
        page_count $intType,
        uploaded_at $textType,
        FOREIGN KEY (subject_id) REFERENCES table_subjects (id) ON DELETE CASCADE
      )
    ''');

    // 3. TABLA DE PREGUNTAS (Añadido subject_id como llave foránea opcional)
    await db.execute('''
      CREATE TABLE table_questions (
        id $idType,
        subject_id INTEGER, -- Puede ser nulo por retrocompatibilidad
        question $textType,
        options $textType,       
        correct_answer $textType,
        subject $textType,          
        next_review $textType,     
        interval $intType,         
        ease_factor $realType,
        repetitions $intType,
        FOREIGN KEY (subject_id) REFERENCES table_subjects (id) ON DELETE CASCADE
      )
    ''');

    // 4. TABLA DE HISTORIAL DE RESPUESTAS
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
