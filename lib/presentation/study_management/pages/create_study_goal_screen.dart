import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/presentation/shared/widgets/loading_indicator.dart';
import '../bloc/study_goal/study_goal_bloc.dart';
import '../bloc/study_goal/study_goal_event.dart';
import '../bloc/study_goal/study_goal_state.dart';

class CreateStudyGoalScreen extends StatelessWidget {
  const CreateStudyGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<StudyGoalBloc>()..add(LoadInitialData()),
      child: const CreateStudyGoalView(),
    );
  }
}

class CreateStudyGoalView extends StatefulWidget {
  const CreateStudyGoalView({super.key});

  @override
  State<CreateStudyGoalView> createState() => _CreateStudyGoalViewState();
}

class _CreateStudyGoalViewState extends State<CreateStudyGoalView> {
  final _formKey = GlobalKey<FormState>();
  final _newSubjectController = TextEditingController();
  bool _isNewSubject = false;

  Future<void> _pickExamDate(
    BuildContext context,
    DateTime? currentDate,
  ) async {
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 365));
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: now,
      lastDate: maxDate,
    );
    if (selectedDate != null && mounted) {
      context.read<StudyGoalBloc>().add(SetExamDate(selectedDate));
    }
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      final file = result.files.first;
      final sizeInMb = file.size ~/ (1024 * 1024);
      int pageCount = 0;
      if (file.path != null) {
        try {
          final pdfDoc = await PDFDoc.fromPath(file.path!);
          pageCount = pdfDoc.length;
        } catch (_) {}
      }

      context.read<StudyGoalBloc>().add(
        SelectPdf(
          filePath: file.path!,
          fileName: file.name,
          fileSizeMb: sizeInMb,
          pageCount: pageCount,
        ),
      );
    }
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e293b),
        title: const Text(
          'Nuevo Objetivo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<StudyGoalBloc, StudyGoalState>(
        listener: (context, state) {
          if (state.status == StudyGoalStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error desconocido'),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else if (state.status == StudyGoalStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Objetivo de estudio creado con éxito! 🚀'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.status == StudyGoalStatus.loading &&
              state.existingSubjects.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // FORMULARIO PRINCIPAL
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader('1. ¿Qué vas a estudiar?'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Usar existente'),
                                  selected: !_isNewSubject,
                                  onSelected: (val) =>
                                      setState(() => _isNewSubject = false),
                                  selectedColor: AppConstants.primaryColor,
                                  labelStyle: TextStyle(
                                    color: !_isNewSubject
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Crear nueva'),
                                  selected: _isNewSubject,
                                  onSelected: (val) =>
                                      setState(() => _isNewSubject = true),
                                  selectedColor: AppConstants.primaryColor,
                                  labelStyle: TextStyle(
                                    color: _isNewSubject
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isNewSubject)
                            TextFormField(
                              controller: _newSubjectController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la nueva asignatura',
                                prefixIcon: Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white54,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => context
                                  .read<StudyGoalBloc>()
                                  .add(CreateNewSubject(val)),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                  ? 'Ingresa un nombre'
                                  : null,
                            )
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Selecciona una asignatura',
                                prefixIcon: Icon(
                                  Icons.book_rounded,
                                  color: Colors.white54,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              dropdownColor: const Color(0xff1e293b),
                              style: const TextStyle(color: Colors.white),
                              items: state.existingSubjects.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s['id'].toString(),
                                  child: Text(s['name']),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final name = state.existingSubjects
                                      .firstWhere(
                                        (s) => s['id'].toString() == val,
                                      )['name'];
                                  context.read<StudyGoalBloc>().add(
                                    SelectSubject(val, name),
                                  );
                                }
                              },
                              validator: (val) => _isNewSubject
                                  ? null
                                  : (val == null
                                        ? 'Selecciona una asignatura'
                                        : null),
                            ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _pickExamDate(context, state.examDate),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Colors.white54,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      state.examDate == null
                                          ? 'Fecha de examen (Opcional)'
                                          : 'Examen: ${state.examDate!.day}/${state.examDate!.month}/${state.examDate!.year}',
                                      style: TextStyle(
                                        color: state.examDate == null
                                            ? Colors.white54
                                            : Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('2. Sube tu material'),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _pickPdfFile(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: state.pdfFileName != null
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : const Color(0xff1e293b),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: state.pdfFileName != null
                                      ? theme.colorScheme.primary
                                      : Colors.white38,
                                  width: state.pdfFileName != null ? 2 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    state.pdfFileName != null
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.cloud_upload_rounded,
                                    size: 32,
                                    color: state.pdfFileName != null
                                        ? theme.colorScheme.primary
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.pdfFileName ??
                                              'Toca para buscar un PDF',
                                          style: TextStyle(
                                            color: state.pdfFileName != null
                                                ? theme.colorScheme.primary
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (state.pdfFileName == null) ...[
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Máximo 10 MB',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.pdfPageCount} páginas • ${state.pdfFileName}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // SECCIÓN DE APPS BLOQUEADAS (SEPARADA DEL FORMULARIO)
                    _buildSectionHeader('3. Apps a bloquear (Global)'),
                    const SizedBox(height: 8),
                    Text(
                      'Estas apps se bloquearán para todas las asignaturas',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.installedApps.length,
                          itemBuilder: (context, index) {
                            final app = state.installedApps[index];
                            final isBlocked = state.blockedAppPackages.contains(
                              app.packageName,
                            );
                            return CheckboxListTile(
                              title: Text(
                                app.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              secondary: app.icon != null
                                  ? Image.memory(
                                      app.icon!,
                                      width: 24,
                                      height: 24,
                                    )
                                  : const Icon(
                                      Icons.android,
                                      color: Colors.white54,
                                      size: 24,
                                    ),
                              value: isBlocked,
                              onChanged: (val) {
                                context.read<StudyGoalBloc>().add(
                                  ToggleAppBlock(app.packageName),
                                );
                              },
                              activeColor: Colors.blueAccent,
                              checkColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // BOTÓN FINAL DE ACCIÓN
                    ElevatedButton(
                      onPressed: state.status == StudyGoalStatus.loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<StudyGoalBloc>().add(
                                  SaveStudyGoal(),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: state.isFormValid
                            ? AppConstants.primaryColor
                            : const Color(0xff334155),
                        disabledBackgroundColor: const Color(0xff334155),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.status == StudyGoalStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '🚀 ¡Empezar a estudiar!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    if (!state.isFormValid &&
                        state.status != StudyGoalStatus.loading) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Completa la asignatura y sube un PDF para habilitar el botón.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (state.status == StudyGoalStatus.loading)
                const LoadingIndicator(
                  isFullScreen: true,
                  message: 'Guardando tu objetivo...',
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
