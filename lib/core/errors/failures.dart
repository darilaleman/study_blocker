import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los fallos en la aplicación.
/// Extendemos de [Equatable] para poder comparar instancias por sus propiedades
/// y facilitar las pruebas unitarias y los cambios de estado en el BLoC.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure[$code]: $message';
}

// ===========================================================================
// FALLOS DE ALMACENAMIENTO (Data Local)
// ===========================================================================

/// Representa un error al leer/escribir en la base de datos local SQLite.
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'No se pudo guardar o recuperar la información local.',
    super.code = 'DB_FAILURE',
  });
}

/// Representa la ausencia de datos cuando se esperaba encontrar algo en caché.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'El recurso solicitado no se encuentra en el dispositivo.',
    super.code = 'CACHE_NOT_FOUND_FAILURE',
  });
}

// ===========================================================================
// FALLOS DE DISPOSITIVO / SISTEMA OPERATIVO
// ===========================================================================

/// Se emite cuando la app no puede bloquear las redes sociales debido a que
/// faltan los permisos nativos de accesibilidad o superposición.
class DevicePermissionFailure extends Failure {
  const DevicePermissionFailure({
    super.message =
        'Es obligatorio activar los permisos para bloquear las aplicaciones.',
    super.code = 'OS_PERMISSION_FAILURE',
  });
}

// ===========================================================================
// FALLOS REMOTOS Y RED (IA y Conectividad)
// ===========================================================================

/// Representa un fallo crítico al intentar conectarse con la API de IA (Gemini/OpenAI).
class AiGenerationFailure extends Failure {
  const AiGenerationFailure({
    super.message =
        'Hubo un problema al procesar el PDF con Inteligencia Artificial.',
    super.code = 'AI_PROCESS_FAILURE',
  });
}

/// Se emite cuando el usuario intenta realizar una acción que requiere internet (como usar la IA)
/// pero el dispositivo está desconectado.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message =
        'Sin conexión a internet. Verifica tu red e intenta de nuevo.',
    super.code = 'NO_INTERNET_FAILURE',
  });
}

// ===========================================================================
// FALLOS DE REGLAS DE NEGOCIO (Suscripciones / Límites)
// ===========================================================================

/// Se emite cuando un usuario intenta superar los límites del plan gratuito.
class SubscriptionFailure extends Failure {
  const SubscriptionFailure({
    super.message =
        'Límite excedido. Pásate a VIP para desbloquear accesos ilimitados.',
    super.code = 'PLAN_LIMIT_FAILURE',
  });
}
