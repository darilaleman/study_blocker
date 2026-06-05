import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/errors/exceptions.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/domain/usecases/extract_text_from_pdf.dart';
import 'package:study_blocker/domain/usecases/generate_quiz_with_ai.dart';
import 'package:study_blocker/domain/usecases/parse_questions_from_pdf.dart';
import 'pdf_upload_event.dart';
import 'pdf_upload_state.dart';

class PdfUploadBloc extends Bloc<PdfUploadEvent, PdfUploadState> {
  final AppConfigLocalDataSource localConfig;
  final QuestionLocalDataSource questionLocalDataSource;
  final ExtractTextFromPdf extractTextFromPdf;
  final GenerateQuizWithAi generateQuizWithAi;
  final ParseQuestionsFromPdf parseQuestionsFromPdf; // ✅ NUEVO

  static const int maxActiveSubjectsFree = 2;
  static const int maxPdfsPerSubjectFree = 1;
  static const int maxPagesFree = 10;
  static const int maxMbSize = 10;

  PdfUploadBloc({
    required this.localConfig,
    required this.questionLocalDataSource,
    required this.extractTextFromPdf,
    required this.generateQuizWithAi,
    required this.parseQuestionsFromPdf, // ✅ NUEVO
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
      await questionLocalDataSource.deactivateExpiredSubjects();
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
    if (event.fileSizeMb > maxMbSize) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'El archivo supera el límite de ${maxMbSize}MB.',
        ),
      );
      return;
    }

    if (!state.isVip && event.pageCount > maxPagesFree) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage:
              'El PDF supera las $maxPagesFree páginas permitidas en el plan gratuito.',
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
                  'Has alcanzado el límite de $maxActiveSubjectsFree asignaturas activas simultáneamente.',
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
            errorMessage: 'Faltan campos obligatorios.',
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

      // ✅ DECISIÓN AUTOMÁTICA: Si es Free, ejecutar parser local inmediatamente
      if (!state.isVip) {
        final textResult = await extractTextFromPdf(
          ExtractTextFromPdfParams(pdfPath: filePath),
        );

        await textResult.fold(
          (failure) {
            // Si falla la extracción de texto, igual el PDF se guardó
            emit(
              state.copyWith(
                status: PdfUploadStatus.success,
                errorMessage:
                    'PDF guardado, pero no se pudieron extraer preguntas: ${failure.message}',
              ),
            );
          },
          (pdfText) async {
            final parseResult = await parseQuestionsFromPdf(
              ParseQuestionsParams(
                pdfText: pdfText,
                subject: state.subjectName,
              ),
            );

            await parseResult.fold(
              (failure) {
                emit(
                  state.copyWith(
                    status: PdfUploadStatus.success,
                    errorMessage:
                        'PDF guardado. ${failure.message}', // Mensaje de guía de formato
                  ),
                );
              },
              (questions) async {
                await questionLocalDataSource.insertQuestions(questions);
                emit(
                  state.copyWith(
                    status: PdfUploadStatus.success,
                    errorMessage:
                        '¡Éxito! PDF guardado y ${questions.length} preguntas extraídas.',
                  ),
                );
              },
            );
          },
        );
        return;
      }

      // Si es VIP, solo guardamos (el VIP usará el otro botón para IA)
      emit(
        state.copyWith(
          status: PdfUploadStatus.success,
          errorMessage: 'PDF guardado exitosamente.',
        ),
      );
    } on DatabaseException catch (e) {
      if (e.message == 'PDF_ALREADY_REPLACED') {
        emit(
          state.copyWith(
            status: PdfUploadStatus.error,
            errorMessage:
                'Ya has reemplazado el PDF de esta asignatura una vez. No puedes cambiarlo hasta que llegue la fecha del examen.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'Error al guardar: ${e.message}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'Error inesperado: $e',
        ),
      );
    }
  }

  Future<void> _onProcessAiRequested(
    ProcessAiRequested event,
    Emitter<PdfUploadState> emit,
  ) async {
    if (!state.isVip) {
      emit(
        state.copyWith(
          status: PdfUploadStatus.error,
          errorMessage: 'REQUIRES_SUBSCRIPTION',
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
