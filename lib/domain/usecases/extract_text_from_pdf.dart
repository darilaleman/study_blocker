import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';

/// Caso de Uso encargado de abrir un archivo PDF local mediante su ruta,
/// extraer su contenido en texto plano y prepararlo para la IA.
class ExtractTextFromPdf implements UseCase<String, ExtractTextFromPdfParams> {
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

      final doc = await PDFDoc.fromPath(params.pdfPath);
      final text = await doc.text;

      if (text.trim().isEmpty) {
        return const Left(
          CacheFailure(
            message:
                'No se pudo extraer texto del PDF. El archivo puede estar protegido o vacío.',
          ),
        );
      }

      return Right(text);
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
  final String pdfPath;

  const ExtractTextFromPdfParams({required this.pdfPath});

  @override
  List<Object?> get props => [pdfPath];
}
