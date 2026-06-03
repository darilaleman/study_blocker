import 'package:flutter/material.dart';
import 'package:study_blocker/data/datasources/local/app_config_local_datasource.dart';
import 'package:study_blocker/domain/repositories/app_block_repository.dart';
import 'package:study_blocker/injection_container.dart' as di;

class OnboardingPermissionScreen extends StatefulWidget {
  const OnboardingPermissionScreen({super.key});

  @override
  State<OnboardingPermissionScreen> createState() =>
      _OnboardingPermissionScreenState();
}

class _OnboardingPermissionScreenState extends State<OnboardingPermissionScreen>
    with WidgetsBindingObserver {
  bool _isSystemAlertWindowGranted = false;
  bool _isUsageStatsGranted = false;
  bool _isCheckingPermissions = false;

  final AppBlockRepository _appBlockRepository = di.sl<AppBlockRepository>();
  final AppConfigLocalDataSource _localConfig = di
      .sl<AppConfigLocalDataSource>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCurrentPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCurrentPermissions();
    }
  }

  Future<void> _checkCurrentPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    final result = await _appBlockRepository.checkAndSyncPermissions();

    result.fold(
      (failure) {
        setState(() {
          _isSystemAlertWindowGranted = false;
          _isUsageStatsGranted = false;
          _isCheckingPermissions = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudieron verificar los permisos: ${failure.message}',
            ),
          ),
        );
      },
      (hasPermissions) {
        setState(() {
          _isSystemAlertWindowGranted = hasPermissions;
          _isUsageStatsGranted = hasPermissions;
          _isCheckingPermissions = false;
        });
      },
    );
  }

  void _requestSystemAlertWindow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abre la configuración del sistema y activa Superposición de Pantalla para Study Blocker.',
        ),
      ),
    );
    _checkCurrentPermissions();
  }

  void _requestUsageStats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abre la configuración del sistema y activa Estadísticas de Uso para Study Blocker.',
        ),
      ),
    );
    _checkCurrentPermissions();
  }

  Future<void> _navigateToNextScreen() async {
    await _localConfig.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Evaluamos la combinación de permisos de forma dinámica.
    // Al no ser constantes estáticas, Dart ya no detectará código muerto.
    final bool allPermissionsGranted =
        _isSystemAlertWindowGranted && _isUsageStatsGranted;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.security_update_good_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Permisos Necesarios',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para que Study Blocker pueda restringir las aplicaciones de distracción mientras estudias, necesitamos que habilites los siguientes accesos del sistema.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // PERMISO 1: SUPERPOSICIÓN DE PANTALLA
              _PermissionTile(
                icon: Icons.picture_in_picture_rounded,
                title: 'Superposición de Pantalla',
                description:
                    'Permite mostrar el cuestionario interactivo de bloqueo por encima de las apps restringidas.',
                isGranted: _isSystemAlertWindowGranted,
                onPressed: _isCheckingPermissions
                    ? () {}
                    : _requestSystemAlertWindow,
              ),
              const SizedBox(height: 12),

              // PERMISO 2: ESTADÍSTICAS DE USO
              _PermissionTile(
                icon: Icons.bar_chart_rounded,
                title: 'Estadísticas de Uso',
                description:
                    'Permite al servicio en segundo plano detectar qué aplicación se está abriendo en tiempo real.',
                isGranted: _isUsageStatsGranted,
                onPressed: _isCheckingPermissions ? () {} : _requestUsageStats,
              ),

              const Spacer(),

              // BOTÓN DE ACCIÓN PRINCIPAL CONTROLADO POR EL ESTADO NATIVO
              FilledButton(
                onPressed: allPermissionsGranted && !_isCheckingPermissions
                    ? _navigateToNextScreen
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isCheckingPermissions
                      ? 'Verificando permisos...'
                      : allPermissionsGranted
                      ? 'Comenzar a Enfocarme'
                      : 'Concede los permisos para continuar',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onPressed;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
          width: isGranted ? 1.5 : 1,
        ),
      ),
      color: isGranted
          ? Colors.green.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isGranted
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isGranted
                ? const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 28,
                    ),
                  )
                : OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Activar'),
                  ),
          ],
        ),
      ),
    );
  }
}
