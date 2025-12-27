import 'package:flutter/material.dart';

/// Dostępne kolory etykiet - zgodne z wersją web
enum LabelColor {
  red(name: 'Czerwony', hex: 0xFFef4444),
  orange(name: 'Pomarańczowy', hex: 0xFFf97316),
  yellow(name: 'Żółty', hex: 0xFFeab308),
  green(name: 'Zielony', hex: 0xFF22c55e),
  blue(name: 'Niebieski', hex: 0xFF3b82f6),
  purple(name: 'Fioletowy', hex: 0xFFa855f7),
  pink(name: 'Różowy', hex: 0xFFec4899),
  gray(name: 'Szary', hex: 0xFF6b7280);

  final String name;
  final int hex;
  
  const LabelColor({required this.name, required this.hex});
  
  Color get color => Color(hex);
}

/// Etykieta użytkownika
class UserLabel {
  final String id;
  final String name;
  final LabelColor color;

  UserLabel({
    required this.id,
    required this.name,
    required this.color,
  });

  factory UserLabel.fromJson(Map<String, dynamic> json) {
    return UserLabel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: LabelColor.values.firstWhere(
        (c) => c.name == json['color'],
        orElse: () => LabelColor.gray,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.name,
    };
  }
}

/// Limity
const int maxLabelsPerMedicine = 5;
const int maxLabelsGlobal = 15;
