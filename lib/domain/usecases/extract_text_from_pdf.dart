import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';

/// Caso de Uso encargado de abrir un archivo PDF local mediante su ruta,
/// extraer su contenido en texto plano y prepararlo para la IA.
class ExtractTextFromPdf implements UseCase<String, ExtractTextFromPdfParams> {
  // Nota: Si en el futuro decides crear un PdfRepository dedicado, lo inyectas aquí.
  // Por ahora, como el fin último de extraer texto es generar preguntas,
  // podemos usar el repositorio de preguntas si este implementa dicha extracción,
  // o definir el contrato aquí mismo.

  const ExtractTextFromPdf();

  @override
  Future<Either<Failure, String>> call(ExtractTextFromPdfParams params) async {
    try {
      if (params.pdfPath.isEmpty) {
        return const Left(
          CacheFailure(
            message: 'La ruta del archivo PDF no puede estar vacía.',
          ),
        );
      }

      // TODO: Implementar la lectura real del PDF usando tu plugin preferido.
      // Ejemplo simulado de flujo de extracción:
      // final File file = File(params.pdfPath);
      // final String extractedText = await PdfTextReader.readTxt(file.path);

      print(
        'SISTEMA LOCAL: Extrayendo texto del PDF en la ruta: ${params.pdfPath}',
      );
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulación de lectura de disco

      const mockExtractedText =
          'Este es el texto resumido extraído del archivo PDF de estudio sobre Clean Architecture y algoritmos.';

      return const Right(mockExtractedText);
    } catch (e) {
      return Left(
        CacheFailure(
          message:
              'Error al intentar leer o extraer el texto del PDF: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parámetros requeridos para poder ejecutar la extracción de texto.
class ExtractTextFromPdfParams extends Equatable {
  final String
  pdfPath; // Ruta local del archivo en el dispositivo (ej: '/cache/documento.pdf')

  const ExtractTextFromPdfParams({required this.pdfPath});

  @override
  List<Object?> get props => [pdfPath];
}
