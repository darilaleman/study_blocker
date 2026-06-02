import 'dart:convert';
import 'package:study_blocker/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.id,
    required super.name,
    required super.email,
    required super.currentStreak,
    super.lastStudyDate,
    required super.isVip,
  });

  /// Crea una instancia de este Modelo a partir de una Entidad del Dominio.
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      currentStreak: entity.currentStreak,
      lastStudyDate: entity.lastStudyDate,
      isVip: entity.isVip,
    );
  }

  /// Convierte el Modelo en un Map (Key-Value) estructurado.
  /// SQLite no tiene booleanos nativos, por lo que convertimos [isVip] a 1 o 0.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'current_streak': currentStreak,
      'last_study_date': lastStudyDate
          ?.toIso8601String(), // Guarda como String ISO si no es nulo
      'is_vip': isVip ? 1 : 0, // 1 = true, 0 = false
    };
  }

  /// Construye el Modelo a partir de un Map proveniente de la persistencia local.
  /// Mapea de regreso el entero de SQLite (1/0) a un booleano real de Dart.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      currentStreak: map['current_streak'] as int,
      lastStudyDate: map['last_study_date'] != null
          ? DateTime.parse(map['last_study_date'] as String)
          : null,
      isVip: (map['is_vip'] as int) == 1,
    );
  }

  /// Convierte el Modelo en una cadena de texto JSON.
  String toJson() => jsonEncode(toMap());

  /// Construye el Modelo directamente desde una cadena de texto JSON.
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
