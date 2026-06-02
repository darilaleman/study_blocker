import 'package:equatable/equatable.dart';

/// Representa el perfil de usuario y sus estadísticas globales de progreso.
///
/// Al ser una entidad de dominio, contiene la información esencial del estudiante
/// de forma pura y desacoplada de los sistemas de autenticación o bases de datos.
class User extends Equatable {
  final int? id;
  final String name;
  final String email;
  final int
  currentStreak; // Días consecutivos respondiendo quizzes correctamente
  final DateTime?
  lastStudyDate; // Última vez que interactuó exitosamente con la app
  final bool isVip; // Define si tiene acceso a funciones Premium (IA ilimitada)

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.currentStreak,
    this.lastStudyDate,
    required this.isVip,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    currentStreak,
    lastStudyDate,
    isVip,
  ];

  @override
  String toString() => 'User($name, Streak: $currentStreak, VIP: $isVip)';
}
