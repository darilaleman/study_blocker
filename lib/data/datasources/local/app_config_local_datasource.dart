import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_blocker/core/errors/exceptions.dart';

/// Contrato abstracto para la persistencia de configuraciones locales de la aplicación.
abstract class AppConfigLocalDataSource {
  /// Guarda si el usuario ya completó la pantalla de permisos iniciales.
  Future<void> setOnboardingCompleted(bool completed);

  /// Verifica si el usuario ya completó el onboarding de permisos.
  Future<bool> isOnboardingCompleted();

  /// Guarda la fecha del examen seleccionado por el usuario.
  Future<void> setExamDate(DateTime date);

  /// Recupera la fecha del examen. Retorna null si no se ha configurado ninguno.
  Future<DateTime?> getExamDate();

  /// Guarda la lista de paquetes de aplicaciones que el usuario desea bloquear (ej: ['com.instagram.android']).
  Future<void> setBlockedApps(List<String> packageNames);

  /// Recupera la lista de aplicaciones guardadas para bloquear.
  Future<List<String>> getBlockedApps();

  /// Guarda el estado de suscripción del usuario (true si es VIP).
  Future<void> setIsVipUser(bool isVip);

  /// Verifica si el usuario tiene el estado VIP activo de forma local.
  Future<bool> isVipUser();

  /// Limpia todas las configuraciones (útil para un cierre de sesión o reset de la app).
  Future<void> clearConfig();
}

/// Implementación concreta utilizando el paquete official SharedPreferences.
class AppConfigLocalDataSourceImpl implements AppConfigLocalDataSource {
  final SharedPreferences _sharedPreferences;

  // Claves estáticas para evitar errores de tipeo al guardar/leer datos
  static const _keyOnboarding = 'PREF_ONBOARDING_COMPLETED';
  static const _keyExamDate = 'PREF_EXAM_DATE';
  static const _keyBlockedApps = 'PREF_BLOCKED_APPS_LIST';
  static const _keyIsVip = 'PREF_IS_VIP_USER';

  AppConfigLocalDataSourceImpl(this._sharedPreferences);

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await _sharedPreferences.setBool(_keyOnboarding, completed);
    } catch (e) {
      throw const CacheException(
        message: 'No se pudo guardar el estado del onboarding.',
      );
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    // Si es la primera vez que abre la app, por defecto retorna false
    return _sharedPreferences.getBool(_keyOnboarding) ?? false;
  }

  @override
  Future<void> setExamDate(DateTime date) async {
    try {
      // SharedPreferences no almacena DateTime directamente, lo guardamos como un String ISO 8601
      await _sharedPreferences.setString(_keyExamDate, date.toIso8601String());
    } catch (e) {
      throw const CacheException(
        message: 'No se pudo guardar la fecha del examen.',
      );
    }
  }

  @override
  Future<DateTime?> getExamDate() async {
    final dateStr = _sharedPreferences.getString(_keyExamDate);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  @override
  Future<void> setBlockedApps(List<String> packageNames) async {
    try {
      await _sharedPreferences.setStringList(_keyBlockedApps, packageNames);
    } catch (e) {
      throw const CacheException(
        message: 'No se pudo guardar la lista de aplicaciones bloqueadas.',
      );
    }
  }

  @override
  Future<List<String>> getBlockedApps() async {
    return _sharedPreferences.getStringList(_keyBlockedApps) ?? [];
  }

  @override
  Future<void> setIsVipUser(bool isVip) async {
    try {
      await _sharedPreferences.setBool(_keyIsVip, isVip);
    } catch (e) {
      throw const CacheException(
        message: 'No se pudo actualizar el estado de suscripción VIP.',
      );
    }
  }

  @override
  Future<bool> isVipUser() async {
    return _sharedPreferences.getBool(_keyIsVip) ?? false;
  }

  @override
  Future<void> clearConfig() async {
    try {
      await _sharedPreferences.remove(_keyOnboarding);
      await _sharedPreferences.remove(_keyExamDate);
      await _sharedPreferences.remove(_keyBlockedApps);
      await _sharedPreferences.remove(_keyIsVip);
    } catch (e) {
      throw const CacheException(
        message: 'Error al limpiar las configuraciones locales.',
      );
    }
  }
}
