import 'package:equatable/equatable.dart';

abstract class AppSelectionEvent extends Equatable {
  const AppSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadInstalledApps extends AppSelectionEvent {}

class ToggleAppCheckbox extends AppSelectionEvent {
  final String packageName;

  const ToggleAppCheckbox(this.packageName);

  @override
  List<Object> get props => [packageName];
}

class SaveSelectedApps extends AppSelectionEvent {}
