import 'package:dartz/dartz.dart';
import 'package:study_blocker/core/errors/exceptions.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/utils/sm2_algorithm.dart'; // Importamos tu utilidad del core
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/data/datasources/remote/ai_quiz_remote_datasource.dart';
import 'package:study_blocker/domain/entities/question.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionLocalDataSource localDataSource;
  final AiQuizRemoteDataSource remoteDataSource;

  QuestionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, void>> generateAndSaveQuizFromPdf({
    required String pdfText,
    required String subject,
  }) async {
    try {
      final remoteQuestions = await remoteDataSource.generateQuizFromText(
        pdfText: pdfText,
        subject: subject,
      );

      await localDataSource.insertQuestions(remoteQuestions);
      return const Right(null);
    } on AiGenerationException catch (e) {
      return Left(AiGenerationFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Question>> getRandomQuestionForLockscreen() async {
    try {
      final questionModel = await localDataSource.getRandomPendingQuestion();
      return Right(questionModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> processUserAnswer({
    required Question question,
    required String userAnswer,
  }) async {
    try {
      final isCorrect =
          question.correctAnswer.trim().toLowerCase() ==
          userAnswer.trim().toLowerCase();
      final now = DateTime.now();

      // 1. Registrar el intento en el historial (Logs)
      await localDataSource.insertStudyLog(
        question.id!,
        isCorrect,
        now.toIso8601String(),
      );

      // 2. DELEGACIÓN ABSOLUTA AL ALGORITMO CENTRALIZADO (Sm2Algorithm)
      // Mapeo estándar: 5 para respuesta perfecta, 1 para fallo/reinicio
      final int quality = isCorrect ? 5 : 1;

      final sm2Result = Sm2Algorithm.calculate(
        previousInterval: question.interval,
        previousEaseFactor: question.easeFactor,
        repetitions: question.repetitions,
        quality: quality,
      );

      final int nextInterval = sm2Result['interval'] as int;
      final double nextEaseFactor = sm2Result['ease_factor'] as double;

      // 3. Calcular fecha exacta de revisión basándonos en el nuevo intervalo obtenido
      // Si nextInterval es 0 (o el algoritmo estipula revisión inmediata corta) aplicamos 1 hora, de lo contrario sumamos días.
      final DateTime nextReviewDate = nextInterval == 0
          ? now.add(const Duration(hours: 1))
          : now.add(Duration(days: nextInterval));

      // 4. Persistir métricas actualizadas en SQLite (incluyendo el nuevo conteo de repeticiones)
      // Nota: Recuerda agregar el parámetro de repeticiones en la firma de tu data source si no existía.
      await localDataSource.updateQuestionReviewData(
        questionId: question.id!,
        nextReview: nextReviewDate.toIso8601String(),
        interval: nextInterval,
        easeFactor: nextEaseFactor,
      );

      return Right(isCorrect);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStudyStats() async {
    try {
      final streak = await localDataSource.getCurrentStreak();
      final todayCount = await localDataSource.getTodayAnsweredCount();

      return Right({
        'current_streak': streak,
        'today_answered_count': todayCount,
        'has_studied_enough_today': todayCount >= 10,
      });
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
