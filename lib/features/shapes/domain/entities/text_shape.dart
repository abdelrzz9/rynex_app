import 'package:flutter/material.dart';
import 'shape.dart';
import 'shape_entity.dart';
import 'shape_type.dart';

class TextShape extends ShapeEntity {
  final String text;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  TextShape({
    required super.id,
    required super.boundingBox,
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 20.0,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(type: ShapeType.text);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'text',
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
        'rotation': rotation,
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeight': fontWeight.value,
        'textAlign': textAlign.name,
        'strokeColor': style.strokeColor.toARGB32(),
        'strokeWidth': style.strokeWidth,
        'strokeStyle': style.strokeStyle.name,
        'fillColor': style.fillColor.toARGB32(),
        'fillStyle': style.fillStyle.name,
        'roughness': style.roughness.name,
        'opacity': style.opacity,
        'layerOrder': layer.order,
        'isLocked': isLocked,
        'isVisible': isVisible,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  TextShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    String? text,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
  }) {
    return TextShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textAlign: textAlign ?? this.textAlign,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [...super.props, text, fontFamily, fontSize, fontWeight, textAlign];
}
