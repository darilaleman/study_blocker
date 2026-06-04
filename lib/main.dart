import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/presentation/auth/bloc/auth_bloc.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_event.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_state.dart';
import 'package:study_blocker/presentation/auth/pages/login_screen.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/main_screen.dart';
import 'package:study_blocker/presentation/onboard_permissions/pages/onboarding_permission_screen.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';
import 'package:study_blocker/presentation/quiz_overlay/pages/quiz_screen.dart';
import 'package:study_blocker/presentation/study_management/pages/pdf_upload_screen.dart';
import 'package:study_blocker/presentation/subscription/pages/subscription_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool initOk = true;
  String? initError;

  try {
    await di.init();
  } catch (e, st) {
    initOk = false;
    initError = e.toString();
    // En release el print puede no verse, por eso mostramos la pantalla de error
    // cuando la inicialización falla.
    // ignore: avoid_print
    print('Error fatal al iniciar: $e\n$st');
  }

  runApp(StudyBlockerApp(initOk: initOk, initError: initError));
}

class StudyBlockerApp extends StatelessWidget {
  final bool initOk;
  final String? initError;

  const StudyBlockerApp({super.key, this.initOk = true, this.initError});

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
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

    if (!initOk) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error de inicio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initError ?? 'Fallo no especificado',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AppStarted()),
        ),
        BlocProvider<DashboardBloc>(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider<QuizBloc>(create: (_) => di.sl<QuizBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return const MainScreen();
            } else if (state is Unauthenticated || state is AuthError) {
              return const LoginScreen();
            }

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        routes: {
          AppConstants.routeAuth: (context) => const LoginScreen(),
          AppConstants.routePermissions: (context) =>
              const OnboardingPermissionScreen(),
          AppConstants.routeHome: (context) => const MainScreen(),
          AppConstants.routePdfUpload: (context) => const PdfUploadScreen(),
          AppConstants.routeQuizOverlay: (context) => const QuizScreen(),
          AppConstants.routeSubscription: (context) =>
              const SubscriptionScreen(),
        },
      ),
    );
  }
}
