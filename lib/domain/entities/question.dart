import 'package:equatable/equatable.dart';

/// Representa una pregunta del cuestionario generada por la IA a partir de un PDF.
///
/// Contiene tanto los datos de visualización para la interfaz de usuario como las
/// métricas matemáticas necesarias para el algoritmo de repetición espaciada.
class Question extends Equatable {
  final int? id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String subject; // Permite agrupar preguntas por PDF o Materia

  // Métricas del Algoritmo de Aprendizaje (SuperMemo SM2)
  final DateTime nextReview; // Cuándo debe volver a aparecer la pregunta
  final int
  interval; // Intervalo actual en días (0 significa que se repite hoy)
  final double
  easeFactor; // Factor de facilidad/dificultad de la pregunta (Multiplicador)
  final int repetitions; // Número de repeticiones consecutivas exitosas

  const Question({
    this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.subject,
    required this.nextReview,
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
  });

  @override
  List<Object?> get props => [
    id,
    question,
    options,
    correctAnswer,
    subject,
    nextReview,
    interval,
    easeFactor,
    repetitions,
  ];

  @override
  String toString() =>
      'Question(id: $id, question: $question, interval: $interval, easeFactor: $easeFactor, repetitions: $repetitions)';
}
