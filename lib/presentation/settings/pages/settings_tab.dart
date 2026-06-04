import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:study_blocker/core/constants/app_constants.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_bloc.dart';
import 'package:study_blocker/presentation/auth/bloc/auth_event.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _version = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text(
          "Perfil y Ajustes",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff1e293b),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Cuenta"),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              "Cerrar Sesión",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),

          const Divider(color: Colors.white24),

          _buildSectionHeader("Preferencias"),
          SwitchListTile(
            title: const Text(
              "Notificaciones de estudio",
              style: TextStyle(color: Colors.white),
            ),
            value: true, // Aquí conectarías con tu estado de preferencias
            onChanged: (val) {},
            activeThumbColor: AppConstants.accentColor,
          ),

          const Divider(color: Colors.white24),

          _buildSectionHeader("Acerca de"),
          ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white70,
            ),
            title: const Text(
              "Versión de la App",
              style: TextStyle(color: Colors.white70),
            ),
            trailing: Text(
              _version,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mail_rounded, color: Colors.white70),
            title: const Text(
              "Contacto / Soporte",
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              // Implementar navegación a mailto: o formulario
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.accentColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
