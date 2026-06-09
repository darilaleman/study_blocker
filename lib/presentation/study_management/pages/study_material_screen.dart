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

  List<Map<String, dynamic>> _subjects = [];
  List<AppInfo> _installedApps = [];
  bool _isLoading = true;

  // Lista negra de apps que no deben aparecer
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

  bool _isAppSafeToBlock(AppInfo app) {
    final lowerName = app.name.toLowerCase().replaceAll('_', ' ').trim();
    final lowerPackage = app.packageName.toLowerCase();

    // No mostrar la propia app
    if (lowerPackage.contains('study_blocker') ||
        lowerPackage.contains('dopamind') ||
        lowerName.contains('study blocker') ||
        lowerName.contains('dopamind')) {
      return false;
    }

    // No mostrar apps críticas del sistema
    for (final prefix in _criticalAppPrefixes) {
      if (lowerPackage.startsWith(prefix)) return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _datasource.getAllSubjects();
      final allApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      final safeApps = allApps.where(_isAppSafeToBlock).toList();

      if (mounted) {
        setState(() {
          _subjects = subjects;
          _installedApps = safeApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubjectActive(int id, bool isActive) async {
    if (isActive) {
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
    _loadData();
  }

  Future<void> _deleteSubject(int id) async {
    await _datasource.deleteSubject(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Asignatura eliminada")));
    }
    _loadData();
  }

  // ✅ NUEVO: Diálogo unificado para crear asignatura con todo el flujo
  Future<void> _showCreateSubjectFlow() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;
    String? pdfPath;
    String? pdfName;
    int? pdfPageCount;
    final Set<String> selectedApps = {};

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xff1e293b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xff0f172a),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Nueva Asignatura',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Contenido scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Nombre
                        const Text(
                          '1. Nombre de la asignatura',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Ej: Matemáticas',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Color(0xff0f172a),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 2. Fecha de examen
                        const Text(
                          '2. Fecha del examen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff0f172a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedDate == null
                                        ? 'Seleccionar fecha'
                                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                    style: TextStyle(
                                      color: selectedDate == null
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
                        const SizedBox(height: 20),

                        // 3. PDF
                        const Text(
                          '3. Material PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null) {
                              final file = result.files.first;
                              int pages = 0;
                              if (file.path != null) {
                                try {
                                  final doc = await PDFDoc.fromPath(file.path!);
                                  pages = doc.length;
                                } catch (_) {}
                              }
                              setDialogState(() {
                                pdfPath = file.path;
                                pdfName = file.name;
                                pdfPageCount = pages;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: pdfPath != null
                                  ? AppConstants.primaryColor.withValues(
                                      alpha: 0.1,
                                    )
                                  : const Color(0xff0f172a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pdfPath != null
                                    ? AppConstants.primaryColor
                                    : Colors.white38,
                                width: pdfPath != null ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  pdfPath != null
                                      ? Icons.picture_as_pdf
                                      : Icons.cloud_upload,
                                  size: 28,
                                  color: pdfPath != null
                                      ? AppConstants.primaryColor
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pdfName ?? 'Toca para seleccionar PDF',
                                        style: TextStyle(
                                          color: pdfPath != null
                                              ? AppConstants.primaryColor
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (pdfPath != null)
                                        Text(
                                          '$pdfPageCount páginas',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Apps a bloquear
                        const Text(
                          '4. Apps a bloquear (opcional)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xff0f172a),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: _installedApps.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Cargando apps...',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _installedApps.length,
                                  itemBuilder: (context, index) {
                                    final app = _installedApps[index];
                                    final isSelected = selectedApps.contains(
                                      app.packageName,
                                    );
                                    return CheckboxListTile(
                                      title: Text(
                                        app.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
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
                                        setDialogState(() {
                                          if (val == true) {
                                            selectedApps.add(app.packageName);
                                          } else {
                                            selectedApps.remove(
                                              app.packageName,
                                            );
                                          }
                                        });
                                      },
                                      activeColor: Colors.blueAccent,
                                      checkColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                      dense: true,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón de guardar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xff0f172a),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (nameController.text.trim().isNotEmpty &&
                              selectedDate != null &&
                              pdfPath != null)
                          ? () async {
                              try {
                                // Guardar asignatura y PDF
                                await _datasource.saveSubjectAndPdf(
                                  subjectName: nameController.text.trim(),
                                  examDate: selectedDate!,
                                  filePath: pdfPath!,
                                  pageCount: pdfPageCount ?? 0,
                                );

                                // Obtener ID de la asignatura recién creada
                                final subjects = await _datasource
                                    .getAllSubjects();
                                final newSubject = subjects.firstWhere(
                                  (s) =>
                                      s['name'] == nameController.text.trim(),
                                );
                                final subjectId = newSubject['id'] as int;

                                // Guardar apps bloqueadas
                                if (selectedApps.isNotEmpty) {
                                  await _datasource.saveBlockedApps(
                                    subjectId,
                                    selectedApps.toList(),
                                  );
                                }

                                if (mounted) {
                                  Navigator.pop(context); // Cerrar diálogo
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Asignatura creada exitosamente',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadData(); // Recargar lista
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al crear: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Crear Asignatura',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text("Gestionar", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff1e293b),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header con botón de crear
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mis Asignaturas",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateSubjectFlow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Nueva',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de asignaturas
                if (_subjects.isEmpty)
                  Card(
                    color: const Color(0xff1e293b),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay asignaturas creadas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca "Nueva" para crear tu primera asignatura',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._subjects.map(
                    (s) => Card(
                      color: const Color(0xff1e293b),
                      child: ListTile(
                        title: Text(
                          s['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          s['is_active'] == 1 ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            color: s['is_active'] == 1
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: s['is_active'] == 1,
                              onChanged: (val) =>
                                  _toggleSubjectActive(s['id'], val),
                              activeThumbColor: Colors.green,
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

                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),

                // Sección de apps bloqueadas (informativa)
                const Text(
                  "Apps bloqueadas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las apps se seleccionan al crear una nueva asignatura',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
    );
  }
}
