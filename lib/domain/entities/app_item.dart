import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class AppItem extends Equatable {
  final String packageName;
  final String name;
  final Uint8List? icon;
  final bool isSelected;

  const AppItem({
    required this.packageName,
    required this.name,
    this.icon,
    this.isSelected = false,
  });

  AppItem copyWith({
    String? packageName,
    String? name,
    Uint8List? icon,
    bool? isSelected,
  }) {
    return AppItem(
      packageName: packageName ?? this.packageName,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [packageName, name, icon, isSelected];
}
