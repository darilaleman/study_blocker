// ignore_for_file: override_on_non_overriding_member

import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:study_blocker/core/errors/exceptions.dart';
import 'package:study_blocker/data/datasources/local/app_database.dart';
import 'package:study_blocker/data/models/question_model.dart';

/// CONTRATO ABSTRACTO (Interfaz)
abstract class QuestionLocalDataSource {
  Future<void> insertQuestions(List<QuestionModel> questions);
  Future<QuestionModel> getRandomPendingQuestion();
  Future<void> updateQuestionReviewData({
    required int questionId,
    required String nextReview,
    required int interval,
    required double easeFactor,
    required int repetitions,
  });
  Future<void> insertStudyLog(
    int questionId,
    bool isCorrect,
    String answeredAt,
  );
  Future<int> getCurrentStreak();
  Future<int> getTodayAnsweredCount();

  Future<List<Map<String, dynamic>>> getAllSubjects();
  Future<int> createSubject({required String name, required bool isActive});
  Future<void> updateSubjectActive(int id, bool isActive);
  Future<List<QuestionModel>> getAllQuestions();
  Future<List<QuestionModel>> getQuestionsBySubject(String subject);
  Future<int> countActiveSubjects();
  Future<int> countPdfsForSubject(String subjectName);
  Future<void> saveSubjectAndPdf({
    required String subjectName,
    required DateTime examDate,
    required String filePath,
    required int pageCount,
  });

  // Métodos nuevos para el bloqueo de aplicaciones
  Future<void> saveBlockedApps(int subjectId, List<String> packageNames);
  Future<List<String>> getBlockedAppsForSubject(int subjectId);
}

/// IMPLEMENTACIÓN CONCRETA
class QuestionLocalDataSourceImpl implements QuestionLocalDataSource {
  final AppDatabase appDatabase;

  QuestionLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<void> insertQuestions(List<QuestionModel> questions) async {
    try {
      final db = await appDatabase.database;
      final batch = db.batch();

      for (final question in questions) {
        batch.insert('table_questions', question.toMap());
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw DatabaseException(
        message: 'Error al insertar preguntas en lote: $e',
      );
    }
  }

  @override
  Future<QuestionModel> getRandomPendingQuestion() async {
    try {
      final db = await appDatabase.database;
      final nowStr = DateTime.now().toIso8601String();

      List<Map<String, dynamic>> maps = await db.query(
        'table_questions',
        where: 'next_review <= ?',
        whereArgs: [nowStr],
        orderBy: 'RANDOM()',
        limit: 1,
      );

      if (maps.isEmpty) {
        maps = await db.query('table_questions', orderBy: 'RANDOM()', limit: 1);
      }

      if (maps.isEmpty) {
        throw const CacheException(
          message: 'No hay preguntas disponibles en la base de datos.',
        );
      }

      return QuestionModel.fromMap(maps.first);
    } on CacheException {
      rethrow;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al obtener pregunta aleatoria: $e',
      );
    }
  }

  @override
  Future<void> updateQuestionReviewData({
    required int questionId,
    required String nextReview,
    required int interval,
    required double easeFactor,
    required int repetitions,
  }) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        'table_questions',
        {
          'next_review': nextReview,
          'interval': interval,
          'ease_factor': easeFactor,
          'repetitions': repetitions,
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error al actualizar métricas SM2 de la pregunta: $e',
      );
    }
  }

  @override
  Future<void> insertStudyLog(
    int questionId,
    bool isCorrect,
    String answeredAt,
  ) async {
    try {
      final db = await appDatabase.database;
      await db.insert('table_study_logs', {
        'question_id': questionId,
        'is_correct': isCorrect ? 1 : 0,
        'answered_at': answeredAt,
      });
    } catch (e) {
      throw DatabaseException(message: 'Error al registrar log de estudio: $e');
    }
  }

  @override
  Future<int> getCurrentStreak() async {
    try {
      final db = await appDatabase.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT DISTINCT substr(answered_at, 1, 10) as study_date 
        FROM table_study_logs 
        WHERE is_correct = 1 
        ORDER BY study_date DESC
      ''');

      if (result.isEmpty) return 0;

      int streak = 0;
      DateTime expectedDate = DateTime.now();
      final todayStr = expectedDate.toIso8601String().substring(0, 10);
      final yesterdayStr = expectedDate
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      final firstLogDate = result.first['study_date'] as String;

      if (firstLogDate != todayStr && firstLogDate != yesterdayStr) return 0;
      if (firstLogDate == yesterdayStr) {
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      }

      for (final row in result) {
        final logDateStr = row['study_date'] as String;
        final expectedDateStr = expectedDate.toIso8601String().substring(0, 10);
        if (logDateStr == expectedDateStr) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al calcular la racha de estudio: $e',
      );
    }
  }

  @override
  Future<void> saveBlockedApps(int subjectId, List<String> packageNames) async {
    try {
      final db = await appDatabase.database;
      await db.transaction((txn) async {
        await txn.delete(
          'table_blocked_apps',
          where: 'subject_id = ?',
          whereArgs: [subjectId],
        );
        for (final packageName in packageNames) {
          await txn.insert('table_blocked_apps', {
            'subject_id': subjectId,
            'package_name': packageName,
          });
        }
      });
    } catch (e) {
      throw DatabaseException(message: 'Error al guardar apps bloqueadas: $e');
    }
  }

  @override
  Future<List<String>> getBlockedAppsForSubject(int subjectId) async {
    try {
      final db = await appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'table_blocked_apps',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      return List.generate(
        maps.length,
        (i) => maps[i]['package_name'] as String,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error al recuperar apps bloqueadas: $e',
      );
    }
  }

  @override
  Future<int> countActiveSubjects() async {
    try {
      final db = await appDatabase.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM table_subjects WHERE is_active = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al contar las asignaturas activas: $e',
      );
    }
  }

  @override
  Future<int> countPdfsForSubject(String subjectName) async {
    try {
      final db = await appDatabase.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(pdf.id) as total
        FROM table_pdf_documents pdf
        INNER JOIN table_subjects subj ON subj.id = pdf.subject_id
        WHERE subj.name = ?
      ''',
        [subjectName],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al contar los PDFs de "$subjectName": $e',
      );
    }
  }

  @override
  Future<void> saveSubjectAndPdf({
    required String subjectName,
    required DateTime examDate,
    required String filePath,
    required int pageCount,
  }) async {
    try {
      final db = await appDatabase.database;
      await db.transaction((txn) async {
        final existingSubjects = await txn.query(
          'table_subjects',
          where: 'name = ?',
          whereArgs: [subjectName],
          limit: 1,
        );
        int subjectId;
        final createdAt = DateTime.now().toIso8601String();

        if (existingSubjects.isNotEmpty) {
          subjectId = existingSubjects.first['id'] as int;
          await txn.update(
            'table_subjects',
            {'exam_date': examDate.toIso8601String(), 'is_active': 1},
            where: 'id = ?',
            whereArgs: [subjectId],
          );
        } else {
          subjectId = await txn.insert('table_subjects', {
            'name': subjectName,
            'exam_date': examDate.toIso8601String(),
            'created_at': createdAt,
            'is_active': 1,
          });
        }
        await txn.insert('table_pdf_documents', {
          'subject_id': subjectId,
          'file_path': filePath,
          'page_count': pageCount,
          'uploaded_at': createdAt,
        });
      });
    } catch (e) {
      throw DatabaseException(message: 'Error al guardar PDF: $e');
    }
  }

  @override
  Future<List<QuestionModel>> getAllQuestions() async {
    try {
      final db = await appDatabase.database;
      final rows = await db.query(
        'table_questions',
        orderBy: 'next_review ASC',
      );
      return rows.map(QuestionModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException(message: 'Error al recuperar preguntas: $e');
    }
  }

  @override
  Future<List<QuestionModel>> getQuestionsBySubject(String subject) async {
    try {
      final db = await appDatabase.database;
      final rows = await db.query(
        'table_questions',
        where: 'subject = ?',
        whereArgs: [subject],
        orderBy: 'next_review ASC',
      );
      return rows.map(QuestionModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Error al recuperar preguntas de "$subject": $e',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    try {
      final db = await appDatabase.database;
      return await db.query('table_subjects', orderBy: 'created_at DESC');
    } catch (e) {
      throw DatabaseException(message: 'Error al recuperar asignaturas: $e');
    }
  }

  @override
  Future<int> createSubject({
    required String name,
    required bool isActive,
  }) async {
    try {
      final db = await appDatabase.database;
      final createdAt = DateTime.now().toIso8601String();
      return await db.insert('table_subjects', {
        'name': name,
        'exam_date': createdAt,
        'created_at': createdAt,
        'is_active': isActive ? 1 : 0,
      });
    } catch (e) {
      throw DatabaseException(message: 'Error al crear asignatura: $e');
    }
  }

  @override
  Future<void> updateSubjectActive(int id, bool isActive) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        'table_subjects',
        {'is_active': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException(message: 'Error al actualizar asignatura: $e');
    }
  }

  @override
  Future<int> getTodayAnsweredCount() async {
    try {
      final db = await appDatabase.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM table_study_logs WHERE substr(answered_at, 1, 10) = ?',
        [todayStr],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener conteo diario: $e');
    }
  }
}
