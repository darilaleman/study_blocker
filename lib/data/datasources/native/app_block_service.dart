import 'package:flutter/services.dart';

class AppBlockService {
  static const MethodChannel _channel = MethodChannel(
    'com.studyblocker/app_shield',
  );

  /// Activa el servicio nativo de accesibilidad/monitoreo
  Future<void> startShield() async {
    try {
      await _channel.invokeMethod('startBackgroundMonitoring');
    } on PlatformException catch (e) {
      print("Error al iniciar el escudo nativo: ${e.message}");
    }
  }

  /// Define qué aplicaciones están en la "lista negra"
  Future<void> updateBlockedApps(List<String> packageNames) async {
    await _channel.invokeMethod('setBlockedPackages', {
      'packages': packageNames,
    });
  }
}
