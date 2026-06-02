import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';

/// Caso de Uso encargado de enviar el texto de un documento a la IA para
/// mapear y guardar de forma masiva un lote de preguntas de opción múltiple.
class GenerateQuizWithAi implements UseCase<void, GenerateQuizWithAiParams> {
  final QuestionRepository repository;

  GenerateQuizWithAi(this.repository);

  @override
  Future<Either<Failure, void>> call(GenerateQuizWithAiParams params) async {
    // Validamos lógica de negocio básica en el UseCase antes de disparar la red
    if (params.pdfText.trim().length < 50) {
      return const Left(
        AiGenerationFailure(
          message:
              'El texto extraído es demasiado corto para generar un cuestionario de calidad.',
        ),
      );
    }

    // Delegamos la llamada al repositorio que coordina la petición remota y la persistencia local
    return await repository.generateAndSaveQuizFromPdf(
      pdfText: params.pdfText,
      subject: params.subject,
    );
  }
}

/// Parámetros requeridos por este caso de uso para mandar a procesar la información.
class GenerateQuizWithAiParams extends Equatable {
  final String pdfText; // El texto plano previamente extraído del PDF
  final String
  subject; // Nombre de la asignatura o título del archivo para categorizarlo

  const GenerateQuizWithAiParams({
    required this.pdfText,
    required this.subject,
  });

  @override
  List<Object?> get props => [pdfText, subject];
}
