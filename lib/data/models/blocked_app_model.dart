import 'dart:convert';
import 'package:study_blocker/domain/entities/blocked_app.dart';

class BlockedAppModel extends BlockedApp {
  const BlockedAppModel({
    super.id,
    required super.packageName,
    required super.appName,
  });

  /// Crea una instancia del Modelo a partir de una Entidad del Dominio.
  /// Útil cuando la UI te pasa una entidad y necesitas convertirla a modelo para guardarla.
  factory BlockedAppModel.fromEntity(BlockedApp entity) {
    return BlockedAppModel(
      id: entity.id,
      packageName: entity.packageName,
      appName: entity.appName,
    );
  }

  /// Convierte el Modelo en un Map (Key-Value) para poder insertarlo
  /// directamente en las tablas de SQLite o guardarlo en SharedPreferences.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'package_name': packageName,
      'app_name': appName,
    };
  }

  /// Construye el Modelo a partir de un Map proveniente de SQLite o SharedPreferences.
  factory BlockedAppModel.fromMap(Map<String, dynamic> map) {
    return BlockedAppModel(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
    );
  }

  /// Convierte el Modelo en una cadena de texto JSON.
  /// Útil si decides guardar la lista de apps bloqueadas como un String en SharedPreferences.
  String toJson() => json.encode(toMap());

  /// Construye el Modelo directamente desde una cadena de texto JSON.
  factory BlockedAppModel.fromJson(String source) =>
      BlockedAppModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
