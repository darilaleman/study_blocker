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

    final result = await questionRepository.getStudyStats();

    result.fold((failure) => emit(DashboardError(message: failure.message)), (
      statsMap,
    ) {
      final int streak = statsMap['current_streak'] as int? ?? 0;
      final int answered = statsMap['today_answered_count'] as int? ?? 0;

      // Lógica tipo Duolingo: Si respondió al menos 1 pregunta hoy, la racha de hoy está activa
      final bool studiedToday = answered > 0;

      emit(
        DashboardLoaded(
          currentStreak: streak,
          questionsAnswered: answered,
          studiedToday: studiedToday,
        ),
      );
    });
  }
}
