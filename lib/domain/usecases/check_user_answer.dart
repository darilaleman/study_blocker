import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/domain/entities/question.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';

/// Caso de Uso encargado de evaluar la respuesta introducida por el usuario,
/// registrar el intento en el historial y reprogramar la pregunta según el algoritmo científico.
class CheckUserAnswer implements UseCase<bool, CheckUserAnswerParams> {
  final QuestionRepository repository;

  CheckUserAnswer(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckUserAnswerParams params) async {
    // Orquesta la validación y actualización matemática del estado de la pregunta.
    // Retorna true si el usuario acertó, false si falló.
    return await repository.processUserAnswer(
      question: params.question,
      userAnswer: params.userAnswer,
    );
  }
}

/// Parámetros requeridos por este caso de uso para procesar el intento de estudio.
class CheckUserAnswerParams extends Equatable {
  final Question question;
  final String userAnswer;

  const CheckUserAnswerParams({
    required this.question,
    required this.userAnswer,
  });

  @override
  List<Object?> get props => [question, userAnswer];
}
