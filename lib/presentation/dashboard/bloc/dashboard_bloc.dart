import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final QuestionRepository questionRepository;

  DashboardBloc({required this.questionRepository})
    : super(DashboardInitial()) {
    on<LoadDashboardMetrics>(_onLoadDashboardMetrics);
  }

  Future<void> _onLoadDashboardMetrics(
    LoadDashboardMetrics event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    // Llamamos al repositorio
    final result = await questionRepository.getStudyStats();

    result.fold((failure) => emit(DashboardError(message: failure.message)), (
      statsMap,
    ) {
      // Extraemos valores asegurando tipos y usando valores por defecto
      final int streak = statsMap['current_streak'] as int? ?? 0;
      final int answered = statsMap['today_answered_count'] as int? ?? 0;

      // Asumiendo que el mapa tiene el tiempo, si no, puedes cambiar la lógica
      final int time = statsMap['study_time_minutes'] as int? ?? 0;

      emit(
        DashboardLoaded(
          currentStreak: streak,
          questionsAnswered: answered,
          studyTimeMinutes: time,
        ),
      );
    });
  }
}
