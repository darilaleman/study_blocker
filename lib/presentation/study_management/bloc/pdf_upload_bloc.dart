import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/domain/usecases/extract_text_from_pdf.dart';
import 'package:study_blocker/domain/usecases/generate_quiz_with_ai.dart';
import 'pdf_upload_event.dart';
import 'pdf_upload_state.dart';

class PdfUploadBloc extends Bloc<PdfUploadEvent, PdfUploadState> {
  final AppConfigLocalDataSource localConfig; // Para verificar isVip
  final QuestionLocalDataSource questionLocalDataSource;
  final ExtractTextFromPdf extractTextFromPdf;
  final GenerateQuizWithAi generateQuizWithAi;

  // Límites del Plan Free
  static const int maxActiveSubjectsFree =
      2; // Solo se permite estudiar/tener activas 2 asignaturas a la vez
  static const int maxPdfsPerSubjectFree =
      1; // Máximo de 1 PDF por cada asignatura
  static const int maxPagesFree = 10;
  static const int maxMbSize = 10;

  PdfUploadBloc({
    required this.localConfig,
    required this.questionLocalDataSource,
    required this.extractTextFromPdf,
    required this.generateQuizWithAi,
  }) : super(const PdfUploadState()) {
    on<InitializePdfUpload>(_onInitialize);
    on<SubjectNameChanged>(_onSubjectNameChanged);
    on<ExamDateChanged>(_onExamDateChanged);
    on<PdfFileSelected>(_onPdfFileSelected);
    on<SavePdfRequested>(_onSavePdfRequested);
    on<ProcessAiRequested>(_onProcessAiRequested);
  }

  Future<void> _onInitialize(
    InitializePdfUpload event,
    Emitter<PdfUploadState> emit,
  ) async {
    emit(state.copyWith(status: PdfUploadStatus.loading));
    try {
      final isVip = await localConfig.isVipUser();
      emit(state.copyWith(status: PdfUploadStatus.initial, isVip: isVip));
    } catch (_) {
      emit(state.copyWith(status: PdfUploadStatus.initial, isVip: false));
    }
  }

  void _onSubjectNameChanged(
    SubjectNameChanged event,
    Emitter<PdfUploadState> emit,
  ) {
    emit(state.copyWith(subjectName: event.name, errorMessage: ''));
  }

  void _onExamDateChanged(ExamDateChanged event, Emitter<PdfUploadState> emit) {
    emit(state.copyWith(examDate: event.date, errorMessage: ''));
  }

  void _onPdfFileSelected(PdfFileSelected event, Emitter<PdfUploadState> emit) {
    // Validación 1: Tamaño
    if (event.fileSizeMb > maxMbSize) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'El archivo supera el límite de ${maxMbSize}MB.',
        ),
      );
      return;
    }

    // Validación 2: Páginas (Si es Free)
    if (!state.isVip && event.pageCount > maxPagesFree) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage:
              'El PDF supera las $maxPagesFree páginas permitidas en el plan gratuito. Actualiza a VIP o utiliza un PDF más corto.',
          fileName: null,
          filePath: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PdfUploadStatus.initial,
        fileName: event.fileName,
        filePath: event.filePath,
        pageCount: event.pageCount,
        errorMessage: '',
      ),
    );
  }

  Future<void> _onSavePdfRequested(
    SavePdfRequested event,
    Emitter<PdfUploadState> emit,
  ) async {
    if (!state.isFormValid) return;

    emit(state.copyWith(status: PdfUploadStatus.loading));

    try {
      if (!state.isVip) {
        final int activeSubjectsCount = await questionLocalDataSource
            .countActiveSubjects();
        if (activeSubjectsCount >= maxActiveSubjectsFree) {
          emit(
            state.copyWith(
              status: PdfUploadStatus.error,
              errorMessage:
                  'Has alcanzado el límite de $maxActiveSubjectsFree asignaturas activas simultáneamente. Desactiva otra asignatura o actualiza a VIP para poder estudiar esta.',
            ),
          );
          return;
        }

        final int currentPdfsInSubject = await questionLocalDataSource
            .countPdfsForSubject(state.subjectName);
        if (currentPdfsInSubject >= maxPdfsPerSubjectFree) {
          emit(
            state.copyWith(
              status: PdfUploadStatus.error,
              errorMessage:
                  'En el plan gratuito solo puedes tener $maxPdfsPerSubjectFree PDF por asignatura. Actualiza a VIP para añadir más material aquí.',
            ),
          );
          return;
        }
      }

      final filePath = state.filePath;
      final pageCount = state.pageCount;
      final examDate = state.examDate;
      if (filePath == null || pageCount == null || examDate == null) {
        emit(
          state.copyWith(
            status: PdfUploadStatus.error,
            errorMessage:
                'No se pudieron guardar los datos del PDF. Faltan campos obligatorios.',
          ),
        );
        return;
      }

      await questionLocalDataSource.saveSubjectAndPdf(
        subjectName: state.subjectName,
        examDate: examDate,
        filePath: filePath,
        pageCount: pageCount,
      );

      emit(
        state.copyWith(
          status: PdfUploadStatus.success,
          errorMessage: 'PDF guardado exitosamente.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'Error al guardar: $e',
        ),
      );
    }
  }

  Future<void> _onProcessAiRequested(
    ProcessAiRequested event,
    Emitter<PdfUploadState> emit,
  ) async {
    if (!state.isVip) {
      // El BLoC bloquea procesar si no es VIP por seguridad
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'REQUIRES_SUBSCRIPTION', // Flag para que la UI navegue
        ),
      );
      return;
    }

    emit(state.copyWith(status: PdfUploadStatus.aiProcessing));

    try {
      final filePath = state.filePath;
      final subject = state.subjectName;

      if (filePath == null || subject.isEmpty) {
        emit(
          state.copyWith(
            status: PdfUploadStatus.error,
            errorMessage:
                'No se ha cargado el PDF o no se ha seleccionado una asignatura.',
          ),
        );
        return;
      }

      final textResult = await extractTextFromPdf(
        ExtractTextFromPdfParams(pdfPath: filePath),
      );

      await textResult.fold(
        (failure) async {
          emit(
            state.copyWith(
              status: PdfUploadStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (pdfText) async {
          final aiResult = await generateQuizWithAi(
            GenerateQuizWithAiParams(pdfText: pdfText, subject: subject),
          );

          aiResult.fold(
            (failure) => emit(
              state.copyWith(
                status: PdfUploadStatus.error,
                errorMessage: failure.message,
              ),
            ),
            (_) => emit(
              state.copyWith(
                status: PdfUploadStatus.aiSuccess,
                errorMessage: 'Preguntas generadas con éxito.',
              ),
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'Error en la IA: $e',
        ),
      );
    }
  }
}
