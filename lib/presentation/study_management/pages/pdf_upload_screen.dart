import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/presentation/shared/widgets/loading_indicator.dart';
import '../bloc/pdf_upload_bloc.dart';
import '../bloc/pdf_upload_event.dart';
import '../bloc/pdf_upload_state.dart';

class PdfUploadScreen extends StatelessWidget {
  const PdfUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
  bool _isPdfLocked = false;

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

  Future<void> _checkPdfLockStatus(String subjectId) async {
    try {
      final subjects = await di.sl<QuestionLocalDataSource>().getAllSubjects();
      final subject = subjects.firstWhere(
        (s) => s['id'].toString() == subjectId,
      );

      final hasPdf =
          await di.sl<QuestionLocalDataSource>().countPdfsForSubject(
            subject['name'],
          ) >
          0;
      final isReplaced = subject['pdf_replaced'] == 1;

      if (mounted) {
        setState(() {
          _isPdfLocked = hasPdf && isReplaced;
        });
      }
    } catch (e) {
      debugPrint('Error al verificar estado del PDF: $e');
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
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else if (state.status == PdfUploadStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final isProcessing =
              state.status == PdfUploadStatus.loading ||
              state.status == PdfUploadStatus.aiProcessing;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. SELECTOR DE ASIGNATURA
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Asignatura Activa',
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
                            : (val) async {
                                setState(() => _selectedSubjectId = val);
                                if (val != null) {
                                  final name = widget.activeSubjects.firstWhere(
                                    (s) => s['id'].toString() == val,
                                  )['name'];
                                  context.read<PdfUploadBloc>().add(
                                    SubjectNameChanged(name),
                                  );
                                  await _checkPdfLockStatus(val);
                                }
                              },
                        validator: (value) =>
                            value == null ? 'Selecciona una asignatura' : null,
                      ),

                      if (widget.activeSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No tienes asignaturas activas. Ve al Dashboard para activar una.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 2. FECHA DE EXAMEN
                      InkWell(
                        onTap: isProcessing
                            ? null
                            : () => _pickExamDate(context, state.examDate),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                      ? 'Fecha de examen'
                                      : '${state.examDate!.day}/${state.examDate!.month}/${state.examDate!.year}',
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

                      const SizedBox(height: 12),

                      // 3. ZONA DE SELECCIÓN DE PDF CON ESTADO DE BLOQUEO
                      InkWell(
                        onTap: (isProcessing || _isPdfLocked)
                            ? null
                            : () => _pickPdfFile(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _isPdfLocked
                                ? Colors.red.withValues(alpha: 0.1)
                                : (state.fileName != null
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        )
                                      : const Color(0xff1e293b)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isPdfLocked
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : (state.fileName != null
                                        ? theme.colorScheme.primary
                                        : Colors.white38),
                              width: _isPdfLocked
                                  ? 2
                                  : (state.fileName != null ? 2 : 1.5),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPdfLocked
                                    ? Icons.lock_rounded
                                    : (state.fileName != null
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.cloud_upload_rounded),
                                size: 32,
                                color: _isPdfLocked
                                    ? Colors.red
                                    : (state.fileName != null
                                          ? theme.colorScheme.primary
                                          : Colors.white70),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPdfLocked
                                          ? 'PDF Bloqueado hasta el examen'
                                          : (state.fileName ??
                                                'Toca para buscar un PDF'),
                                      style: TextStyle(
                                        color: _isPdfLocked
                                            ? Colors.red
                                            : (state.fileName != null
                                                  ? theme.colorScheme.primary
                                                  : Colors.white),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (_isPdfLocked) ...[
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Ya usaste tu único cambio de PDF. No puedes modificarlo hasta la fecha del examen.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ] else if (state.fileName == null) ...[
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
                                        '${state.pageCount} páginas • ${state.filePath?.split('/').last ?? ''}',
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

                      const SizedBox(height: 16),

                      // 4. ✅ GUÍA DE FORMATO (SOLO PARA USUARIOS FREE)
                      if (!state.isVip) ...[
                        Card(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Plan Gratuito: Formato de Preguntas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Para generar preguntas automáticamente, tu PDF debe seguir este formato:\n\n'
                                  '1. ¿Cuál es la capital de Francia?\n'
                                  '   a) Madrid\n'
                                  '   b) París ✓\n'
                                  '   c) Londres\n'
                                  '   d) Berlín\n\n'
                                  'Usa "✓", "✔" o "*" para marcar la respuesta correcta.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      const ClipboardData(
                                        text:
                                            '1. ¿Tu pregunta aquí?\n   a) Opción incorrecta\n   b) Opción correcta ✓\n   c) Opción incorrecta\n   d) Opción incorrecta',
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Plantilla copiada al portapapeles',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text(
                                    'Copiar Formato de Plantilla',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 5. ✅ BOTÓN INTELIGENTE (cambia según VIP o Free)
                      ElevatedButton.icon(
                        onPressed:
                            (state.isFormValid &&
                                _selectedSubjectId != null &&
                                !isProcessing &&
                                !_isPdfLocked)
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  if (state.isVip) {
                                    context.read<PdfUploadBloc>().add(
                                      ProcessAiRequested(),
                                    );
                                  } else {
                                    context.read<PdfUploadBloc>().add(
                                      SavePdfRequested(),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              (state.isFormValid &&
                                  _selectedSubjectId != null &&
                                  !_isPdfLocked)
                              ? AppConstants.primaryColor
                              : const Color(0xff334155),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xff334155),
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  (state.isFormValid &&
                                      _selectedSubjectId != null &&
                                      !_isPdfLocked)
                                  ? Colors.transparent
                                  : Colors.white24,
                              width: 1,
                            ),
                          ),
                        ),
                        icon: Icon(
                          isProcessing
                              ? Icons.hourglass_empty_rounded
                              : (state.isVip
                                    ? Icons.auto_awesome_rounded
                                    : Icons.text_snippet_rounded),
                          color: Colors.white,
                          size: 22,
                        ),
                        label: Text(
                          isProcessing
                              ? 'Procesando...'
                              : (state.isVip
                                    ? 'Procesar con Inteligencia Artificial'
                                    : 'Procesar PDF (Formato Manual)'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      if (!(state.isFormValid && _selectedSubjectId != null) &&
                          !isProcessing &&
                          !_isPdfLocked) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Completa la asignatura, la fecha y el archivo para habilitar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],

                      if (_isPdfLocked) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Esta asignatura ya tiene un PDF asociado y se usó el cambio permitido.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // ✅ BOTÓN SECUNDARIO VIP (si es Free, ofrece upgrade)
                      if (!state.isVip) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppConstants.routeSubscription),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            ),
                            foregroundColor: Colors.amber,
                          ),
                          icon: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Desbloquear IA Premium',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Overlay de carga a pantalla completa
              if (isProcessing)
                const LoadingIndicator(
                  isFullScreen: true,
                  message: 'Procesando documento...',
                ),
            ],
          );
        },
      ),
    );
  }
}
