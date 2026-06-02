import 'package:dartz/dartz.dart';
import 'package:study_blocker/core/errors/exceptions.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/data/datasources/device/screen_time_device_datasource.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/data/models/blocked_app_model.dart';
import 'package:study_blocker/domain/entities/blocked_app.dart';
import 'package:study_blocker/domain/repositories/app_block_repository.dart';

class AppBlockRepositoryImpl implements AppBlockRepository {
  final ScreenTimeDeviceDataSource deviceDataSource;
  final AppConfigLocalDataSource localDataSource;

  AppBlockRepositoryImpl({
    required this.deviceDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<BlockedApp>>> getAvailableApplications() async {
    try {
      // 1. Obtener los mapas crudos del dispositivo (TikTok, Instagram, etc.)
      final appMaps = await deviceDataSource.getInstalledApplications();

      // 2. Parsearlos adaptando de forma segura las llaves 'camelCase' del OS al 'snake_case' del Modelo
      final applications = appMaps.map((map) {
        return BlockedAppModel.fromMap({
          'id': map['id'], // Por si el canal nativo llega a indexar un id
          'package_name': map['packageName'] ?? map['package_name'] ?? '',
          'app_name': map['appName'] ?? map['app_name'] ?? 'App Desconocida',
        });
      }).toList();

      return Right(applications);
    } on DevicePermissionException catch (e) {
      return Left(DevicePermissionFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBlockedApplications(
    List<BlockedApp> selectedApplications,
  ) async {
    try {
      // 1. Convertir la lista de entidades a modelos estructurados
      final models = selectedApplications
          .map((entity) => BlockedAppModel.fromEntity(entity))
          .toList();

      // 2. Extraer solo los nombres de los paquetes (packageNames) para persistencia local y OS
      final packageNames = models.map((m) => m.packageName).toList();

      // 3. Guardar las configuraciones locales de la app
      await localDataSource.setBlockedApps(packageNames);

      // 4. Ordenarle al sistema operativo que ejecute el bloqueo de inmediato
      await deviceDataSource.blockApplications(packageNames);

      return const Right(null);
    } on DevicePermissionException catch (e) {
      return Left(DevicePermissionFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> grantTemporaryAccess(
    int durationMinutes,
  ) async {
    try {
      // Ordena al sistema operativo levantar las restricciones por los minutos ganados
      await deviceDataSource.temporaryUnlock(durationMinutes);
      return const Right(null);
    } on DevicePermissionException catch (e) {
      return Left(DevicePermissionFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAndSyncPermissions() async {
    try {
      final hasPermissions = await deviceDataSource.checkSystemPermissions();
      return Right(hasPermissions);
    } on DevicePermissionException catch (e) {
      return Left(DevicePermissionFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
