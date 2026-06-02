import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Forzar la recarga de métricas al montar el panel
    context.read<DashboardBloc>().add(LoadDashboardMetrics());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a), // Slate oscuro unificado
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
            onPressed: () => Navigator.of(context).pushNamed('/stats'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppConstants.primaryColor,
        onRefresh: () async {
          context.read<DashboardBloc>().add(LoadDashboardMetrics());
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
              );
            }

            if (state is DashboardError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            int streak = 0;
            int todayAnswered = 0;

            if (state is DashboardLoaded) {
              streak = state.currentStreak;
              todayAnswered = state.todayAnsweredCount;
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Estado del bloqueo de Apps
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff6366f1), Color(0xff06b6d4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Filtro Activo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'El acceso a tus aplicaciones bloqueadas requiere la resolución de cuestionarios periódicos.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid de métricas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          title: 'Racha de Estudio',
                          value: '$streak días',
                          icon: Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatTile(
                          title: 'Completadas Hoy',
                          value: '$todayAnswered',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppConstants.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Botón de sesión de estudio manual
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/quiz'),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
