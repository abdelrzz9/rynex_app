import 'package:flutter/material.dart';

int colorToJson(Color color) => color.toARGB32();

Color colorFromJson(int value) {
  return Color.fromARGB(
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  );
}
