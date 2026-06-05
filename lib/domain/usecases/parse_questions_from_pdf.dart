import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/data/models/question_model.dart';

class ParseQuestionsFromPdf
    implements UseCase<List<QuestionModel>, ParseQuestionsParams> {
  const ParseQuestionsFromPdf();

  @override
  Future<Either<Failure, List<QuestionModel>>> call(
    ParseQuestionsParams params,
  ) async {
    try {
      final text = params.pdfText;
      final questions = <QuestionModel>[];

      // Regex para encontrar preguntas numeradas (ej: "1. ¿Cuál es...?")
      final questionRegex = RegExp(
        r'(\d+)\.\s+(.+?)(?=\n\s*[a-dA-D]\))',
        dotAll: true,
      );
      // Regex para encontrar las opciones y detectar si tienen el símbolo de correcto
      final optionRegex = RegExp(
        r'([a-dA-D])\)\s+(.+?)(?=\n\s*[a-dA-D]\)|\n\d+\.|\Z)',
        dotAll: true,
      );

      final questionMatches = questionRegex.allMatches(text);

      for (final match in questionMatches) {
        final questionText = match
            .group(2)!
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ');
        final optionsStart = match.end;

        // Encontrar el final del bloque de opciones (siguiente pregunta o fin del texto)
        final allQuestions = questionRegex.allMatches(text).toList();
        final currentIndex = allQuestions.indexOf(match);
        final nextQuestion = (currentIndex + 1 < allQuestions.length)
            ? allQuestions[currentIndex + 1]
            : null;
        final optionsEnd = nextQuestion?.start ?? text.length;

        final optionsBlock = text.substring(optionsStart, optionsEnd);
        final options = <String>[];
        String? correctAnswer;

        for (final optMatch in optionRegex.allMatches(optionsBlock)) {
          final optionText = optMatch
              .group(2)!
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ');
          // Detectamos la respuesta correcta por ✓, ✔ o *
          final isCorrect =
              optionText.contains('✓') ||
              optionText.contains('✔') ||
              optionText.contains('*');

          final cleanOption = optionText
              .replaceAll(RegExp(r'[✓✔*]'), '')
              .trim();
          options.add(cleanOption);

          if (isCorrect) {
            correctAnswer = cleanOption;
          }
        }

        // Validamos que tenga al menos 2 opciones y una respuesta correcta identificada
        if (options.length >= 2 && correctAnswer != null) {
          questions.add(
            QuestionModel(
              question: questionText,
              options: options,
              correctAnswer: correctAnswer,
              subject: params.subject,
              nextReview: DateTime.now(),
              interval: 0,
              easeFactor: 2.5,
              repetitions: 0,
            ),
          );
        }
      }

      if (questions.isEmpty) {
        return const Left(
          CacheFailure(
            message:
                'No se encontraron preguntas con el formato correcto. Por favor, usa la plantilla proporcionada y asegúrate de marcar la respuesta correcta con ✓.',
          ),
        );
      }

      return Right(questions);
    } catch (e) {
      return Left(CacheFailure(message: 'Error al parsear preguntas: $e'));
    }
  }
}

class ParseQuestionsParams extends Equatable {
  final String pdfText;
  final String subject;

  const ParseQuestionsParams({required this.pdfText, required this.subject});

  @override
  List<Object?> get props => [pdfText, subject];
}
