import 'package:equatable/equatable.dart';
import '../../../../domain/entities/app_item.dart';

abstract class AppSelectionState extends Equatable {
  const AppSelectionState();

  @override
  List<Object> get props => [];
}

class AppSelectionInitial extends AppSelectionState {}

class AppSelectionLoading extends AppSelectionState {}

class AppSelectionLoaded extends AppSelectionState {
  final List<AppItem> apps;

  const AppSelectionLoaded({required this.apps});

  @override
  List<Object> get props => [apps];
}

class AppSelectionError extends AppSelectionState {
  final String message;

  const AppSelectionError(this.message);

  @override
  List<Object> get props => [message];
}

class AppSelectionSavedSuccess extends AppSelectionState {}
