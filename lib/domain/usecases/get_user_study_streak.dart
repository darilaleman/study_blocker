import 'package:dartz/dartz.dart';
import 'package:study_blocker/core/errors/failures.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';

/// Caso de Uso encargado de recopilar las métricas de progreso del estudiante,
/// incluyendo su racha de días activos y el volumen de estudio completado hoy.
///
/// Al no requerir parámetros de entrada, implementa la firma base usando [NoParams].
class GetUserStudyStreak implements UseCase<Map<String, dynamic>, NoParams> {
  final QuestionRepository repository;

  GetUserStudyStreak(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    // Retorna el mapa con las llaves 'current_streak', 'today_answered_count'
    // y 'has_studied_enough_today'.
    return await repository.getStudyStats();
  }
}
