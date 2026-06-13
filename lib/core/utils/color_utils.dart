import 'package:flutter/material.dart';

int colorToInt(Color color) {
  return color.toARGB32();
}

Color colorFromInt(int value) {
  return Color(value);
}

String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}

Color? colorFromHex(String hex) {
  try {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.parse(hex, radix: 16);
    return Color(value);
  } catch (_) {
    return null;
  }
}

Color blendColors(Color a, Color b, double t) {
  return Color.lerp(a, b, t)!;
}

double getLuminance(Color color) {
  return color.computeLuminance();
}

bool isDark(Color color) {
  return getLuminance(color) < 0.5;
}

Color contrastingTextColor(Color background) {
  return isDark(background) ? Colors.white : Colors.black;
}

Color withOpacity(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}

Map<String, dynamic> colorToJson(Color color) {
  return {'r': color.r, 'g': color.g, 'b': color.b, 'a': color.a};
}

Color colorFromJson(Map<String, dynamic> json) {
  return Color.from(
    red: (json['r'] as num).toDouble(),
    green: (json['g'] as num).toDouble(),
    blue: (json['b'] as num).toDouble(),
    alpha: (json['a'] as num).toDouble(),
  );
}
