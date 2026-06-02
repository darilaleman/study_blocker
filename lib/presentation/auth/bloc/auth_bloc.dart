import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/domain/entities/user.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_event.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Nota: Cuando conectes inyección de dependencias (GetIt),
  // descomenta y pasa tus Casos de Uso reales aquí.
  // final CheckAuthStatus checkAuthStatus;
  // final LoginUseCase loginUseCase;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Simulación de verificación de persistencia local (SharedPreferences/SecureStorage)
      await Future.delayed(const Duration(seconds: 1));

      // Por defecto obligamos a ir a login. Cambiar por lógica de sesión persistente.
      emit(Unauthenticated());
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
      // Validación estricta en presentación antes de llamadas de red/infraestructura
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

      // Simulación de retardo de red/asíncrono
      await Future.delayed(const Duration(milliseconds: 1200));

      // Creación de la Entidad de Dominio User (acorde a tu archivo user.dart)
      final user = User(
        id: 1,
        name: "Estudiante enfocado",
        email: event.email,
        currentStreak: 0,
        isVip: false,
        lastStudyDate: DateTime.now(),
      );

      // ¡CRÍTICO! Emitir el estado de éxito para desbloquear la UI
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
      // Simulación de limpieza de tokens/DB
      await Future.delayed(const Duration(milliseconds: 500));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Error al cerrar sesión: $e'));
    }
  }
}
