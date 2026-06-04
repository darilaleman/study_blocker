import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_state.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text(
          "Estadísticas",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff1e293b),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.accentColor),
            );
          }

          if (state is DashboardLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(
                  "Tiempo de estudio",
                  "${state.studyTimeMinutes} min",
                  Icons.timer_rounded,
                ),
                _buildStatCard(
                  "Preguntas respondidas",
                  "${state.questionsAnswered}",
                  Icons.quiz_rounded,
                ),
                _buildStatCard(
                  "Racha actual",
                  "${state.currentStreak} días",
                  Icons.local_fire_department_rounded,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Progreso por Asignatura",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Aquí podrías agregar un gráfico o una lista simplificada
              ],
            );
          }

          return const Center(
            child: Text(
              "No hay datos disponibles",
              style: TextStyle(color: Colors.white70),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: const Color(0xff1e293b),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppConstants.accentColor),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
