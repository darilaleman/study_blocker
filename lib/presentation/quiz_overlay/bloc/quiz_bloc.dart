import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/usecases/usecase.dart';
import 'package:study_blocker/domain/usecases/get_random_question.dart';
import 'package:study_blocker/domain/usecases/check_user_answer.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_event.dart';
import 'package:study_blocker/presentation/quiz_overlay/bloc/quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final GetRandomQuestion getRandomQuestion;
  final CheckUserAnswer checkUserAnswer;

  QuizBloc({required this.getRandomQuestion, required this.checkUserAnswer})
    : super(QuizInitial()) {
    on<FetchQuizQuestion>(_onFetchQuizQuestion);
    on<SubmitQuizAnswer>(_onSubmitQuizAnswer);
  }

  Future<void> _onFetchQuizQuestion(
    FetchQuizQuestion event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());

    // Invocamos al caso de uso puro de dominio sin parámetros de entrada (NoParams)
    final result = await getRandomQuestion(NoParams());

    result.fold(
      (failure) => emit(QuizError(message: failure.message)),
      (question) => emit(QuizQuestionLoaded(question: question)),
    );
  }

  Future<void> _onSubmitQuizAnswer(
    SubmitQuizAnswer event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());

    // Ejecutamos el caso de uso pasando los parámetros requeridos
    final result = await checkUserAnswer(
      CheckUserAnswerParams(
        question: event.question,
        userAnswer: event.selectedAnswer,
      ),
    );

    result.fold(
      (failure) => emit(QuizError(message: failure.message)),
      (isCorrect) => emit(
        QuizAnswerResult(
          isCorrect: isCorrect,
          correctAnswer: event.question.correctAnswer,
        ),
      ),
    );
  }
}
