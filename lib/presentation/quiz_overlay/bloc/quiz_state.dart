import 'package:equatable/equatable.dart';
import 'package:study_blocker/domain/entities/question.dart';

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

/// La pregunta se ha recuperado con éxito y está lista en la UI.
class QuizQuestionLoaded extends QuizState {
  final Question question;

  const QuizQuestionLoaded({required this.question});

  @override
  List<Object?> get props => [question];
}

/// Estado emitido inmediatamente después de evaluar la respuesta del usuario.
class QuizAnswerResult extends QuizState {
  final bool isCorrect;
  final String correctAnswer;

  const QuizAnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
  });

  @override
  List<Object?> get props => [isCorrect, correctAnswer];
}

class QuizError extends QuizState {
  final String message;

  const QuizError({required this.message});

  @override
  List<Object?> get props => [message];
}
