import 'package:dartz/dartz.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/domain/entities/question.dart';

/// Contrato abstracto que define las reglas de negocio para el manejo de preguntas,
/// procesamiento con Inteligencia Artificial y métricas de aprendizaje.
abstract class QuestionRepository {
  /// Toma el texto extraído de un documento PDF y lo envía a la IA para
  /// estructurar, parsear y almacenar un nuevo banco de preguntas localmente.
  Future<Either<Failure, void>> generateAndSaveQuizFromPdf({
    required String pdfText,
    required String subject,
  });

  /// Extrae una única pregunta del almacenamiento para mostrarla en la pantalla de bloqueo.
  Future<Either<Failure, Question>> getRandomQuestionForLockscreen();

  /// Evalúa la respuesta otorgada por el estudiante contra la respuesta correcta de la entidad.
  Future<Either<Failure, bool>> processUserAnswer({
    required Question question,
    required String userAnswer,
  });

  /// Recupera un mapa con las métricas acumuladas de estudio del usuario actual.
  Future<Either<Failure, Map<String, dynamic>>> getStudyStats();
}
