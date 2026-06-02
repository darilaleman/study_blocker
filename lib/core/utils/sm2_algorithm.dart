class Sm2Algorithm {
  /// Recalcula los metadatos de repetición espaciada.
  /// [quality] va de 0 (olvido total) a 5 (respuesta perfecta y rápida).
  static Map<String, dynamic> calculate({
    required int previousInterval,
    required double previousEaseFactor,
    required int repetitions,
    required int quality,
  }) {
    int nextInterval;
    int nextRepetitions = repetitions;
    double nextEaseFactor = previousEaseFactor;

    if (quality >= 3) {
      if (nextRepetitions == 0) {
        nextInterval = 1;
      } else if (nextRepetitions == 1) {
        nextInterval = 6;
      } else {
        nextInterval = (previousInterval * previousEaseFactor).round();
      }
      nextRepetitions++;
    } else {
      // Si el usuario falla (calidad < 3), el ciclo se reinicia inmediatamente
      nextRepetitions = 0;
      nextInterval = 1;
    }

    // Fórmula estándar de ajuste del Ease Factor de SuperMemo
    nextEaseFactor =
        previousEaseFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (nextEaseFactor < 1.3) nextEaseFactor = 1.3; // Límite inferior estándar

    return {
      'interval': nextInterval,
      'repetitions': nextRepetitions,
      'easeFactor': nextEaseFactor,
      'nextReview': DateTime.now().add(Duration(days: nextInterval)),
    };
  }
}
