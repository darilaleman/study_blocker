import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/injection_container.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuestionLocalDataSource _subjectDatasource = sl();
  bool _isLoadingSubjects = true;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    context.read<DashboardBloc>().add(LoadDashboardMetrics());
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final subjects = await _subjectDatasource.getAllSubjects();
      setState(() {
        _subjects = subjects;
      });
    } catch (_) {
      // En este nivel, mantenemos la UI simple y permitimos que el usuario siga navegando.
    } finally {
      setState(() {
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _addSubject(String name) async {
    await _subjectDatasource.createSubject(name: name, isActive: false);
    await _loadSubjects();
  }

  void _showAddSubjectDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        title: const Text(
          'Añadir Asignatura',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre de la materia',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _addSubject(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubjectActive(int id, bool currentValue) async {
    final activeCount = _subjects.where((s) => s['is_active'] == 1).length;

    if (!currentValue && activeCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo puedes tener 2 asignaturas activas al mismo tiempo.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _subjectDatasource.updateSubjectActive(id, !currentValue);
    await _loadSubjects();
  }

  void _showManageSubjectsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xff1e293b),
            title: const Text(
              'Gestionar Asignaturas',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  final isActive = subject['is_active'] == 1;
                  return SwitchListTile(
                    title: Text(
                      subject['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      isActive ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    value: isActive,
                    activeColor: AppConstants.accentColor,
                    onChanged: (bool value) async {
                      await _toggleSubjectActive(
                        subject['id'] as int,
                        isActive,
                      );
                      setStateDialog(() {}); // Refrescar el modal
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text(
          'Dopamind Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff1e293b),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: AppConstants.accentColor,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppConstants.routeStats),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppConstants.primaryColor,
        onRefresh: () async =>
            context.read<DashboardBloc>().add(LoadDashboardMetrics()),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Aquí mantienes tu Container de "Filtro Activo" y el Row de métricas) ...
              const SizedBox(height: 24),
              const Text(
                'Mis Asignaturas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddSubjectDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nueva'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showManageSubjectsDialog,
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Gestionar'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              if (_isLoadingSubjects)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.accentColor,
                  ),
                )
              else if (_subjects.isEmpty)
                const Text(
                  'No tienes asignaturas registradas aún. Añade una para comenzar.',
                  style: TextStyle(color: Colors.white70),
                )
              else
                Column(
                  children: _subjects.map((subject) {
                    final isActive = subject['is_active'] == 1;
                    return Card(
                      color: const Color(0xff1e293b),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          subject['name'] as String,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          isActive ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.white54,
                          ),
                        ),
                        trailing: Switch(
                          value: isActive,
                          activeColor: AppConstants.accentColor,
                          onChanged: (_) => _toggleSubjectActive(
                            subject['id'] as int,
                            isActive,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppConstants.routeQuizOverlay),
                icon: const Icon(Icons.school_rounded, color: Colors.white),
                label: const Text(
                  'Estudiar Voluntariamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  elevation: 0,
                ),
                // Pasamos las asignaturas activas como argumento para el dropdown de la siguiente pantalla
                onPressed: () => Navigator.of(context).pushNamed(
                  AppConstants.routePdfUpload,
                  arguments: _subjects
                      .where((s) => s['is_active'] == 1)
                      .toList(),
                ),
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppConstants.textPrimary,
                ),
                label: const Text(
                  'Cargar Material PDF',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
