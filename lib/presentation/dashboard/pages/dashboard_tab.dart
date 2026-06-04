import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:study_blocker/presentation/dashboard/bloc/dashboard_state.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardMetrics());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Método que carga tus asignaturas en el Dashboard
    });
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
        onRefresh: () async =>
            context.read<DashboardBloc>().add(LoadDashboardMetrics()),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aquí iría tu lógica de métricas (BlocBuilder)
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.accentColor,
                      ),
                    );
                  }
                  // Aquí renderizas tus métricas basadas en el estado
                  return const SizedBox();
                },
              ),

              const SizedBox(height: 40),

              // Botones de acción rápida
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

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 2,
                  ),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppConstants.routePdfUpload),
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
