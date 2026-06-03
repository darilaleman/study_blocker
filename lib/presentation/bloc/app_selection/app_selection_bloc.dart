import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/app_item.dart';
import '../../../../domain/entities/blocked_app.dart';
import '../../../../domain/repositories/app_block_repository.dart';
import 'app_selection_event.dart';
import 'app_selection_state.dart';

class AppSelectionBloc extends Bloc<AppSelectionEvent, AppSelectionState> {
  final AppBlockRepository repository;

  AppSelectionBloc({required this.repository}) : super(AppSelectionInitial()) {
    on<LoadInstalledApps>(_onLoadInstalledApps);
    on<ToggleAppCheckbox>(_onToggleAppCheckbox);
    on<SaveSelectedApps>(_onSaveSelectedApps);
  }

  Future<void> _onLoadInstalledApps(
    LoadInstalledApps event,
    Emitter<AppSelectionState> emit,
  ) async {
    emit(AppSelectionLoading());
    final result = await repository.getAvailableApplications();

    result.fold(
      (failure) => emit(
        AppSelectionError(
          'Error al cargar las aplicaciones: ${failure.message}',
        ),
      ),
      (availableApps) {
        final appItems = availableApps
            .map(
              (app) => AppItem(
                packageName: app.packageName,
                name: app.appName,
                icon: null,
                isSelected: false,
              ),
            )
            .toList();
        emit(AppSelectionLoaded(apps: appItems));
      },
    );
  }

  void _onToggleAppCheckbox(
    ToggleAppCheckbox event,
    Emitter<AppSelectionState> emit,
  ) {
    if (state is AppSelectionLoaded) {
      final currentState = state as AppSelectionLoaded;

      final updatedApps = currentState.apps.map((app) {
        if (app.packageName == event.packageName) {
          return app.copyWith(isSelected: !app.isSelected);
        }
        return app;
      }).toList();

      emit(AppSelectionLoaded(apps: updatedApps));
    }
  }

  Future<void> _onSaveSelectedApps(
    SaveSelectedApps event,
    Emitter<AppSelectionState> emit,
  ) async {
    if (state is! AppSelectionLoaded) return;

    final currentState = state as AppSelectionLoaded;
    final selectedApps = currentState.apps
        .where((app) => app.isSelected)
        .map(
          (app) => BlockedApp(packageName: app.packageName, appName: app.name),
        )
        .toList();

    emit(AppSelectionLoading());

    final result = await repository.updateBlockedApplications(selectedApps);

    result.fold(
      (failure) => emit(
        AppSelectionError('Error al guardar la selección: ${failure.message}'),
      ),
      (_) => emit(AppSelectionSavedSuccess()),
    );
  }
}
