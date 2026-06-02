import 'package:dartz/dartz.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/domain/entities/blocked_app.dart';

/// Contrato abstracto que define las operaciones permitidas sobre el bloqueo
/// de aplicaciones y sincronización de permisos del sistema operativo.
///
/// Pertenece exclusivamente a la capa de Dominio.
abstract class AppBlockRepository {
  /// Obtiene la lista completa de aplicaciones que están instaladas en el
  /// dispositivo y que el usuario es elegible para bloquear.
  Future<Either<Failure, List<BlockedApp>>> getAvailableApplications();

  /// Actualiza la lista de aplicaciones que deben ser bloqueadas activamente por el sistema.
  ///
  /// Recibe un arreglo de [appsToBlock]. Si el usuario supera las limitaciones de su plan,
  /// este método retornará un [SubscriptionFailure].
  Future<Either<Failure, void>> updateBlockedApplications(
    List<BlockedApp> appsToBlock,
  );

  /// Concede un acceso temporal levantando las restricciones del sistema operativo.
  ///
  /// [durationMinutes] especifica cuántos minutos de tregua tiene el usuario
  /// antes de que el Foreground Service o la API nativa reactiven el bloqueo.
  Future<Either<Failure, void>> grantTemporaryAccess(int durationMinutes);

  /// Verifica el estado actual de los permisos nativos (Accesibilidad, Superposición o FamilyControls)
  /// y los sincroniza con el estado de la aplicación.
  ///
  /// Retorna `true` si todos los permisos requeridos están activos y funcionales.
  Future<Either<Failure, bool>> checkAndSyncPermissions();
}
