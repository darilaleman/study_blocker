import 'dart:convert';
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
      // Simulación de respuesta JSON de la Inteligencia Artificial
      const mockResponseBody = '''
      [
        {
          "question": "¿Cuál es la principal ventaja de utilizar Clean Architecture en un proyecto de Flutter?",
          "options": [
            "Aumenta la velocidad de renderizado de los widgets",
            "Permite desacoplar la lógica de negocio de los detalles de infraestructura",
            "Reduce automáticamente el tamaño del APK final",
            "Elimina la necesidad de utilizar gestores de estado"
          ],
          "correct_answer": "Permite desacoplar la lógica de negocio de los detalles de infraestructura"
        },
        {
          "question": "¿Qué capa de Clean Architecture debe permanecer completamente pura e independiente de los frameworks?",
          "options": [
            "Capa de Presentación",
            "Capa de Datos",
            "Capa de Dominio",
            "Capa de Dispositivo"
          ],
          "correct_answer": "Capa de Dominio"
        }
      ]
      ''';

      final List<dynamic> decodedJson = jsonDecode(mockResponseBody);

      return decodedJson.map((map) {
        final extendedMap = Map<String, dynamic>.from(map);
        extendedMap['subject'] = subject;

        // Metadatos iniciales para el algoritmo SM2 en la creación de la tarjeta
        extendedMap['next_review'] = DateTime.now().toIso8601String();
        extendedMap['interval'] = 0;
        extendedMap['ease_factor'] = 2.5;
        extendedMap['repetitions'] =
            0; // <-- CORRECCIÓN: Nace con 0 repeticiones consecutivas

        return QuestionModel.fromMap(extendedMap);
      }).toList();
    } catch (e) {
      throw AiGenerationException(
        message:
            'Error al decodificar o estructurar el quiz de la IA: ${e.toString()}',
      );
    }
  }
}
