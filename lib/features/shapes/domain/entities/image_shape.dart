import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'shape_entity.dart';
import 'shape_type.dart';
import 'shape.dart';

class ImageShape extends ShapeEntity {
  final Uint8List imageBytes;
  final Size originalSize;

  ImageShape({
    required super.id,
    required super.boundingBox,
    required this.imageBytes,
    required this.originalSize,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(type: ShapeType.image);

  @override
  bool hitTest(Offset point) {
    final local = ShapeEntity.rotatePoint(point, center, -rotation);
    return boundingBox.contains(local);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'image',
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
        'rotation': rotation,
        'originalWidth': originalSize.width,
        'originalHeight': originalSize.height,
        'opacity': style.opacity,
        'layerOrder': layer.order,
        'isLocked': isLocked,
        'isVisible': isVisible,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  ImageShape copyWith({
    Rect? boundingBox,
    double? rotation,
    Uint8List? imageBytes,
    Size? originalSize,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
  }) {
    return ImageShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      imageBytes: imageBytes ?? this.imageBytes,
      originalSize: originalSize ?? this.originalSize,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [...super.props, imageBytes, originalSize];
}
