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
}

/// IMPLEMENTACIÓN CONCRETA
class QuestionLocalDataSourceImpl implements QuestionLocalDataSource {
  final AppDatabase appDatabase;

  QuestionLocalDataSourceImpl({required this.appDatabase});

  @override // Añadido para seguir las buenas prácticas
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

  @override // Añadido para seguir las buenas prácticas
  Future<QuestionModel> getRandomPendingQuestion() async {
    try {
      final db = await appDatabase.database;
      final nowStr = DateTime.now().toIso8601String();

      // Intenta obtener primero las vencidas por repetición espaciada
      List<Map<String, dynamic>> maps = await db.query(
        'table_questions',
        where: 'next_review <= ?',
        whereArgs: [nowStr],
        orderBy: 'RANDOM()',
        limit: 1,
      );

      // Si no hay ninguna pendiente, obtiene cualquier pregunta de la base de datos al azar
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

      // Respetamos estrictamente las columnas existentes en el script de creación de SQLite
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

      if (firstLogDate != todayStr && firstLogDate != yesterdayStr) {
        return 0;
      }

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
  Future<int> getTodayAnsweredCount() async {
    try {
      final db = await appDatabase.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as total 
        FROM table_study_logs 
        WHERE substr(answered_at, 1, 10) = ?
      ''',
        [todayStr],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException(message: 'Error al obtener conteo diario: $e');
    }
  }
}
