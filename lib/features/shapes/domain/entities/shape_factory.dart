import 'dart:convert';
import 'package:flutter/material.dart';
import '../value_objects/fill_style.dart';
import '../value_objects/roughness.dart';
import '../value_objects/stroke_style.dart';
import 'arrow_shape.dart';
import 'diamond_shape.dart';
import 'ellipse_shape.dart';
import 'freehand_shape.dart';
import 'image_shape.dart';
import 'line_shape.dart';
import 'polygon_shape.dart';
import 'rectangle_shape.dart';
import 'shape.dart';
import 'shape_entity.dart';
import 'text_shape.dart';
import 'triangle_shape.dart';

class _ShapeBaseFields {
  final String id;
  final double rotation;
  final ShapeStyle style;
  final LayerInfo layer;
  final bool isLocked;
  final bool isVisible;
  final DateTime createdAt;

  _ShapeBaseFields({
    required this.id,
    required this.rotation,
    required this.style,
    required this.layer,
    required this.isLocked,
    required this.isVisible,
    required this.createdAt,
  });
}

class ShapeFactory {
  static ShapeEntity fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'rectangle':
      case 'roundedRect':
        return _parseRectangle(json);
      case 'ellipse':
        return _parseEllipse(json);
      case 'diamond':
        return _parseDiamond(json);
      case 'triangle':
        return _parseTriangle(json);
      case 'polygon':
        return _parsePolygon(json);
      case 'line':
        return _parseLine(json);
      case 'arrow':
        return _parseArrow(json);
      case 'freehand':
        return _parseFreehand(json);
      case 'text':
        return _parseText(json);
      case 'image':
        return _parseImage(json);
      default:
        return _parseRectangle(json);
    }
  }

  static _ShapeBaseFields _parseBaseFields(Map<String, dynamic> json) {
    return _ShapeBaseFields(
      id: json['id'] as String,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      style: _parseStyle(json),
      layer: _parseLayer(json),
      isLocked: json['isLocked'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
      createdAt: _parseDate(json),
    );
  }

  static ShapeStyle _parseStyle(Map<String, dynamic> json) {
    return ShapeStyle(
      strokeColor: Color(json['strokeColor'] as int),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeStyle: StrokeStyle.values.firstWhere(
        (e) => e.name == json['strokeStyle'],
        orElse: () => StrokeStyle.solid,
      ),
      fillColor: json['fillColor'] != null
          ? Color(json['fillColor'] as int)
          : Colors.transparent,
      fillStyle: FillStyle.values.firstWhere(
        (e) => e.name == json['fillStyle'],
        orElse: () => FillStyle.none,
      ),
      roughness: Roughness.values.firstWhere(
        (e) => e.name == json['roughness'],
        orElse: () => Roughness.none,
      ),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static LayerInfo _parseLayer(Map<String, dynamic> json) {
    return LayerInfo(
      order: (json['layerOrder'] as num?)?.toInt() ?? 0,
      isLocked: json['isLocked'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  static DateTime _parseDate(Map<String, dynamic> json) {
    final str = json['createdAt'] as String?;
    if (str != null) return DateTime.parse(str);
    return DateTime.now();
  }

  static RectangleShape _parseRectangle(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return RectangleShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static EllipseShape _parseEllipse(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return EllipseShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }

  static DiamondShape _parseDiamond(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return DiamondShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }

  static TriangleShape _parseTriangle(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return TriangleShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
      direction: json['direction'] != null
          ? TriangleDirection.values.firstWhere((d) => d.name == json['direction'])
          : TriangleDirection.up,
    );
  }

  static PolygonShape _parsePolygon(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return PolygonShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
      sides: (json['sides'] as num?)?.toInt() ?? 6,
    );
  }

  static LineShape _parseLine(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return LineShape(
      id: f.id,
      startPoint: Offset(
        (json['startX'] as num).toDouble(),
        (json['startY'] as num).toDouble(),
      ),
      endPoint: Offset(
        (json['endX'] as num).toDouble(),
        (json['endY'] as num).toDouble(),
      ),
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }

  static ArrowShape _parseArrow(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return ArrowShape(
      id: f.id,
      startPoint: Offset(
        (json['startX'] as num).toDouble(),
        (json['startY'] as num).toDouble(),
      ),
      endPoint: Offset(
        (json['endX'] as num).toDouble(),
        (json['endY'] as num).toDouble(),
      ),
      startArrowhead: json['startArrowhead'] != null
          ? ArrowheadStyle.values.firstWhere((a) => a.name == json['startArrowhead'])
          : ArrowheadStyle.none,
      endArrowhead: json['endArrowhead'] != null
          ? ArrowheadStyle.values.firstWhere((a) => a.name == json['endArrowhead'])
          : ArrowheadStyle.triangle,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }

  static FreehandShape _parseFreehand(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    final points = (json['points'] as List).map((p) {
      final pt = p as Map<String, dynamic>;
      return Offset(
        (pt['x'] as num).toDouble(),
        (pt['y'] as num).toDouble(),
      );
    }).toList();
    return FreehandShape(
      id: f.id,
      points: points,
      isClosed: json['isClosed'] as bool? ?? false,
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }

  static TextShape _parseText(Map<String, dynamic> json) {
    final f = _parseBaseFields(json);
    return TextShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      text: json['text'] as String? ?? '',
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20.0,
      fontWeight: FontWeight.values.firstWhere(
        (w) => w.value == (json['fontWeight'] as num?)?.toInt(),
        orElse: () => FontWeight.normal,
      ),
      textAlign: TextAlign.values.firstWhere(
        (a) => a.name == json['textAlign'],
        orElse: () => TextAlign.left,
      ),
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }

  static ImageShape _parseImage(Map<String, dynamic> json) {
    final imageBytesStr = json['imageBytes'] as String?;
    if (imageBytesStr == null || imageBytesStr.isEmpty) {
      throw ArgumentError(
        'Image shape "${json['id']}" is missing required field "imageBytes". '
        'The project file may be corrupted or from an older version.',
      );
    }
    final f = _parseBaseFields(json);
    return ImageShape(
      id: f.id,
      boundingBox: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      rotation: f.rotation,
      imageBytes: base64Decode(imageBytesStr),
      originalSize: Size(
        ((json['originalWidth'] as num?) ?? json['width'] as num).toDouble(),
        ((json['originalHeight'] as num?) ?? json['height'] as num).toDouble(),
      ),
      style: f.style,
      layer: f.layer,
      isLocked: f.isLocked,
      isVisible: f.isVisible,
      createdAt: f.createdAt,
    );
  }
}
