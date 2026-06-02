import 'dart:convert';
import 'package:study_blocker/domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    super.id,
    required super.question,
    required super.options,
    required super.correctAnswer,
    required super.subject,
    required super.nextReview,
    required super.interval,
    required super.easeFactor,
    required super.repetitions, // <-- Añadido al constructor del modelo
  });

  /// Crea una instancia de este Modelo a partir de una Entidad del Dominio.
  factory QuestionModel.fromEntity(Question entity) {
    return QuestionModel(
      id: entity.id,
      question: entity.question,
      options: entity.options,
      correctAnswer: entity.correctAnswer,
      subject: entity.subject,
      nextReview: entity.nextReview,
      interval: entity.interval,
      easeFactor: entity.easeFactor,
      repetitions: entity.repetitions, // <-- Mapeo de entidad a modelo
    );
  }

  /// Convierte el Modelo en un Map (Key-Value) estructurado para SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'question': question,
      'options': jsonEncode(options),
      'correct_answer': correctAnswer,
      'subject': subject,
      'next_review': nextReview.toIso8601String(),
      'interval': interval,
      'ease_factor': easeFactor,
      'repetitions': repetitions, // <-- Se añade al mapa de inserción de SQLite
    };
  }

  /// Construye el Modelo a partir de un Map proveniente de la base de datos.
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'] as String;
    final List<dynamic> optionsDecoded = jsonDecode(optionsRaw);
    final List<String> optionsList = optionsDecoded
        .map((e) => e.toString())
        .toList();

    return QuestionModel(
      id: map['id'] as int?,
      question: map['question'] as String,
      options: optionsList,
      correctAnswer: map['correct_answer'] as String,
      subject: map['subject'] as String,
      nextReview: DateTime.parse(map['next_review'] as String),
      interval: map['interval'] as int,
      easeFactor: (map['ease_factor'] as num).toDouble(),
      repetitions:
          map['repetitions'] as int? ??
          0, // <-- Extrae el valor de la BD de forma segura
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QuestionModel.fromJson(String source) =>
      QuestionModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
