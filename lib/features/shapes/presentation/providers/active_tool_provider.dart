import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../domain/entities/shape.dart';
import '../../domain/value_objects/fill_style.dart';
import '../../domain/value_objects/roughness.dart';
import '../../domain/value_objects/stroke_style.dart';

final activeToolProvider = StateProvider<DrawingTool>((ref) {
  return DrawingTool.select;
});

final activeStyleProvider = StateNotifierProvider<StyleNotifier, ShapeStyle>(
  (ref) => StyleNotifier(),
);

class StyleNotifier extends StateNotifier<ShapeStyle> {
  StyleNotifier() : super(const ShapeStyle());

  void setStrokeColor(Color color) {
    state = state.copyWith(strokeColor: color);
  }

  void setFillColor(Color color) {
    state = state.copyWith(fillColor: color);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void setStrokeStyle(StrokeStyle style) {
    state = state.copyWith(strokeStyle: style);
  }

  void setFillStyle(FillStyle style) {
    state = state.copyWith(fillStyle: style);
  }

  void setRoughness(Roughness roughness) {
    state = state.copyWith(roughness: roughness);
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity);
  }

  void reset() {
    state = const ShapeStyle();
  }
}
