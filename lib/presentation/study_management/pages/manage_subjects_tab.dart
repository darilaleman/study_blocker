import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/injection_container.dart';

class ManageSubjectsTab extends StatefulWidget {
  const ManageSubjectsTab({super.key});

  @override
  State<ManageSubjectsTab> createState() => _ManageSubjectsTabState();
}

class _ManageSubjectsTabState extends State<ManageSubjectsTab> {
  final QuestionLocalDataSource _subjectDatasource = sl();
  List<Map<String, dynamic>> _subjects = [];
  List<AppInfo> _installedApps = [];
  final Set<String> _selectedPackageNames = {};
  int? _currentSubjectId;

  // ✅ LISTA NEGRA DE APPS CRÍTICAS DEL SISTEMA
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

  /// Verifica si una app es segura para ser bloqueada por el usuario
  bool _isAppSafeToBlock(AppInfo app) {
    // ✅ NORMALIZACIÓN: minúsculas y reemplaza guiones bajos por espacios.
    // Esto captura tanto "study_blocker" como "Study Blocker" sin fallar.
    final lowerName = app.name.toLowerCase().replaceAll('_', ' ').trim();
    final lowerPackage = app.packageName.toLowerCase();

    // 1. Bloquear explícitamente nuestra propia app por nombre o por paquete
    if (lowerPackage.contains('study_blocker') ||
        lowerPackage.contains('dopamind') ||
        lowerName.contains('study blocker') ||
        lowerName.contains('dopamind')) {
      return false;
    }

    // 2. Verificación por prefijos para apps críticas del sistema operativo
    for (final prefix in _criticalAppPrefixes) {
      if (lowerPackage.startsWith(prefix.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subjects = await _subjectDatasource.getAllSubjects();

    // Obtenemos todas las apps instaladas
    List<AppInfo> allApps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      withIcon: true,
    );

    // ✅ APLICAMOS EL FILTRO DE SEGURIDAD Y LIMPIEZA
    List<AppInfo> safeApps = allApps.where(_isAppSafeToBlock).toList();

    setState(() {
      _subjects = subjects;
      _installedApps = safeApps; // Usamos la lista ya filtrada
      if (subjects.isNotEmpty) {
        _currentSubjectId ??= subjects.first['id'];
        _loadBlockedApps(_currentSubjectId!);
      }
    });
  }

  Future<void> _loadBlockedApps(int subjectId) async {
    final blocked = await _subjectDatasource.getBlockedAppsForSubject(
      subjectId,
    );
    setState(() {
      _selectedPackageNames.clear();
      _selectedPackageNames.addAll(blocked);
    });
  }

  Future<void> _deleteSubject(int id) async {
    await _subjectDatasource.deleteSubject(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Asignatura eliminada")));
    }
    _loadData();
  }

  Future<void> _saveSettings() async {
    if (_currentSubjectId != null) {
      await _subjectDatasource.saveBlockedApps(
        _currentSubjectId!,
        _selectedPackageNames.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cambios guardados correctamente")),
        );
      }
    }
  }

  Future<void> _showCreateSubjectDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Asignatura"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Nombre de la asignatura",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final ctx = context;
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final exists = _subjects.any(
                (s) => s['name'].toLowerCase() == name.toLowerCase(),
              );
              if (exists) {
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Esta asignatura ya existe")),
                  );
                }
                return;
              }

              await _subjectDatasource.createSubject(
                name: name,
                isActive: false,
              );
              if (mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text("Crear"),
          ),
        ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveSettings,
            tooltip: "Guardar cambios de bloqueo",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.blueAccent,
                  size: 32,
                ),
                onPressed: _showCreateSubjectDialog,
                tooltip: "Crear nueva asignatura",
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._subjects.map(
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
                      onChanged: (val) async {
                        final ctx = context;
                        if (val) {
                          final count = await _subjectDatasource
                              .countActiveSubjects();
                          if (count >= 2) {
                            if (mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Máximo 2 asignaturas activas en versión gratuita",
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                        }
                        await _subjectDatasource.updateSubjectActive(
                          s['id'],
                          val,
                        );
                        _loadData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteSubject(s['id']),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const Text(
            "Bloqueo de Apps",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // ✅ LISTA DE APPS LIMPIA Y FILTRADA
          ..._installedApps.map(
            (app) => CheckboxListTile(
              title: Text(
                app.name,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              secondary: app.icon != null
                  ? Image.memory(app.icon!, width: 30, height: 30)
                  : const Icon(Icons.android, color: Colors.white54, size: 30),
              value: _selectedPackageNames.contains(app.packageName),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedPackageNames.add(app.packageName);
                  } else {
                    _selectedPackageNames.remove(app.packageName);
                  }
                });
              },
              activeColor: Colors.blueAccent,
              checkColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
