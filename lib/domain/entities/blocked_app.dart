import 'package:equatable/equatable.dart';

/// Representa una aplicación del dispositivo que el usuario puede seleccionar para bloquear.
///
/// Al ser una Entidad de la capa de Dominio, es una clase pura de Dart,
/// inmutable y completamente desacoplada de la infraestructura técnica.
class BlockedApp extends Equatable {
  final int? id;
  final String
  packageName; // Ejemplo: 'com.instagram.android' o el ID de Apple Store
  final String appName; // Ejemplo: 'Instagram'

  const BlockedApp({this.id, required this.packageName, required this.appName});

  @override
  List<Object?> get props => [id, packageName, appName];

  @override
  String toString() => 'BlockedApp($appName, $packageName)';
}
