import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/injection_container.dart' as di;

class ManageSubjectsTab extends StatefulWidget {
  const ManageSubjectsTab({super.key});

  @override
  State<ManageSubjectsTab> createState() => _ManageSubjectsTabState();
}

class _ManageSubjectsTabState extends State<ManageSubjectsTab> {
  final QuestionLocalDataSource _datasource = di.sl<QuestionLocalDataSource>();

  List<Map<String, dynamic>> _allSubjects = [];
  List<AppInfo> _installedApps = [];
  bool _isLoading = true;

  // ✅ VARIABLES DEL FORMULARIO MOVIDAS AL ESTADO DE LA CLASE
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _pdfPath;
  String? _pdfName;
  int? _pdfPageCount;

  // ✅ NO FINAL para permitir modificación
  Set<String> _globalBlockedApps = {};

  // Lista negra de apps críticas
  static const List<String> _criticalAppPrefixes = [
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ✅ GETTER PARA VALIDACIÓN EN TIEMPO REAL
  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _pdfPath != null;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _datasource.getAllSubjects();
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );

      // Filtrar apps críticas y la propia app
      final safeApps = apps.where((app) {
        final lowerName = app.name.toLowerCase().replaceAll('_', ' ').trim();
        final lowerPackage = app.packageName.toLowerCase();

        if (lowerPackage.contains('study_blocker') ||
            lowerPackage.contains('dopamind') ||
            lowerName.contains('study blocker') ||
            lowerName.contains('dopamind')) {
          return false;
        }

        for (final prefix in _criticalAppPrefixes) {
          if (lowerPackage.startsWith(prefix)) return false;
        }
        return true;
      }).toList();

      // Cargar apps bloqueadas globales (subject_id = 0)
      final globalBlocked = await _datasource.getBlockedAppsForSubject(0);

      if (mounted) {
        setState(() {
          _allSubjects = subjects;
          _installedApps = safeApps;
          _globalBlockedApps = globalBlocked.toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      final file = result.files.first;

      // Validar tamaño máximo 10MB
      if (file.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo supera el límite de 10MB')),
        );
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

      // Validar máximo 10 páginas para usuarios free
      if (pageCount > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 10 páginas en versión gratuita'),
          ),
        );
        return;
      }

      setState(() {
        _pdfPath = file.path;
        _pdfName = file.name;
        _pdfPageCount = pageCount;
      });
    }
  }

  Future<void> _processGoal(bool useAI) async {
    if (!_isFormValid) return;

    final subjectName = _nameController.text.trim();

    // Validar límite de 2 asignaturas activas
    final activeCount = await _datasource.countActiveSubjects();
    if (activeCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 2 asignaturas activas en versión gratuita'),
        ),
      );
      return;
    }

    try {
      // Guardar asignatura y PDF
      await _datasource.saveSubjectAndPdf(
        subjectName: subjectName,
        examDate: _selectedDate!,
        filePath: _pdfPath!,
        pageCount: _pdfPageCount ?? 0,
      );

      // Guardar apps bloqueadas globales (subject_id = 0)
      await _datasource.saveBlockedApps(0, _globalBlockedApps.toList());

      if (mounted) {
        String msg = useAI
            ? 'Objetivo creado. Procesando con IA...'
            : '¡Objetivo de estudio creado exitosamente!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        // Si usamos IA, aquí iría la lógica adicional de llamada a la API
        // Por ahora, solo limpiamos y recargamos
        _clearForm();
        _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _selectedDate = null;
      _pdfPath = null;
      _pdfName = null;
      _pdfPageCount = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text(
          'Gestión',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff1e293b),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección: Asignaturas existentes
                  const Text(
                    'Mis Asignaturas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_allSubjects.isEmpty)
                    const Card(
                      color: Color(0xff1e293b),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No tienes asignaturas aún. Crea la primera abajo.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    ..._allSubjects.map((s) => _buildSubjectCard(s)),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Sección: Formulario unificado
                  const Text(
                    'Crear Nuevo Objetivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo: Nombre de asignatura
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    // ✅ onChanged llama a setState para actualizar el botón
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la asignatura',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Ej: Matemáticas',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon: Icon(
                        Icons.book_rounded,
                        color: Colors.white54,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo: Fecha de examen
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
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
                              _selectedDate == null
                                  ? 'Fecha del examen'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
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
                  const SizedBox(height: 16),

                  // Campo: PDF
                  InkWell(
                    onTap: _pickPdf,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _pdfPath != null
                            ? AppConstants.primaryColor.withValues(alpha: 0.1)
                            : const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _pdfPath != null
                              ? AppConstants.primaryColor
                              : Colors.white38,
                          width: _pdfPath != null ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pdfPath != null
                                ? Icons.picture_as_pdf_rounded
                                : Icons.cloud_upload_rounded,
                            size: 32,
                            color: _pdfPath != null
                                ? AppConstants.primaryColor
                                : Colors.white70,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pdfName ?? 'Toca para buscar un PDF',
                                  style: TextStyle(
                                    color: _pdfPath != null
                                        ? AppConstants.primaryColor
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_pdfPath == null) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Máximo 10 MB • Máximo 10 páginas',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_pdfPageCount páginas • $_pdfName',
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
                  const SizedBox(height: 24),

                  // Botones de Acción
                  Row(
                    children: [
                      // Botón 1: Procesar (Free)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isFormValid
                              ? () => _processGoal(false)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.text_snippet_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Procesar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón 2: Procesar con IA (VIP)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isFormValid
                              ? () => _processGoal(true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Procesar con IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Sección: Apps bloqueadas (global)
                  const Text(
                    'Apps a Bloquear (Global)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estas apps se bloquearán para todas tus asignaturas',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: _installedApps.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay apps disponibles',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _installedApps.length,
                            itemBuilder: (context, index) {
                              final app = _installedApps[index];
                              final isSelected = _globalBlockedApps.contains(
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
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _globalBlockedApps.add(app.packageName);
                                    } else {
                                      _globalBlockedApps.remove(
                                        app.packageName,
                                      );
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

                  // Botón para guardar cambios de apps
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _datasource.saveBlockedApps(
                        0,
                        _globalBlockedApps.toList(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Apps bloqueadas actualizadas'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar Configuración de Apps'),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final name = subject['name'] as String;
    final examDate = subject['exam_date'] as String?;
    final isActive = subject['is_active'] == 1;

    String dateText = 'Sin fecha';
    if (examDate != null) {
      try {
        final date = DateTime.parse(examDate);
        dateText = '${date.day}/${date.month}/${date.year}';
      } catch (_) {}
    }

    return Card(
      color: const Color(0xff1e293b),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.schedule,
          color: isActive ? Colors.green : Colors.orange,
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Examen: $dateText',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        // ✅ SIN BOTÓN DE ELIMINAR Y SIN TOGGLES
      ),
    );
  }
}
