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

  // Usaremos el ID de la primera asignatura activa para el ejemplo,
  // o podrías agregar un Dropdown para seleccionar la asignatura actual.
  int? _currentSubjectId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subjects = await _subjectDatasource.getAllSubjects();

    // Obtenemos apps de terceros (excluye sistema)
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      withIcon: true,
    );

    setState(() {
      _subjects = subjects;
      _installedApps = apps;
      // Seleccionamos la primera asignatura por defecto si existe
      if (subjects.isNotEmpty) {
        _currentSubjectId = subjects.first['id'];
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
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Mis Asignaturas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ..._subjects.map(
            (s) => Card(
              color: const Color(0xff1e293b),
              child: ListTile(
                title: Text(
                  s['name'],
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Switch(
                  value: s['is_active'] == 1,
                  onChanged: (val) async {
                    await _subjectDatasource.updateSubjectActive(s['id'], val);
                    _loadData();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const Text(
            "Bloqueo de Apps (Selección en Vivo)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._installedApps.map(
            (app) => CheckboxListTile(
              title: Text(
                app.versionName,
                style: const TextStyle(color: Colors.white),
              ),
              secondary: app.icon != null
                  ? Image.memory(app.icon!, width: 30)
                  : null,
              value: _selectedPackageNames.contains(app.packageName),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    // 1. Usamos llaves para el if
                    // 2. Eliminamos el '!' porque packageName ya es un String no nulo
                    _selectedPackageNames.add(app.packageName);
                  } else {
                    // 3. Usamos llaves para el else
                    _selectedPackageNames.remove(app.packageName);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
