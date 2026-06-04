import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
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
  List<Application> _installedApps = [];
  final Set<String> _selectedPackageNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subjects = await _subjectDatasource.getAllSubjects();
    // Cargamos apps, excluyendo sistema para seguridad
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    setState(() {
      _subjects = subjects;
      _installedApps = apps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text("Gestionar", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff1e293b),
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
                app.appName,
                style: const TextStyle(color: Colors.white),
              ),
              secondary: app is ApplicationWithIcon
                  ? Image.memory(app.icon, width: 30)
                  : null,
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
            ),
          ),
        ],
      ),
    );
  }
}
