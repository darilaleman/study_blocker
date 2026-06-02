import 'package:dartz/dartz.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/domain/entities/question.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';

/// Caso de Uso encargado de obtener una pregunta del banco de datos local
/// para ser presentada de forma inmediata en la interfaz de la pantalla de bloqueo.
///
/// Al no requerir parámetros de entrada, implementa la firma base usando [NoParams].
class GetRandomQuestion implements UseCase<Question, NoParams> {
  final QuestionRepository repository;

  GetRandomQuestion(this.repository);

  @override
  Future<Either<Failure, Question>> call(NoParams params) async {
    // El repositorio se encarga de aplicar el query SQL que prioriza
    // las preguntas vencidas en su fecha de revisión científica (nextReview).
    return await repository.getRandomQuestionForLockscreen();
  }
}
