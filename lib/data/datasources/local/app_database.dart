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

      // ✅ VERSIÓN ACTUALIZADA A 3
      return await openDatabase(
        path,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'No se pudo inicializar la base de datos: ${e.toString()}',
      );
    }
  }

  FutureOr<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE table_subjects (
        id $idType,
        name $textType,
        exam_date $textType,
        created_at $textType,
        is_active $intType DEFAULT 0,
        pdf_replaced $intType DEFAULT 0
      )
    ''');

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

    await db.execute('''
      CREATE TABLE table_questions (
        id $idType,
        subject_id INTEGER,
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

    await db.execute('''
      CREATE TABLE table_study_logs (
        id $idType,
        question_id $intType,
        is_correct $intType,
        answered_at $textType,
        FOREIGN KEY (question_id) REFERENCES table_questions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE table_blocked_apps (
        id $idType,
        subject_id $intType,
        package_name $textType,
        FOREIGN KEY (subject_id) REFERENCES table_subjects (id) ON DELETE CASCADE
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE table_blocked_apps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_id INTEGER NOT NULL,
          package_name TEXT NOT NULL,
          FOREIGN KEY (subject_id) REFERENCES table_subjects (id) ON DELETE CASCADE
        )
      ''');
    }

    // ✅ NUEVA MIGRACIÓN: Añade la columna para controlar el reemplazo único del PDF
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE table_subjects ADD COLUMN pdf_replaced INTEGER DEFAULT 0',
      );
    }
  }
}
