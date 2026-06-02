import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Se dispara al arrancar la app para comprobar si hay una sesión activa en el llavero local.
class AppStarted extends AuthEvent {}

/// Desencadena el inicio de sesión del estudiante.
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Cierra la sesión del usuario actual y limpia la persistencia de datos.
class LogoutRequested extends AuthEvent {}
