import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // ===========================================================================
  // CONFIGURACIÓN DE LA APP
  // ===========================================================================
  static const String appName = 'Dopamind';
  static const String appVersion = '1.0.0';

  // ===========================================================================
  // RUTAS DE NAVEGACIÓN (Named Routes)
  // ===========================================================================
  static const String routeSplash = '/';
  static const String routePermissions = '/permissions';
  static const String routeAuth = '/auth';
  static const String routeHome = '/home';
  static const String routeCreateGoal =
      '/create-goal'; // ✅ NUEVA RUTA UNIFICADA
  static const String routePdfUpload = '/pdf-upload'; // ✅ RESTAURADA
  static const String routeQuizOverlay = '/quiz-overlay';
  static const String routeStats = '/stats';
  static const String routeSubscription = '/subscription';

  // ===========================================================================
  // DISEÑO Y PALETA DE COLORES (UI Theme)
  // ===========================================================================
  static const Color primaryColor = Color(0xff6366f1); // Indigo moderno
  static const Color accentColor = Color(0xff10b981); // Verde Éxito
  static const Color errorColor = Color(0xffef4444); // Rojo Fallo
  static const Color backgroundColor = Color(
    0xff0f172a,
  ); // Fondo Oscuro Profundo
  static const Color surfaceColor = Color(
    0xff1e293b,
  ); // Tarjetas y Contenedores
  static const Color textPrimary = Color(0xfff8fafc); // Blanco Grisáceo
  static const Color textSecondary = Color(0xff94a3b8); // Gris Atenuado

  // ===========================================================================
  // LIMITACIONES Y REGLAS DE NEGOCIO (Valores por defecto)
  // ===========================================================================
  static const int freeTierMaxPdfs = 1;
  static const int freeTierMaxPagesPerPdf = 10;
  static const int freeTierMaxBlockedApps = 2;
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
