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
  final int questionsAnswered; // Mapeado de todayAnsweredCount
  final int studyTimeMinutes; // Propiedad añadida

  const DashboardLoaded({
    required this.currentStreak,
    required this.questionsAnswered,
    required this.studyTimeMinutes,
  });

  @override
  List<Object?> get props => [
    currentStreak,
    questionsAnswered,
    studyTimeMinutes,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
