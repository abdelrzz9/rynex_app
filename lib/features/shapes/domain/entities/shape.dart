import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../value_objects/fill_style.dart';
import '../value_objects/roughness.dart';
import '../value_objects/stroke_style.dart';

class ShapeStyle extends Equatable {
  final Color strokeColor;
  final double strokeWidth;
  final StrokeStyle strokeStyle;
  final Color fillColor;
  final FillStyle fillStyle;
  final Roughness roughness;
  final double opacity;

  const ShapeStyle({
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.strokeStyle = StrokeStyle.solid,
    this.fillColor = Colors.transparent,
    this.fillStyle = FillStyle.none,
    this.roughness = Roughness.none,
    this.opacity = 1.0,
  });

  ShapeStyle copyWith({
    Color? strokeColor,
    double? strokeWidth,
    StrokeStyle? strokeStyle,
    Color? fillColor,
    FillStyle? fillStyle,
    Roughness? roughness,
    double? opacity,
  }) {
    return ShapeStyle(
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeStyle: strokeStyle ?? this.strokeStyle,
      fillColor: fillColor ?? this.fillColor,
      fillStyle: fillStyle ?? this.fillStyle,
      roughness: roughness ?? this.roughness,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  List<Object?> get props => [
        strokeColor,
        strokeWidth,
        strokeStyle,
        fillColor,
        fillStyle,
        roughness,
        opacity,
      ];
}

class LayerInfo extends Equatable {
  final int order;
  final bool isVisible;
  final bool isLocked;
  final String? name;

  const LayerInfo({
    this.order = 0,
    this.isVisible = true,
    this.isLocked = false,
    this.name,
  });

  LayerInfo copyWith({
    int? order,
    bool? isVisible,
    bool? isLocked,
    String? name,
  }) {
    return LayerInfo(
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [order, isVisible, isLocked, name];
}
