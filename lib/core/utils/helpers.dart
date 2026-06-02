import 'dart:io';
import 'package:path/path.dart' as p;

class AppHelpers {
  AppHelpers._();

  // ===========================================================================
  // VALIDACIONES DE ARCHIVOS (PDF)
  // ===========================================================================

  /// Verifica si el archivo seleccionado por el usuario es un PDF válido por su extensión.
  static bool isValidPdf(File file) {
    final extension = p.extension(file.path).toLowerCase();
    return extension == '.pdf';
  }

  /// Verifica si el tamaño del archivo está dentro del límite permitido (en Megabytes).
  /// Útil para evitar que suban PDFs masivos en el plan gratuito.
  static bool isFileSizeValid(File file, int maxMb) {
    final bytes = file.lengthSync();
    final megabytes = bytes / (1024 * 1024);
    return megabytes <= maxMb;
  }

  // ===========================================================================
  // MANEJO DE TIEMPO Y FORMATOS
  // ===========================================================================

  /// Convierte una duración en minutos a un texto legible para el usuario.
  /// Ejemplo: 90 -> "1h 30m" | 15 -> "15m"
  static String formatMinutesToReadable(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  /// Calcula cuántos segundos quedan entre la hora actual y una hora de finalización.
  /// Útil para la cuenta regresiva en el overlay de bloqueo si dejas pasar al usuario por tiempo.
  static int getRemainingSeconds(DateTime endDateTime) {
    final now = DateTime.now();
    if (now.isAfter(endDateTime)) return 0;
    return endDateTime.difference(now).inSeconds;
  }

  // ===========================================================================
  // LÓGICA DE GAMIFICACIÓN (Rachas / Streaks)
  // ===========================================================================

  /// Verifica si la racha de estudio se mantiene activa o si ya se rompió.
  ///
  /// Recibe la fecha del [lastStudyDate] (última vez que respondió bien un quiz).
  /// Si pasó más de un día completo sin actividad, la racha debería volver a 0.
  static bool isStreakActive(DateTime? lastStudyDate) {
    if (lastStudyDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStudyDay = DateTime(
      lastStudyDate.year,
      lastStudyDate.month,
      lastStudyDate.day,
    );

    final difference = today.difference(lastStudyDay).inDays;

    // La racha sigue activa si estudió hoy (0) o ayer (1).
    // Si la diferencia es 2 o más, la racha se rompió.
    return difference <= 1;
  }
}

// ===========================================================================
// EXTENSIONES ÚTILES (Opcional, hace el código de la UI más limpio)
// ===========================================================================

extension DateTimeExtension on DateTime {
  /// Devuelve true si la fecha corresponde al día de hoy.
  /// Uso en UI: `if (question.createdAt.isToday) ...`
  bool get isToday {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }

  /// Formatea la fecha de manera simple para mostrar la meta del examen (DD/MM/AAAA)
  String toShortDateString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
}
