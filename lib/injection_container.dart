import 'dart:async' show Future;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_blocker/data/datasources/device/screen_time_device_datasource.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/data/datasources/local/app_database.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/data/datasources/remote/ai_quiz_remote_datasource.dart';
import 'package:study_blocker/data/repositories/app_block_repository_impl.dart';
import 'package:study_blocker/data/repositories/question_repository_impl.dart';
import 'package:study_blocker/domain/repositories/app_block_repository.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';
import 'package:study_blocker/domain/usecases/block_application.dart';
import 'package:study_blocker/domain/usecases/check_user_answer.dart';
import 'package:study_blocker/domain/usecases/get_random_question.dart';
import 'package:study_blocker/domain/usecases/get_user_study_streak.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  //! Data sources
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<AppConfigLocalDataSource>(
    () => AppConfigLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<QuestionLocalDataSource>(
    () => QuestionLocalDataSourceImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<AiQuizRemoteDataSource>(
    () => AiQuizRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ScreenTimeDeviceDataSource>(
    () => ScreenTimeDeviceDataSourceImpl(),
  );

  //! Repositories
  sl.registerLazySingleton<QuestionRepository>(
    () => QuestionRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AppBlockRepository>(
    () => AppBlockRepositoryImpl(deviceDataSource: sl(), localDataSource: sl()),
  );

  //! Use cases
  sl.registerLazySingleton(() => GetRandomQuestion(sl()));
  sl.registerLazySingleton(() => CheckUserAnswer(sl()));
  sl.registerLazySingleton(() => GetUserStudyStreak(sl()));
  sl.registerLazySingleton(() => BlockApplication(sl()));

  //! Blocs
  sl.registerFactory(() => DashboardBloc(questionRepository: sl()));
  sl.registerFactory(
    () => QuizBloc(getRandomQuestion: sl(), checkUserAnswer: sl()),
  );
}
