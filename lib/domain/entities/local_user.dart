import 'package:flutter/material.dart';

/// Local account profile data shown by the presentation layer.
class LocalUser {
  const LocalUser({
    required this.username,
    required this.name,
    required this.email,
    required this.passwordSalt,
    required this.passwordHash,
    required this.avatarColor,
  });

  final String username;
  final String name;
  final String email;
  final String passwordSalt;
  final String passwordHash;
  final int avatarColor;

  String get displayName => name.trim().isEmpty ? username : name.trim();

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return '$first$second';
  }

  Color get avatarMaterialColor => Color(avatarColor);

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final legacyEmail = json['email'] as String? ?? '';
    final normalizedUsername = username.trim().isEmpty
        ? _normalizeLegacyUsername(legacyEmail)
        : username.trim().toLowerCase();
    return LocalUser(
      username: normalizedUsername,
      name: json['name'] as String? ?? '',
      email: legacyEmail.trim().toLowerCase(),
      passwordSalt: json['passwordSalt'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      avatarColor: json['avatarColor'] as int? ??
          _fallbackAvatarColor(normalizedUsername),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'email': email,
      'passwordSalt': passwordSalt,
      'passwordHash': passwordHash,
      'avatarColor': avatarColor,
    };
  }

  static int avatarColorFor(String username) => _fallbackAvatarColor(username);

  static String _normalizeLegacyUsername(String email) {
    final localPart = email.split('@').first.trim().toLowerCase();
    final sanitized = localPart.replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    return sanitized.isEmpty ? 'user' : sanitized;
  }

  static int _fallbackAvatarColor(String username) {
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
    final index = username.codeUnits
            .fold<int>(0, (sum, codeUnit) => sum + codeUnit) %
        palette.length;
    return palette[index];
  }
}
