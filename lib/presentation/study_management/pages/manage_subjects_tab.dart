import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/injection_container.dart';

class ManageSubjectsTab extends StatefulWidget {
  const ManageSubjectsTab({super.key});

  @override
  State<ManageSubjectsTab> createState() => _ManageSubjectsTabState();
}

class _ManageSubjectsTabState extends State<ManageSubjectsTab> {
  final QuestionLocalDataSource _datasource = sl();

  // Restricciones
  static const int maxActiveSubjectsFree = 2;
  static const int maxPdfsPerSubjectFree = 1;
  static const int maxPagesFree = 10;
  static const int maxMbSize = 10;

  // Controladores y estado
  final _subjectController = TextEditingController();
  DateTime? _examDate;
  String? _pdfFilePath;
  String? _pdfFileName;
  int? _pdfPageCount;
  int? _pdfSizeMb;
  final Set<String> _blockedApps = {};

  bool _isLoading = false;
  List<AppInfo> _installedApps = [];
  bool _isVip = false; // Esto debería venir de tu sistema de autenticación

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      setState(() {
        _installedApps = apps.where(_isAppSafeToBlock).toList();
      });
    } catch (e) {
      debugPrint('Error al cargar apps: $e');
    }
  }

  bool _isAppSafeToBlock(dynamic app) {
    final lowerName = app.name.toLowerCase().replaceAll('_', ' ').trim();
    final lowerPackage = app.packageName.toLowerCase();

    // No bloquear la propia app
    if (lowerPackage.contains('study_blocker') ||
        lowerPackage.contains('dopamind') ||
        lowerName.contains('study blocker') ||
        lowerName.contains('dopamind')) {
      return false;
    }

    // Apps críticas del sistema
    const criticalPrefixes = [
      'com.android.settings',
      'com.android.systemui',
      'com.google.android.gms',
      'com.android.phone',
      'com.android.dialer',
    ];

    for (final prefix in criticalPrefixes) {
      if (lowerPackage.startsWith(prefix)) return false;
    }

    return true;
  }

  Future<void> _selectExamDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      setState(() => _examDate = selectedDate);
    }
  }

  Future<void> _selectPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      final file = result.files.first;
      final sizeInMb = file.size ~/ (1024 * 1024);

      // Validar tamaño
      if (sizeInMb > maxMbSize) {
        _showError('El archivo supera el límite de ${maxMbSize}MB');
        return;
      }

      // Contar páginas
      int pageCount = 0;
      if (file.path != null) {
        try {
          final pdfDoc = await PDFDoc.fromPath(file.path!);
          pageCount = pdfDoc.length;
        } catch (_) {}
      }

      // Validar páginas (solo free)
      if (!_isVip && pageCount > maxPagesFree) {
        _showError(
          'El PDF supera las $maxPagesFree páginas permitidas en el plan gratuito',
        );
        return;
      }

      setState(() {
        _pdfFilePath = file.path;
        _pdfFileName = file.name;
        _pdfPageCount = pageCount;
        _pdfSizeMb = sizeInMb;
      });
    }
  }

  Future<void> _saveSubject() async {
    // Validaciones
    if (_subjectController.text.trim().isEmpty) {
      _showError('Ingresa el nombre de la asignatura');
      return;
    }

    if (_examDate == null) {
      _showError('Selecciona la fecha del examen');
      return;
    }

    if (_pdfFilePath == null) {
      _showError('Selecciona un archivo PDF');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar límites para usuarios free
      if (!_isVip) {
        final activeCount = await _datasource.countActiveSubjects();
        if (activeCount >= maxActiveSubjectsFree) {
          setState(() => _isLoading = false);
          _showError(
            'Has alcanzado el límite de $maxActiveSubjectsFree asignaturas activas',
          );
          return;
        }

        // Verificar si ya tiene un PDF esta asignatura
        final existingSubjects = await _datasource.getAllSubjects();
        final existingSubject = existingSubjects.firstWhere(
          (s) =>
              s['name'].toLowerCase() ==
              _subjectController.text.trim().toLowerCase(),
          orElse: () => {},
        );

        if (existingSubject.isNotEmpty) {
          final pdfCount = await _datasource.countPdfsForSubject(
            existingSubject['name'],
          );
          if (pdfCount >= maxPdfsPerSubjectFree) {
            setState(() => _isLoading = false);
            _showError(
              'Ya tienes el máximo de PDFs para esta asignatura (plan gratuito)',
            );
            return;
          }
        }
      }

      // Guardar asignatura y PDF
      await _datasource.saveSubjectAndPdf(
        subjectName: _subjectController.text.trim(),
        examDate: _examDate!,
        filePath: _pdfFilePath!,
        pageCount: _pdfPageCount!,
      );

      // Obtener el ID de la asignatura
      final subjects = await _datasource.getAllSubjects();
      final subject = subjects.firstWhere(
        (s) => s['name'] == _subjectController.text.trim(),
      );
      final subjectId = subject['id'] as int;

      // Guardar apps bloqueadas
      await _datasource.saveBlockedApps(subjectId, _blockedApps.toList());

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccess('Asignatura guardada correctamente');
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al guardar: $e');
      }
    }
  }

  void _clearForm() {
    setState(() {
      _subjectController.clear();
      _examDate = null;
      _pdfFilePath = null;
      _pdfFileName = null;
      _pdfPageCount = null;
      _pdfSizeMb = null;
      _blockedApps.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text(
          'Gestión de Estudio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff1e293b),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SECCIÓN 1: ASIGNATURA
                  const Text(
                    '1. Asignatura',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nombre de la asignatura',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.school, color: Colors.white54),
                      filled: true,
                      fillColor: Color(0xff1e293b),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECCIÓN 2: FECHA DE EXAMEN
                  const Text(
                    '2. Fecha del Examen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectExamDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _examDate == null
                                ? 'Seleccionar fecha'
                                : '${_examDate!.day}/${_examDate!.month}/${_examDate!.year}',
                            style: TextStyle(
                              color: _examDate == null
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

                  // SECCIÓN 3: PDF
                  const Text(
                    '3. Material PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectPdf,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _pdfFileName != null
                            ? AppConstants.primaryColor.withOpacity(0.1)
                            : const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _pdfFileName != null
                              ? AppConstants.primaryColor
                              : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pdfFileName != null
                                ? Icons.picture_as_pdf
                                : Icons.upload_file,
                            size: 48,
                            color: _pdfFileName != null
                                ? AppConstants.primaryColor
                                : Colors.white54,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _pdfFileName ?? 'Toca para seleccionar PDF',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _pdfFileName != null
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_pdfFileName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$_pdfPageCount páginas • $_pdfSizeMb MB',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (!_isVip) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Máximo $maxPagesFree páginas (Plan Free)',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECCIÓN 4: APPS A BLOQUEAR
                  const Text(
                    '4. Aplicaciones a Bloquear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecciona las apps que se bloquearán:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _installedApps.length,
                            itemBuilder: (context, index) {
                              final app = _installedApps[index];
                              final isBlocked = _blockedApps.contains(
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
                                  setState(() {
                                    if (val == true) {
                                      _blockedApps.add(app.packageName);
                                    } else {
                                      _blockedApps.remove(app.packageName);
                                    }
                                  });
                                },
                                activeColor: AppConstants.primaryColor,
                                checkColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // BOTÓN GUARDAR
                  ElevatedButton(
                    onPressed: _saveSubject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Guardar Asignatura',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (!_isVip) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Plan Free: Máximo 2 asignaturas activas, 1 PDF por asignatura (10 páginas máx)',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
