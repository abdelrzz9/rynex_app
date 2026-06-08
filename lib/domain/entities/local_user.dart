import 'package:flutter/material.dart';

/// Local account profile data shown by the presentation layer.
class LocalUser {
  const LocalUser({
    required this.name,
    required this.email,
    required this.passwordSalt,
    required this.passwordHash,
    required this.avatarColor,
  });

  final String name;
  final String email;
  final String passwordSalt;
  final String passwordHash;
  final int avatarColor;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      final trimmedEmail = email.trim();
      return trimmedEmail.isEmpty ? '?' : trimmedEmail.characters.first.toUpperCase();
    }
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return '$first$second';
  }

  Color get avatarMaterialColor => Color(avatarColor);

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    return LocalUser(
      name: json['name'] as String? ?? '',
      email: email,
      passwordSalt: json['passwordSalt'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      avatarColor: json['avatarColor'] as int? ?? _fallbackAvatarColor(email),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'passwordSalt': passwordSalt,
      'passwordHash': passwordHash,
      'avatarColor': avatarColor,
    };
  }

  static int avatarColorFor(String email) => _fallbackAvatarColor(email);

  static int _fallbackAvatarColor(String email) {
    const palette = <int>[
      0xFF3F51B5,
      0xFF00897B,
      0xFFD81B60,
      0xFF5E35B1,
      0xFFEF6C00,
      0xFF3949AB,
      0xFF00ACC1,
      0xFF7CB342,
    ];
    final index =
        email.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit) %
            palette.length;
    return palette[index];
  }
}
