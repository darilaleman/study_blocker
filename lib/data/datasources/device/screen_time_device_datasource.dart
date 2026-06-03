import 'dart:async';
import 'package:study_blocker/core/errors/exceptions.dart';

/// Contrato abstracto para la fuente de datos del dispositivo enfocada en el bloqueo de pantalla.
abstract class ScreenTimeDeviceDataSource {
  /// Obtiene la lista de aplicaciones instaladas en el dispositivo que se pueden bloquear.
  /// Retorna una lista de mapas con la estructura `{'packageName': String, 'appName': String, 'icon': String?}`
  Future<List<Map<String, dynamic>>> getInstalledApplications();

  /// Activa el monitoreo y bloquea de inmediato las aplicaciones especificadas en la lista.
  /// [packageNames] representa los identificadores únicos (ej: 'com.instagram.android').
  Future<void> blockApplications(List<String> packageNames);

  /// Levanta temporalmente el bloqueo de todas las aplicaciones.
  /// [durationMinutes] determina cuánto tiempo tiene el usuario antes de que se reactive el bloqueo.
  Future<void> temporaryUnlock(int durationMinutes);

  /// Verifica si la aplicación cuenta actualmente con los permisos necesarios del sistema
  /// (Accesibilidad / Superposición en Android, o FamilyControls en iOS).
  Future<bool> checkSystemPermissions();
}

/// Implementación concreta que interactúa con el hardware/OS del teléfono.
class ScreenTimeDeviceDataSourceImpl implements ScreenTimeDeviceDataSource {
  // Aquí inyectarías el plugin nativo que elijas, por ejemplo:
  // final FlutterScreenTime _screenTimePlugin;
  // ScreenTimeDeviceDataSourceImpl(this._screenTimePlugin);

  ScreenTimeDeviceDataSourceImpl();

  @override
  Future<bool> checkSystemPermissions() async {
    try {
      // Placeholder: aquí se integraría el plugin nativo para verificar permisos.
      // Ejemplo simulado:
      // final hasPermission = await _screenTimePlugin.checkPermissions();
      // return hasPermission;
      return true;
    } catch (e) {
      throw DevicePermissionException(
        message: 'Fallo al verificar los permisos del sistema: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInstalledApplications() async {
    try {
      // Aquí usarías un plugin como 'device_apps' o 'manager' para listar las apps del usuario.
      // Simulamos un retorno exitoso de prueba:
      return [
        {'packageName': 'com.zhiliaoapp.musically', 'appName': 'TikTok'},
        {'packageName': 'com.instagram.android', 'appName': 'Instagram'},
        {'packageName': 'com.facebook.katana', 'appName': 'Facebook'},
      ];
    } catch (e) {
      throw DatabaseException(
        message:
            'No se pudo leer la lista de aplicaciones instaladas: ${e.toString()}',
        code: 'OS_APP_LIST_ERROR',
      );
    }
  }

  @override
  Future<void> blockApplications(List<String> packageNames) async {
    if (packageNames.isEmpty) return;

    try {
      // 1. Verificar primero si tenemos los permisos activos.
      final hasPermission = await checkSystemPermissions();
      if (!hasPermission) {
        throw const DevicePermissionException();
      }

      // 2. Invocar la API nativa de bloqueo.
      // await _screenTimePlugin.blockApps(packageNames);
      print('SISTEMA NATIVO: Bloqueando las aplicaciones: $packageNames');
    } on DevicePermissionException {
      rethrow;
    } catch (e) {
      throw DevicePermissionException(
        message:
            'Error crítico al intentar aplicar el bloqueo del OS: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> temporaryUnlock(int durationMinutes) async {
    try {
      // Invocar al sistema operativo para liberar las restricciones de tiempo de pantalla
      print(
        'SISTEMA NATIVO: Desbloqueo temporal concedido por $durationMinutes minutos.',
      );

      // Placeholder: aquí se podría registrar un timer nativo para reactivar
      // el bloqueo cuando expire el tiempo de liberación temporal.
    } catch (e) {
      throw DevicePermissionException(
        message: 'No se pudo procesar el desbloqueo temporal: ${e.toString()}',
        code: 'OS_UNLOCK_ERROR',
      );
    }
  }
}
