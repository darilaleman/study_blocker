import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:study_blocker/core/errors/failures.dart';

/// Interfaz base abstracta para todos los casos de uso (Use Cases) de la app.
///
/// [Type] representa el tipo de dato que el caso de uso devolverá en caso de éxito.
/// [Params] representa los parámetros necesarios para ejecutar el caso de uso.
abstract class UseCase<Type, Params> {
  /// Ejecuta la lógica del caso de uso.
  ///
  /// Retorna un [Either] que contiene un [Failure] a la izquierda (si falló)
  /// o el [Type] esperado a la derecha (si fue exitoso).
  Future<Either<Failure, Type>> call(Params params);
}

/// Clase utilitaria para aquellos casos de uso que NO requieren parámetros de entrada.
///
/// Ejemplo: `GetRandomQuestion` o `GetActiveSubscriptionStatus`
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
