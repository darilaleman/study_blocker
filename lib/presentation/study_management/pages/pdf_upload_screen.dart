import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/presentation/shared/widgets/loading_indicator.dart';
import '../bloc/pdf_upload_bloc.dart';
import '../bloc/pdf_upload_event.dart';
import '../bloc/pdf_upload_state.dart';

class PdfUploadScreen extends StatelessWidget {
  const PdfUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperamos las asignaturas activas pasadas desde el Dashboard
    final activeSubjects =
        ModalRoute.of(context)?.settings.arguments
            as List<Map<String, dynamic>>? ??
        [];

    return BlocProvider(
      create: (context) => di.sl<PdfUploadBloc>()..add(InitializePdfUpload()),
      child: PdfUploadView(activeSubjects: activeSubjects),
    );
  }
}

class PdfUploadView extends StatefulWidget {
  final List<Map<String, dynamic>> activeSubjects;
  const PdfUploadView({super.key, required this.activeSubjects});

  @override
  State<PdfUploadView> createState() => _PdfUploadViewState();
}

class _PdfUploadViewState extends State<PdfUploadView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectId;

  Future<void> _pickExamDate(
    BuildContext context,
    DateTime? currentDate,
  ) async {
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 7));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: now,
      lastDate: maxDate,
    );

    if (selectedDate != null && mounted) {
      context.read<PdfUploadBloc>().add(ExamDateChanged(selectedDate));
    }
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      final PlatformFile file = result.files.first;
      final int sizeInMb = file.size ~/ (1024 * 1024);
      final int pageCount = await _resolvePageCount(file.path);

      context.read<PdfUploadBloc>().add(
        PdfFileSelected(
          filePath: file.path!,
          fileName: file.name,
          fileSizeMb: sizeInMb,
          pageCount: pageCount,
        ),
      );
    }
  }

  Future<int> _resolvePageCount(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return 0;

    try {
      final pdfDoc = await PDFDoc.fromPath(filePath);
      return pdfDoc.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e293b),
        title: const Text(
          'Configurar Material',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<PdfUploadBloc, PdfUploadState>(
        listener: (context, state) {
          if (state.status == PdfUploadStatus.error) {
            if (state.errorMessage == 'REQUIRES_SUBSCRIPTION') {
              Navigator.of(context).pushNamed(AppConstants.routeSubscription);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          } else if (state.status == PdfUploadStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF guardado en la base de datos.'),
                backgroundColor: Colors.blueAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          final isProcessing =
              state.status == PdfUploadStatus.loading ||
              state.status == PdfUploadStatus.aiProcessing;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SELECTOR DE ASIGNATURA EN LUGAR DE TEXTFIELD
                      DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Selecciona una Asignatura Activa',
                          prefixIcon: Icon(
                            Icons.book_rounded,
                            color: Colors.white54,
                          ),
                        ),
                        dropdownColor: const Color(0xff1e293b),
                        style: const TextStyle(color: Colors.white),
                        items: widget.activeSubjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject['id'].toString(),
                            child: Text(subject['name']),
                          );
                        }).toList(),
                        onChanged: isProcessing
                            ? null
                            : (val) {
                                setState(() => _selectedSubjectId = val);
                                if (val != null) {
                                  final name = widget.activeSubjects.firstWhere(
                                    (s) => s['id'].toString() == val,
                                  )['name'];
                                  context.read<PdfUploadBloc>().add(
                                    SubjectNameChanged(name),
                                  );
                                }
                              },
                        validator: (value) => value == null
                            ? 'Debes seleccionar una asignatura activa'
                            : null,
                      ),

                      if (widget.activeSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No tienes asignaturas activas. Ve al Dashboard para activar una.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // FECHA DE EXAMEN
                      InkWell(
                        onTap: isProcessing
                            ? null
                            : () => _pickExamDate(context, state.examDate),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                state.examDate == null
                                    ? 'Seleccionar fecha de examen'
                                    : '${state.examDate!.day}/${state.examDate!.month}/${state.examDate!.year}',
                                style: TextStyle(
                                  color: state.examDate == null
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SELECCIÓN DE ARCHIVO CON FILE_PICKER
                      InkWell(
                        onTap: isProcessing
                            ? null
                            : () => _pickPdfFile(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: state.fileName != null
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: state.fileName != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: state.fileName != null ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                state.fileName != null
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.cloud_upload_rounded,
                                size: 48,
                                color: state.fileName != null
                                    ? theme.colorScheme.primary
                                    : Colors.white54,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.fileName ??
                                    'Abrir Explorador y Seleccionar PDF',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: state.fileName != null
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed:
                            state.isFormValid &&
                                !isProcessing &&
                                _selectedSubjectId != null
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<PdfUploadBloc>().add(
                                    SavePdfRequested(),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Cargar y Guardar PDF',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed:
                            state.status == PdfUploadStatus.success &&
                                !isProcessing
                            ? () => context.read<PdfUploadBloc>().add(
                                ProcessAiRequested(),
                              )
                            : (!state.isVip
                                  ? () => Navigator.of(
                                      context,
                                    ).pushNamed(AppConstants.routeSubscription)
                                  : null),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: state.isVip
                              ? AppConstants.primaryColor
                              : Colors.grey[800],
                        ),
                        icon: Icon(
                          state.isVip
                              ? Icons.auto_awesome_rounded
                              : Icons.lock_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          state.isVip
                              ? 'Procesar con Inteligencia Artificial'
                              : 'Procesar con IA (VIP Requerido)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.status == PdfUploadStatus.loading)
                const LoadingIndicator(
                  isFullScreen: true,
                  message: 'Validando límites y guardando PDF...',
                ),
            ],
          );
        },
      ),
    );
  }
}
