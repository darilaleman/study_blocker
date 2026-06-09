import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/data/datasources/local/question_local_datasource.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_state.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final QuestionLocalDataSource _localDataSource = di
      .sl<QuestionLocalDataSource>();
  List<Map<String, dynamic>> _activeSubjectsData = [];
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    context.read<DashboardBloc>().add(LoadDashboardMetrics());
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final allSubjects = await _localDataSource.getAllSubjects();
      final active = allSubjects.where((s) => s['is_active'] == 1).toList();

      final enrichedData = <Map<String, dynamic>>[];
      for (var subject in active) {
        final pdfCount = await _localDataSource.countPdfsForSubject(
          subject['name'],
        );
        enrichedData.add({
          ...subject,
          'hasPdf': pdfCount > 0,
          'pdfCount': pdfCount,
        });
      }

      if (mounted) {
        setState(() {
          _activeSubjectsData = enrichedData;
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'Sin fecha';
    }
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
      ),
      body: RefreshIndicator(
        color: AppConstants.primaryColor,
        onRefresh: () async {
          await _loadDashboardData();
          if (mounted) {
            context.read<DashboardBloc>().add(LoadDashboardMetrics());
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. INFORMACIÓN DE RACHA (Sin botones)
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoaded) {
                  return Card(
                    color: const Color(0xff1e293b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 40,
                            color: state.studiedToday
                                ? Colors.orange
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Racha de estudio',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.currentStreak} días',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.studiedToday
                                      ? '¡Objetivo de hoy cumplido! 🎯'
                                      : 'Responde 1 pregunta para mantenerla',
                                  style: TextStyle(
                                    color: state.studiedToday
                                        ? Colors.orange[300]
                                        : Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            // 2. INFORMACIÓN DE ASIGNATURAS ACTIVAS
            const Text(
              'Tus Objetivos de Estudio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingSubjects)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                ),
              )
            else if (_activeSubjectsData.isEmpty)
              Card(
                color: const Color(0xff1e293b),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tienes asignaturas activas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ve a la pestaña "Gestión" para activar una asignatura, subir tu PDF y configurar el bloqueo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._activeSubjectsData.map((data) => _buildSubjectCard(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Sin nombre';
    final String dateStr = _formatDate(data['exam_date']);
    final bool hasPdf = data['hasPdf'] ?? false;
    final int pdfCount = data['pdfCount'] ?? 0;

    return Card(
      color: const Color(0xff1e293b),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasPdf
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hasPdf ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_rounded, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'Examen: $dateStr',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  hasPdf
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: hasPdf ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPdf
                      ? '$pdfCount PDF cargado${pdfCount > 1 ? "s" : ""}'
                      : 'Falta cargar el material PDF',
                  style: TextStyle(
                    color: hasPdf ? Colors.green[300] : Colors.orange[300],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
