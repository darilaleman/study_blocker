import 'package:equatable/equatable.dart';
import 'package:study_blocker/domain/entities/question.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

/// Disparado por la pantalla de bloqueo para solicitar una pregunta vencida del SM2.
class FetchQuizQuestion extends QuizEvent {}

/// Disparado cuando el estudiante selecciona una de las opciones de opción múltiple.
class SubmitQuizAnswer extends QuizEvent {
  final Question question;
  final String selectedAnswer;

  const SubmitQuizAnswer({
    required this.question,
    required this.selectedAnswer,
  });

  @override
  List<Object?> get props => [question, selectedAnswer];
}
