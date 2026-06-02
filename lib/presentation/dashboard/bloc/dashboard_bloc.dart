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

    // Llamamos al método real definido en el contrato del repositorio de dominio
    final result = await questionRepository.getStudyStats();

    result.fold((failure) => emit(DashboardError(message: failure.message)), (
      statsMap,
    ) {
      // Extraemos los valores de forma segura mapeando las llaves del mapa de SQLite/Dominio
      // Usamos el operador de coalescencia (??) por si los campos vienen nulos
      final int streak = statsMap['current_streak'] as int? ?? 0;
      final int todayCount = statsMap['today_answered_count'] as int? ?? 0;

      emit(
        DashboardLoaded(currentStreak: streak, todayAnsweredCount: todayCount),
      );
    });
  }
}
