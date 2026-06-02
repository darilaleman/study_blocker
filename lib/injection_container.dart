import 'dart:async' show Future;
import 'dart:core';
import 'package:get_it/get_it.dart';
import 'package:study_blocker/domain/usecases/get_random_question.dart';
import 'package:study_blocker/domain/usecases/check_user_answer.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';
// Importa tus datasources y repositorios concretos...

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  //! Presentation Layer (Blocs)
  // useFactory o registerFactory siempre crea una instancia nueva cuando se pide (ideal para Blocs de UI)
  sl.registerFactory(
    () => QuizBloc(getRandomQuestion: sl(), checkUserAnswer: sl()),
  );

  //! Domain Layer (Use Cases)
  sl.registerLazySingleton(() => GetRandomQuestion(sl()));
  sl.registerLazySingleton(() => CheckUserAnswer(sl()));

  //! Data Layer
  // sl.registerLazySingleton<QuestionRepository>(() => QuestionRepositoryImpl(localDataSource: sl()));
  // sl.registerLazySingleton<QuestionLocalDataSource>(() => QuestionLocalDataSourceImpl(database: sl()));
}
