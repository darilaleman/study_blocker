import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/domain/entities/blocked_app.dart';
import 'package:study_blocker/domain/repositories/app_block_repository.dart';

/// Caso de Uso encargado de guardar y activar el bloqueo de una lista de aplicaciones
/// seleccionadas por el estudiante en el dispositivo.
class BlockApplication implements UseCase<void, BlockApplicationParams> {
  final AppBlockRepository repository;

  BlockApplication(this.repository);

  @override
  Future<Either<Failure, void>> call(BlockApplicationParams params) async {
    // Aquí delegamos la acción al repositorio abstract.
    // La lógica de verificar si el usuario excede su límite de aplicaciones si es Free
    // se resuelve dentro de la implementación del repositorio para mantener el UseCase esbelto.
    return await repository.updateBlockedApplications(params.appsToBlock);
  }
}

/// Parámetros obligatorios requeridos por este caso de uso para poder ejecutarse.
class BlockApplicationParams extends Equatable {
  final List<BlockedApp> appsToBlock;

  const BlockApplicationParams({required this.appsToBlock});

  @override
  List<Object?> get props => [appsToBlock];
}
