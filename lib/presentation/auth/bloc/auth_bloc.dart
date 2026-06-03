import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/domain/entities/user.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_event.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AppConfigLocalDataSource localConfig;

  AuthBloc({required this.localConfig}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await localConfig.isUserLoggedIn();
      if (!isLoggedIn) {
        emit(Unauthenticated());
        return;
      }

      final user = User(
        id: 1,
        name: 'Estudiante enfocado',
        email: 'usuario@ejemplo.com',
        currentStreak: 0,
        isVip: await localConfig.isVipUser(),
        lastStudyDate: DateTime.now(),
      );

      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Error al verificar el estado de la sesión: $e'));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      if (event.email.isEmpty || !event.email.contains('@')) {
        emit(
          const AuthError(
            message: 'Por favor, introduce un correo electrónico válido.',
          ),
        );
        return;
      }
      if (event.password.length < 6) {
        emit(
          const AuthError(
            message: 'La contraseña debe contener al menos 6 caracteres.',
          ),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1200));
      await localConfig.setIsUserLoggedIn(true);

      final user = User(
        id: 1,
        name: 'Estudiante enfocado',
        email: event.email,
        currentStreak: 0,
        isVip: await localConfig.isVipUser(),
        lastStudyDate: DateTime.now(),
      );

      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Error al iniciar sesión: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await localConfig.setIsUserLoggedIn(false);
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Error al cerrar sesión: $e'));
    }
  }
}
