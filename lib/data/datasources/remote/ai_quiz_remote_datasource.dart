import 'package:study_blocker/core/errors/exceptions.dart';
import 'package:study_blocker/data/models/question_model.dart';

abstract class AiQuizRemoteDataSource {
  Future<List<QuestionModel>> generateQuizFromText({
    required String pdfText,
    required String subject,
  });
}

class AiQuizRemoteDataSourceImpl implements AiQuizRemoteDataSource {
  AiQuizRemoteDataSourceImpl();

  @override
  Future<List<QuestionModel>> generateQuizFromText({
    required String pdfText,
    required String subject,
  }) async {
    try {
      final cleanedText = pdfText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanedText.isEmpty) {
        throw AiGenerationException(
          message: 'El texto del PDF no contiene contenido válido.',
        );
      }

      final sentences = _extractSentences(
        cleanedText,
      ).where((sentence) => sentence.length >= 40).toList();

      if (sentences.isEmpty) {
        throw AiGenerationException(
          message:
              'No se pudieron generar preguntas porque el texto es muy corto.',
        );
      }

      final uniqueSentences = sentences.toSet().toList();
      final questions = <QuestionModel>[];
      final candidates = uniqueSentences.take(6).toList();

      for (
        var index = 0;
        index < candidates.length && questions.length < 3;
        index++
      ) {
        final correctSentence = candidates[index];
        final answerOptions = _buildOptions(correctSentence, candidates);

        questions.add(
          QuestionModel(
            question:
                '¿Cuál de las siguientes oraciones aparece en el texto extraído del PDF?',
            options: answerOptions,
            correctAnswer: correctSentence,
            subject: subject,
            nextReview: DateTime.now(),
            interval: 0,
            easeFactor: 2.5,
            repetitions: 0,
          ),
        );
      }

      if (questions.isEmpty) {
        throw AiGenerationException(
          message:
              'No se pudieron generar preguntas a partir del texto proporcionado.',
        );
      }

      return questions;
    } catch (e) {
      if (e is AiGenerationException) rethrow;
      throw AiGenerationException(
        message:
            'Error al generar preguntas a partir del texto: ${e.toString()}',
      );
    }
  }

  List<String> _extractSentences(String text) {
    final rawSentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    return rawSentences.map((sentence) => sentence.trim()).toList();
  }

  List<String> _buildOptions(String correctSentence, List<String> candidates) {
    final options = <String>[correctSentence];
    for (final sentence in candidates) {
      if (options.length >= 4) break;
      if (sentence == correctSentence) continue;
      final normalized = sentence.length > 120
          ? '${sentence.substring(0, 117)}...'
          : sentence;
      options.add(normalized);
    }

    while (options.length < 4) {
      options.add('No estoy seguro, revisar el material de estudio.');
    }

    options.shuffle();
    return options;
  }
}
