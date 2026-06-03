import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_blocker/injection_container.dart';
import '../bloc/app_selection/app_selection_bloc.dart';
import '../bloc/app_selection/app_selection_event.dart';
import '../bloc/app_selection/app_selection_state.dart';

class AppSelectionScreen extends StatelessWidget {
  const AppSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AppSelectionBloc>()..add(LoadInstalledApps()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bloquear Aplicaciones'),
          centerTitle: true,
        ),
        body: BlocConsumer<AppSelectionBloc, AppSelectionState>(
          listener: (context, state) {
            if (state is AppSelectionSavedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preferencias guardadas exitosamente'),
                ),
              );
              Navigator.pop(context); // O redirigir al Dashboard
            }
          },
          builder: (context, state) {
            if (state is AppSelectionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AppSelectionError) {
              return Center(child: Text(state.message));
            } else if (state is AppSelectionLoaded) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Selecciona las aplicaciones que deseas bloquear hasta que completes tus cuestionarios.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.apps.length,
                      itemBuilder: (context, index) {
                        final app = state.apps[index];
                        return CheckboxListTile(
                          title: Text(app.name),
                          subtitle: Text(
                            app.packageName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: app.icon != null
                              ? Image.memory(app.icon!, width: 40, height: 40)
                              : const Icon(
                                  Icons.android,
                                  size: 40,
                                ), // Placeholder
                          value: app.isSelected,
                          onChanged: (bool? value) {
                            context.read<AppSelectionBloc>().add(
                              ToggleAppCheckbox(app.packageName),
                            );
                          },
                          activeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AppSelectionBloc>().add(
                            SaveSelectedApps(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Guardar Selección',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
