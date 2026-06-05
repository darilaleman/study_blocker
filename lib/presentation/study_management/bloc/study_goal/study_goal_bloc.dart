import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'study_goal_event.dart';
import 'study_goal_state.dart';

class StudyGoalBloc extends Bloc<StudyGoalEvent, StudyGoalState> {
  final AppConfigLocalDataSource localConfig;
  final QuestionLocalDataSource questionLocalDataSource;

  static const int maxActiveSubjectsFree = 2;
  static const int maxPdfsPerSubjectFree = 1;
  static const int maxPagesFree = 10;
  static const int maxMbSize = 10;

  StudyGoalBloc({
    required this.localConfig,
    required this.questionLocalDataSource,
  }) : super(const StudyGoalState()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<CreateNewSubject>(_onCreateNewSubject);
    on<SelectSubject>(_onSelectSubject);
    on<SetExamDate>(_onSetExamDate);
    on<SelectPdf>(_onSelectPdf);
    on<ToggleAppBlock>(_onToggleAppBlock);
    on<SaveStudyGoal>(_onSaveStudyGoal);
  }

  Future<void> _onLoadInitialData(
    LoadInitialData event,
    Emitter<StudyGoalState> emit,
  ) async {
    emit(state.copyWith(status: StudyGoalStatus.loading));
    try {
      final isVip = await localConfig.isVipUser();
      final subjects = await questionLocalDataSource.getAllSubjects();

      final allApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );

      // ✅ FILTRO INFALIBLE APLICADO AQUÍ
      final safeApps = allApps.where(_isAppSafeToBlock).toList();

      emit(
        state.copyWith(
          status: StudyGoalStatus.initial,
          isVip: isVip,
          existingSubjects: subjects,
          installedApps: safeApps,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StudyGoalStatus.error,
          errorMessage: 'Error al cargar datos: $e',
        ),
      );
    }
  }

  bool _isAppSafeToBlock(dynamic app) {
    final lowerName = app.name.toLowerCase().replaceAll('_', ' ').trim();
    final lowerPackage = app.packageName.toLowerCase();

    // 1. Bloqueo explícito de la propia app (cubriendo todas las variaciones)
    if (lowerPackage.contains('study_blocker') ||
        lowerPackage.contains('dopamind') ||
        lowerName.contains('study blocker') ||
        lowerName.contains('dopamind') ||
        lowerName == 'studyblocker' ||
        lowerPackage == 'com.example.study_blocker') {
      return false;
    }

    // 2. Apps críticas del sistema operativo
    const criticalPrefixes = [
      'com.android.settings',
      'com.android.systemui',
      'com.google.android.gms',
      'com.google.android.gsf',
      'com.android.phone',
      'com.android.dialer',
      'com.google.android.dialer',
      'com.android.incallui',
      'com.google.android.packageinstaller',
      'com.sec.android',
      'com.miui',
      'com.huawei',
      'com.google.android.googlequicksearchbox',
    ];

    for (final prefix in criticalPrefixes) {
      if (lowerPackage.startsWith(prefix)) return false;
    }
    return true;
  }

  void _onCreateNewSubject(
    CreateNewSubject event,
    Emitter<StudyGoalState> emit,
  ) {
    emit(
      state.copyWith(
        selectedSubjectId: null,
        selectedSubjectName: event.name.trim(),
      ),
    );
  }

  void _onSelectSubject(SelectSubject event, Emitter<StudyGoalState> emit) {
    emit(
      state.copyWith(
        selectedSubjectId: event.subjectId,
        selectedSubjectName: event.subjectName,
      ),
    );
  }

  void _onSetExamDate(SetExamDate event, Emitter<StudyGoalState> emit) {
    emit(state.copyWith(examDate: event.date));
  }

  void _onSelectPdf(SelectPdf event, Emitter<StudyGoalState> emit) {
    if (event.fileSizeMb > maxMbSize) {
      emit(
        state.copyWith(
          status: StudyGoalStatus.error,
          errorMessage: 'El archivo supera el límite de ${maxMbSize}MB.',
        ),
      );
      return;
    }
    if (!state.isVip && event.pageCount > maxPagesFree) {
      emit(
        state.copyWith(
          status: StudyGoalStatus.error,
          errorMessage:
              'El PDF supera las $maxPagesFree páginas permitidas en el plan gratuito.',
          pdfFilePath: null,
          pdfFileName: null,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: StudyGoalStatus.initial,
        pdfFilePath: event.filePath,
        pdfFileName: event.fileName,
        pdfPageCount: event.pageCount,
        errorMessage: null,
      ),
    );
  }

  void _onToggleAppBlock(ToggleAppBlock event, Emitter<StudyGoalState> emit) {
    final newBlocked = Set<String>.from(state.blockedAppPackages);
    if (newBlocked.contains(event.packageName)) {
      newBlocked.remove(event.packageName);
    } else {
      newBlocked.add(event.packageName);
    }
    emit(state.copyWith(blockedAppPackages: newBlocked));
  }

  Future<void> _onSaveStudyGoal(
    SaveStudyGoal event,
    Emitter<StudyGoalState> emit,
  ) async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          status: StudyGoalStatus.error,
          errorMessage: 'Por favor, completa la asignatura, la fecha y el PDF.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: StudyGoalStatus.loading));

    try {
      if (!state.isVip) {
        final activeCount = await questionLocalDataSource.countActiveSubjects();
        if (activeCount >= maxActiveSubjectsFree) {
          emit(
            state.copyWith(
              status: StudyGoalStatus.error,
              errorMessage:
                  'Has alcanzado el límite de $maxActiveSubjectsFree asignaturas activas en el plan gratuito.',
            ),
          );
          return;
        }

        if (state.selectedSubjectId != null) {
          final pdfCount = await questionLocalDataSource.countPdfsForSubject(
            state.selectedSubjectName!,
          );
          if (pdfCount >= maxPdfsPerSubjectFree) {
            emit(
              state.copyWith(
                status: StudyGoalStatus.error,
                errorMessage:
                    'Ya tienes el máximo de PDFs para esta asignatura en el plan gratuito.',
              ),
            );
            return;
          }
        }
      }

      // 1. Guardar/Actualizar Asignatura y PDF
      await questionLocalDataSource.saveSubjectAndPdf(
        subjectName: state.selectedSubjectName!,
        examDate: state.examDate!,
        filePath: state.pdfFilePath!,
        pageCount: state.pdfPageCount!,
      );

      // 2. Obtener el ID de la asignatura recién guardada
      final subjects = await questionLocalDataSource.getAllSubjects();
      final targetSubject = subjects.firstWhere(
        (s) => s['name'] == state.selectedSubjectName,
        orElse: () => throw Exception('Asignatura no encontrada tras guardar'),
      );
      final subjectId = targetSubject['id'] as int;

      // 3. Guardar apps bloqueadas
      await questionLocalDataSource.saveBlockedApps(
        subjectId,
        state.blockedAppPackages.toList(),
      );

      emit(state.copyWith(status: StudyGoalStatus.success));
    } catch (e) {
      String errorMsg = 'Error al guardar: $e';
      if (e.toString().contains('PDF_ALREADY_REPLACED')) {
        errorMsg =
            'Ya has reemplazado el PDF de esta asignatura una vez. No puedes cambiarlo hasta que llegue la fecha del examen.';
      }
      emit(
        state.copyWith(status: StudyGoalStatus.error, errorMessage: errorMsg),
      );
    }
  }
}
