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
      debugPrint('Error al cargar datos del dashboard: $e');
      if (mounted) {
        setState(() => _isLoadingSubjects = false);
      }
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🏆 TARJETA DE RACHA
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          color: AppConstants.accentColor,
                        ),
                      ),
                    );
                  }

                  if (state is DashboardLoaded) {
                    final bool studiedToday = state.questionsAnswered > 0;
                    return Card(
                      color: const Color(0xff1e293b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: studiedToday
                              ? Colors.orange.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: studiedToday ? 2 : 0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 36,
                              color: studiedToday
                                  ? Colors.orange
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Racha de estudio',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${state.currentStreak} días',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    studiedToday
                                        ? '¡Objetivo de hoy cumplido! 🎯'
                                        : 'Responde 1 pregunta para mantenerla',
                                    style: TextStyle(
                                      color: studiedToday
                                          ? Colors.orange[300]
                                          : Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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

              const SizedBox(height: 20),

              // 📌 MURAL DE ASIGNATURAS ACTIVAS
              const Text(
                'Tus Objetivos de Estudio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _isLoadingSubjects
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    )
                  : _activeSubjectsData.isEmpty
                  ? Card(
                      color: const Color(0xff1e293b),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 36,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No tienes asignaturas activas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ve a la pestaña "Gestión" para crear tu primera asignatura.',
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
                  : Column(
                      children: _activeSubjectsData.map((data) {
                        return _buildMuralCard(data);
                      }).toList(),
                    ),

              const SizedBox(height: 20),

              // 🚀 Botón de estudiar voluntariamente (único botón del dashboard)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppConstants.routeQuizOverlay),
                icon: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Estudiar Voluntariamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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

  Widget _buildMuralCard(Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Sin nombre';
    final String dateStr = _formatDate(data['exam_date']);
    final bool hasPdf = data['hasPdf'] ?? false;

    return Card(
      color: const Color(0xff1e293b),
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
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: hasPdf ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Examen: $dateStr',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        hasPdf
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: hasPdf ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasPdf ? 'Material PDF cargado' : 'Falta cargar el PDF',
                        style: TextStyle(
                          color: hasPdf
                              ? Colors.green[300]
                              : Colors.orange[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
