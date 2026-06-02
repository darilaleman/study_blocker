/// Clase base para todas las excepciones personalizadas de la aplicación.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => '[$code]: $message';
}

// ===========================================================================
// EXCEPCIONES DE LA CAPA DE DATOS (Bases de Datos / Persistencia)
// ===========================================================================

/// Se lanza cuando ocurre un error crítico al interactuar con SQLite (sqflite).
class DatabaseException extends AppException {
  const DatabaseException({
    super.message = 'Error al leer o escribir en la base de datos local.',
    super.code = 'DB_ERROR',
  });
}

/// Se lanza cuando se intenta buscar un registro (ej. una pregunta) que no existe.
class CacheException extends AppException {
  const CacheException({
    super.message = 'No se encontraron datos en el almacenamiento local.',
    super.code = 'CACHE_NOT_FOUND',
  });
}

// ===========================================================================
// EXCEPCIONES DE DISPOSITIVO / SISTEMA OPERATIVO (Plugins Nativos)
// ===========================================================================

/// Se lanza si el plugin de bloqueo (flutter_screentime) falla o si el usuario
/// revoca los permisos de accesibilidad/superposición a mitad de ejecución.
class DevicePermissionException extends AppException {
  const DevicePermissionException({
    super.message = 'Los permisos del sistema requeridos no están activos.',
    super.code = 'OS_PERMISSION_DENIED',
  });
}

// ===========================================================================
// EXCEPCIONES REMOTAS / APIS (IA e Integraciones)
// ===========================================================================

/// Se lanza cuando la API de Inteligencia Artificial (OpenAI/Gemini) falla,
/// devuelve un formato incorrecto o se agotan los tokens del usuario.
class AiGenerationException extends AppException {
  const AiGenerationException({
    super.message = 'La IA no pudo procesar el PDF o generar las preguntas.',
    super.code = 'AI_GENERATION_FAILED',
  });
}

/// Se lanza si el dispositivo no tiene conexión a internet y se intenta usar la IA.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No hay conexión a internet disponible.',
    super.code = 'NO_INTERNET',
  });
}

// ===========================================================================
// EXCEPCIONES DE REGLAS DE NEGOCIO (Validaciones Críticas)
// ===========================================================================

/// Se lanza si un usuario Free intenta superar el límite de PDFs o apps bloqueadas.
class SubscriptionException extends AppException {
  const SubscriptionException({
    super.message = 'Has alcanzado el límite de tu plan actual.',
    super.code = 'LIMIT_EXCEEDED',
  });
}
