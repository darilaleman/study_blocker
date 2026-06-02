import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_bloc.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_event.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_state.dart';
import 'package:study_blocker/presentation/auth/pages/login_screen.dart';
import 'package:study_blocker/presentation/dashboard/pages/home_screen.dart';
import 'package:study_blocker/presentation/dashboard/pages/stats_screen.dart';
import 'package:study_blocker/presentation/onboard_permissions/pages/onboarding_permission_screen.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';
import 'package:study_blocker/presentation/quiz_overlay/pages/quiz_screen.dart';
import 'package:study_blocker/presentation/study_management/pages/pdf_upload_screen.dart';
import 'package:study_blocker/presentation/study_management/pages/study_material_screen.dart';
import 'package:study_blocker/presentation/subscription/pages/subscription_screen.dart';

// TODO: Importar tu contenedor de Inyección de Dependencias real
// import 'package:study_blocker/injection_container.dart' as di;

void main() async {
  // Aseguramos que los canales nativos del motor de Flutter estén completamente vinculados
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Inicializar la inyección de dependencias asíncrona
  // await di.init();

  runApp(const StudyBlockerApp());
}

class StudyBlockerApp extends StatelessWidget {
  const StudyBlockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición del Sistema de Diseño unificado bajo la estética de Material 3
    final ThemeData appTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(
          0xFF6366F1,
        ), // Indigo moderno como color de enfoque
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return MultiBlocProvider(
      providers: [
        // 1. Inyección del Bloque de Autenticación (Se dispara inmediatamente al iniciar)
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AppStarted()),
        ),
        // 2. Inyección del Bloque de Quizzes (Disponible globalmente para los overlays de bloqueo)
        BlocProvider<QuizBloc>(
          create: (context) => QuizBloc(
            getRandomQuestion: context
                .read(), // TODO: Reemplazar por di.sl<GetRandomQuestion>() cuando acoples DI
            checkUserAnswer: context
                .read(), // TODO: Reemplazar por di.sl<CheckUserAnswer>() cuando acoples DI
          ),
        ),
      ],
      child: MaterialApp(
        title: 'StudyBlocker',
        theme: appTheme,
        debugShowCheckedModeBanner: false,

        // GESTIÓN REACTIVA DE LA RUTA INICIAL SEGÚN EL ESTADO DE SESIÓN
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return const HomeScreen();
            } else if (state is Unauthenticated) {
              return const LoginScreen();
            } else if (state is AuthError) {
              return const LoginScreen(); // Si hay error, forzamos login para re-autenticar
            }

            // Pantalla de carga limpia mientras verifica el llavero local SecureStorage
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),

        // MAPEO CENTRALIZADO DE ENRUTAMIENTO ESTÁTICO
        routes: {
          '/login': (context) => const LoginScreen(),
          '/onboarding-permissions': (context) =>
              const OnboardingPermissionScreen(),
          '/home': (context) => const HomeScreen(),
          '/upload-pdf': (context) => const PdfUploadScreen(),
          '/quiz-bank': (context) => const StudyMaterialScreen(),
          '/lockscreen-quiz': (context) => const QuizScreen(),
          '/analytics': (context) => const StatsScreen(),
          '/subscription': (context) => const SubscriptionScreen(),
        },
      ),
    );
  }
}
