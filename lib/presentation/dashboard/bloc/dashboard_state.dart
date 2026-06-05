import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int currentStreak;
  final int questionsAnswered;
  final bool studiedToday; // Nuevo: Indica si ya cumplió hoy (tipo Duolingo)

  const DashboardLoaded({
    required this.currentStreak,
    required this.questionsAnswered,
    required this.studiedToday,
  });

  @override
  List<Object?> get props => [currentStreak, questionsAnswered, studiedToday];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
