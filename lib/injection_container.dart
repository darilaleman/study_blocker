import 'dart:async' show Future;
import 'dart:io' show Platform;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_blocker/data/datasources/device/screen_time_device_datasource.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/data/datasources/local/app_database.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/data/datasources/remote/ai_quiz_remote_datasource.dart';
import 'package:study_blocker/data/models/question_model.dart';
import 'package:study_blocker/data/repositories/app_block_repository_impl.dart';
import 'package:study_blocker/data/repositories/question_repository_impl.dart';
import 'package:study_blocker/domain/repositories/app_block_repository.dart';
import 'package:study_blocker/domain/repositories/question_repository.dart';
import 'package:study_blocker/domain/usecases/block_application.dart';
import 'package:study_blocker/domain/usecases/check_user_answer.dart';
import 'package:study_blocker/domain/usecases/extract_text_from_pdf.dart';
import 'package:study_blocker/domain/usecases/generate_quiz_with_ai.dart';
import 'package:study_blocker/domain/usecases/get_random_question.dart';
import 'package:study_blocker/domain/usecases/get_user_study_streak.dart';
import 'package:study_blocker/domain/usecases/parse_questions_from_pdf.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_bloc.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_bloc.dart';
import 'package:study_blocker/presentation/study_management/bloc/app_selection/app_selection_bloc.dart';
import 'package:study_blocker/presentation/study_management/bloc/pdf_upload_bloc.dart';
import 'package:study_blocker/presentation/study_management/bloc/study_goal/study_goal_bloc.dart';

final sl = GetIt.instance;

// Datasources mock para plataformas no soportadas (web, etc)
class _MockQuestionLocalDataSource implements QuestionLocalDataSource {
  @override
  Future<void> insertQuestions(List<QuestionModel> questions) async {}

  @override
  Future<QuestionModel> getRandomPendingQuestion() async =>
      _createMockQuestion();

  @override
  Future<void> deleteSubject(int id) async {}

  @override
  Future<void> deactivateExpiredSubjects() async {}

  @override
  Future<void> updateQuestionReviewData({
    required int questionId,
    required String nextReview,
    required int interval,
    required double easeFactor,
    required int repetitions,
  }) async {}

  @override
  Future<void> insertStudyLog(
    int questionId,
    bool isCorrect,
    String answeredAt,
  ) async {}

  @override
  Future<int> getCurrentStreak() async => 0;

  @override
  Future<int> getTodayAnsweredCount() async => 0;

  @override
  Future<List<Map<String, dynamic>>> getAllSubjects() async => [];

  @override
  Future<int> createSubject({
    required String name,
    required bool isActive,
  }) async => 0;

  @override
  Future<void> updateSubjectActive(int id, bool isActive) async {}

  @override
  Future<List<QuestionModel>> getAllQuestions() async => [];

  @override
  Future<List<QuestionModel>> getQuestionsBySubject(String subject) async => [];

  @override
  Future<int> countActiveSubjects() async => 0;

  @override
  Future<int> countPdfsForSubject(String subjectName) async => 0;

  @override
  Future<void> saveSubjectAndPdf({
    required String subjectName,
    required DateTime examDate,
    required String filePath,
    required int pageCount,
  }) async {}

  @override
  Future<void> saveBlockedApps(
    int subjectId,
    List<String> packageNames,
  ) async {}

  @override
  Future<List<String>> getBlockedAppsForSubject(int subjectId) async => [];

  static QuestionModel _createMockQuestion() => QuestionModel(
    id: 1,
    subject: 'Tema de prueba',
    question: '¿Esta es una pregunta de prueba?',
    options: const ['Sí', 'No', 'Tal vez'],
    correctAnswer: 'Sí',
    nextReview: DateTime.now(),
    interval: 1,
    easeFactor: 2.5,
    repetitions: 0,
  );
}

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  //! Data sources
  final bool isNativePlatform =
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isLinux ||
      Platform.isWindows;

  if (isNativePlatform) {
    try {
      sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);
      sl.registerLazySingleton<QuestionLocalDataSource>(
        () => QuestionLocalDataSourceImpl(appDatabase: sl()),
      );
    } catch (e) {
      // Fallback a mock si sqflite falla
      sl.registerLazySingleton<QuestionLocalDataSource>(
        () => _MockQuestionLocalDataSource(),
      );
    }
  } else {
    // En web u otras plataformas sin soporte, usar mock
    sl.registerLazySingleton<QuestionLocalDataSource>(
      () => _MockQuestionLocalDataSource(),
    );
  }

  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<AppConfigLocalDataSource>(
    () => AppConfigLocalDataSourceImpl(sl()),
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
  sl.registerLazySingleton(() => ExtractTextFromPdf());
  sl.registerLazySingleton(() => GenerateQuizWithAi(sl()));

  //! Blocs
  sl.registerFactory(() => DashboardBloc(questionRepository: sl()));
  sl.registerFactory(
    () => QuizBloc(getRandomQuestion: sl(), checkUserAnswer: sl()),
  );
  sl.registerFactory(() => AuthBloc(localConfig: sl()));
  sl.registerFactory(() => AppSelectionBloc(repository: sl()));
  sl.registerLazySingleton(() => const ParseQuestionsFromPdf());
  sl.registerFactory(
    () => PdfUploadBloc(
      localConfig: sl(),
      questionLocalDataSource: sl(),
      extractTextFromPdf: sl(),
      generateQuizWithAi: sl(),
      parseQuestionsFromPdf: sl(),
    ),
  );
  sl.registerFactory(
    () => StudyGoalBloc(localConfig: sl(), questionLocalDataSource: sl()),
  );
}
