import 'package:flutter/material.dart';

class AppConstants {
  // Ocultamos el constructor para evitar instancias innecesarias
  AppConstants._();

  // ===========================================================================
  // CONFIGURACIÓN DE LA APP
  // ===========================================================================
  static const String appName = 'Dopamind'; // O el nombre comercial que elijas
  static const String appVersion = '1.0.0';

  // ===========================================================================
  // RUTAS DE NAVEGACIÓN (Named Routes)
  // ===========================================================================
  static const String routeSplash = '/';
  static const String routePermissions = '/permissions';
  static const String routeAuth = '/auth';
  static const String routeHome = '/home';
  static const String routePdfUpload = '/pdf-upload';
  static const String routeQuizOverlay = '/quiz-overlay';
  static const String routeStats = '/stats';
  static const String routeSubscription = '/subscription';

  // ===========================================================================
  // DISEÑO Y PALETA DE COLORES (UI Theme)
  // ===========================================================================
  // Un enfoque oscuro e imponente que evoque enfoque/productividad
  static const Color primaryColor = Color(0xff6366f1); // Indigo moderno
  static const Color accentColor = Color(
    0xff10b981,
  ); // Verde Éxito (para respuestas correctas)
  static const Color errorColor = Color(
    0xffef4444,
  ); // Rojo Fallo (para respuestas incorrectas)
  static const Color backgroundColor = Color(
    0xff0f172a,
  ); // Fondo Oscuro Profundo (Slate 900)
  static const Color surfaceColor = Color(
    0xff1e293b,
  ); // Tarjetas y Contenedores (Slate 800)

  static const Color textPrimary = Color(0xfff8fafc); // Blanco Grisáceo
  static const Color textSecondary = Color(0xff94a3b8); // Gris Atenuado

  // ===========================================================================
  // LIMITACIONES Y REGLAS DE NEGOCIO (Valores por defecto)
  // ===========================================================================
  static const int freeTierMaxPdfs = 1;
  static const int freeTierMaxPagesPerPdf = 5;
  static const int freeTierMaxBlockedApps = 2;

  // Tiempos por defecto (en minutos) para desbloqueo temporal de apps
  static const int defaultUnlockDurationMinutes = 15;

  // ===========================================================================
  // TEXTOS LOCALIZADOS (Hardcoded temporales antes de meter i18n/Arb)
  // ===========================================================================
  static const String txtPermissionTitle = 'Permisos Requeridos';
  static const String txtPermissionSubtitle =
      'Para bloquear las aplicaciones de distracción, necesitamos que actives los permisos de Accesibilidad y Superposición de pantalla.';
  static const String txtBtnGrantPermission = 'Otorgar Permisos';
  static const String txtBtnContinue = 'Continuar';

  static const String txtQuizHeader = '¡Tiempo de Peaje Mental!';
  static const String txtQuizInstruction =
      'Responde correctamente para desbloquear tus redes sociales.';

  static const String txtVipBannerTitle = 'Desbloquea Dopamind VIP';
  static const String txtVipBannerSubtitle =
      'Sube PDFs ilimitados y genera quizzes automáticos con IA.';
}
