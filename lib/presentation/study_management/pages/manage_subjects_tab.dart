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
  bool _isVip =
      false; // Puedes conectar esto a tu AppConfigLocalDataSource si lo tienes

  // Estado del Formulario Unificado
  String? _selectedSubjectId;
  final TextEditingController _newSubjectController = TextEditingController();
  bool _isCreatingNew = false;
  DateTime? _selectedDate;
  String? _pdfPath;
  String? _pdfName;
  int? _pdfPages;
  final Set<String> _selectedApps = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
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
            lowerName.contains('study blocker'))
          return false;
        const critical = [
          'com.android.settings',
          'com.android.systemui',
          'com.google.android.gms',
        ];
        return !critical.any((p) => lowerPackage.startsWith(p));
      }).toList();

      if (mounted) {
        setState(() {
          _allSubjects = subjects;
          _installedApps = safeApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubjectActive(int id, bool isActive) async {
    if (isActive && !_isVip) {
      final count = await _datasource.countActiveSubjects();
      if (count >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Máximo 2 asignaturas activas en versión gratuita"),
            ),
          );
        }
        return;
      }
    }
    await _datasource.updateSubjectActive(id, isActive);
    _loadInitialData();
  }

  Future<void> _deleteSubject(int id) async {
    await _datasource.deleteSubject(id);
    _loadInitialData();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Máximo 10MB")));
        return;
      }
      int pages = 0;
      if (file.path != null) {
        try {
          pages = (await PDFDoc.fromPath(file.path!)).length;
        } catch (_) {}
      }
      if (!_isVip && pages > 10) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Máximo 10 páginas en versión gratuita"),
            ),
          );
        return;
      }
      setState(() {
        _pdfPath = file.path;
        _pdfName = file.name;
        _pdfPages = pages;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    final subjectName = _isCreatingNew
        ? _newSubjectController.text.trim()
        : (_allSubjects.firstWhere(
                (s) => s['id'] == _selectedSubjectId,
                orElse: () => {},
              )['name'] ??
              '');

    if (subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona o crea una asignatura")),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una fecha de examen")),
      );
      return;
    }
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un archivo PDF")),
      );
      return;
    }

    try {
      // 1. Guardar Asignatura y PDF
      await _datasource.saveSubjectAndPdf(
        subjectName: subjectName,
        examDate: _selectedDate!,
        filePath: _pdfPath!,
        pageCount: _pdfPages ?? 0,
      );

      // 2. Obtener ID y Guardar Apps Bloqueadas
      final subjects = await _datasource.getAllSubjects();
      final target = subjects.firstWhere((s) => s['name'] == subjectName);
      await _datasource.saveBlockedApps(target['id'], _selectedApps.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuración guardada exitosamente")),
        );
        _clearForm();
        _loadInitialData();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _clearForm() {
    setState(() {
      _selectedSubjectId = null;
      _newSubjectController.clear();
      _isCreatingNew = false;
      _selectedDate = null;
      _pdfPath = null;
      _pdfName = null;
      _pdfPages = null;
      _selectedApps.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text("Gestión", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff1e293b),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // SECCIÓN 1: LISTA DE ASIGNATURAS
                const Text(
                  "Mis Asignaturas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._allSubjects.map(
                  (s) => Card(
                    color: const Color(0xff1e293b),
                    child: ListTile(
                      title: Text(
                        s['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: s['is_active'] == 1,
                            onChanged: (val) =>
                                _toggleSubjectActive(s['id'], val),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteSubject(s['id']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),

                // SECCIÓN 2: FORMULARIO UNIFICADO
                const Text(
                  "Configurar Material y Bloqueo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Selector de Asignatura
                Row(
                  children: [
                    Expanded(
                      child: Checkbox(
                        value: _isCreatingNew,
                        onChanged: (val) =>
                            setState(() => _isCreatingNew = val ?? false),
                      ),
                    ),
                    const Text(
                      "Crear nueva asignatura",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                if (_isCreatingNew)
                  TextField(
                    controller: _newSubjectController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId?.toString(),
                    items: _allSubjects
                        .where((s) => s['is_active'] == 1)
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(
                      () => _selectedSubjectId =
                          int.tryParse(val ?? '') as String?,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Asignatura Activa',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                const SizedBox(height: 16),

                // Fecha
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white54),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Fecha de examen'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.white54
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PDF
                InkWell(
                  onTap: _pickPdf,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.white54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pdfName ?? 'Seleccionar PDF',
                            style: TextStyle(
                              color: _pdfName == null
                                  ? Colors.white54
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Apps
                const Text(
                  "Apps a bloquear:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: _installedApps
                        .map(
                          (app) => CheckboxListTile(
                            title: Text(
                              app.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            value: _selectedApps.contains(app.packageName),
                            onChanged: (val) => setState(
                              () => val == true
                                  ? _selectedApps.add(app.packageName)
                                  : _selectedApps.remove(app.packageName),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Guardar
                ElevatedButton(
                  onPressed: _saveConfiguration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Guardar Configuración",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
