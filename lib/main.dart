import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/presentation/auth/bloc/auth_bloc.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_event.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_state.dart';
import 'package:study_blocker/presentation/auth/pages/login_screen.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/dashboard/pages/home_screen.dart';
import 'package:study_blocker/presentation/dashboard/pages/stats_screen.dart';
import 'package:study_blocker/presentation/onboard_permissions/pages/onboarding_permission_screen.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';
import 'package:study_blocker/presentation/quiz_overlay/pages/quiz_screen.dart';
import 'package:study_blocker/presentation/study_management/pages/pdf_upload_screen.dart';
import 'package:study_blocker/presentation/subscription/pages/subscription_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const StudyBlockerApp());
}

class StudyBlockerApp extends StatelessWidget {
  const StudyBlockerApp({super.key});

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

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(localConfig: di.sl())..add(AppStarted()),
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
              return const HomeScreen();
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
          AppConstants.routeHome: (context) => const HomeScreen(),
          AppConstants.routePdfUpload: (context) => const PdfUploadScreen(),
          AppConstants.routeQuizOverlay: (context) => const QuizScreen(),
          AppConstants.routeStats: (context) => const StatsScreen(),
          AppConstants.routeSubscription: (context) =>
              const SubscriptionScreen(),
        },
      ),
    );
  }
}
