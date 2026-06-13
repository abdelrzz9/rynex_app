import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/features/shapes/domain/entities/arrow_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/diamond_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/ellipse_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/freehand_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/line_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/rectangle_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/shape_entity.dart';
import 'package:rynex_app/features/shapes/domain/entities/shape_factory.dart';
import 'package:rynex_app/features/shapes/domain/entities/shape_type.dart';
import 'package:rynex_app/features/shapes/domain/entities/text_shape.dart';
import 'package:rynex_app/features/shapes/domain/entities/triangle_shape.dart';

void main() {
  group('ShapeEntity base', () {
    test('rotatedBoundingBox equals boundingBox when rotation is 0', () {
      final rect = RectangleShape(
        id: 'test',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 50),
      );
      expect(rect.rotatedBoundingBox, rect.boundingBox);
    });

    test('hitTest returns true for point inside', () {
      final rect = RectangleShape(
        id: 'test',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 50),
      );
      expect(rect.hitTest(const Offset(50, 25)), true);
      expect(rect.hitTest(const Offset(-1, 0)), false);
    });

    test('center returns bounding box center', () {
      final rect = RectangleShape(
        id: 'test',
        boundingBox: const Rect.fromLTWH(10, 10, 100, 50),
      );
      expect(rect.center, const Offset(60, 35));
    });
  });

  group('RectangleShape', () {
    test('toJson/fromJson roundtrip', () {
      final original = RectangleShape(
        id: 'r1',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 50),
        style: const ShapeStyle(strokeColor: Colors.red, strokeWidth: 3),
      );
      final json = original.toJson();
      final restored = ShapeFactory.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.boundingBox, original.boundingBox);
      expect(restored.type, original.type);
    });

    test('copyWith updates boundingBox', () {
      final original = RectangleShape(
        id: 'r1',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 50),
      );
      final updated = original.copyWith(boundingBox: const Rect.fromLTWH(10, 10, 80, 40));
      expect(updated.boundingBox, const Rect.fromLTWH(10, 10, 80, 40));
    });
  });

  group('EllipseShape', () {
    test('toJson/fromJson roundtrip', () {
      final original = EllipseShape(
        id: 'e1',
        boundingBox: const Rect.fromLTWH(0, 0, 80, 60),
      );
      final json = original.toJson();
      final restored = ShapeFactory.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.type, ShapeType.ellipse);
    });
  });

  group('LineShape', () {
    test('hitTest returns true near line', () {
      final line = LineShape(
        id: 'l1',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(100, 0),
      );
      expect(line.hitTest(const Offset(50, 2)), true);
      expect(line.hitTest(const Offset(50, 20)), false);
    });

    test('toJson/fromJson roundtrip', () {
      final original = LineShape(
        id: 'l1',
        startPoint: const Offset(10, 20),
        endPoint: const Offset(100, 200),
      );
      final json = original.toJson();
      final restored = ShapeFactory.fromJson(json);
      expect(restored.id, original.id);
      if (restored is LineShape) {
        expect(restored.startPoint, original.startPoint);
        expect(restored.endPoint, original.endPoint);
      } else {
        fail('restored is not LineShape');
      }
    });
  });

  group('ArrowShape', () {
    test('creates with default arrowhead', () {
      final arrow = ArrowShape(
        id: 'a1',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(100, 0),
      );
      expect(arrow.startArrowhead, ArrowheadStyle.none);
      expect(arrow.endArrowhead, ArrowheadStyle.triangle);
      expect(arrow.length, 100);
      expect(arrow.angle, 0);
    });

    test('toJson/fromJson roundtrip', () {
      final original = ArrowShape(
        id: 'a1',
        startPoint: const Offset(0, 0),
        endPoint: const Offset(100, 0),
        startArrowhead: ArrowheadStyle.circle,
        endArrowhead: ArrowheadStyle.diamond,
      );
      final json = original.toJson();
      final restored = ShapeFactory.fromJson(json);
      if (restored is ArrowShape) {
        expect(restored.startArrowhead, ArrowheadStyle.circle);
        expect(restored.endArrowhead, ArrowheadStyle.diamond);
      } else {
        fail('restored is not ArrowShape');
      }
    });
  });

  group('DiamondShape', () {
    test('toJson/fromJson roundtrip', () {
      final original = DiamondShape(
        id: 'd1',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 80),
      );
      final json = original.toJson();
      final restored = ShapeFactory.fromJson(json);
      expect(restored.type, ShapeType.diamond);
    });
  });

  group('TriangleShape', () {
    test('vertices computed from bounding box', () {
      final tri = TriangleShape(
        id: 't1',
        boundingBox: const Rect.fromLTWH(0, 0, 100, 80),
      );
      final verts = tri.vertices;
      expect(verts.length, 3);
      expect(verts[0], const Offset(50, 0));
      expect(verts[1], const Offset(0, 80));
      expect(verts[2], const Offset(100, 80));
    });
  });

  group('TextShape', () {
    test('copyWith updates text', () {
      final text = TextShape(
        id: 'txt1',
        boundingBox: const Rect.fromLTWH(0, 0, 200, 40),
        text: 'Hello',
      );
      final updated = text.copyWith(text: 'World');
      expect(updated.text, 'World');
    });

    test('toJson/fromJson roundtrip', () {
      final original = TextShape(
        id: 'txt1',
        boundingBox: const Rect.fromLTWH(10, 10, 200, 40),
        text: 'Hello World',
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );
      final json = original.toJson();
      final restored = ShapeFactory.fromJson(json);
      if (restored is TextShape) {
        expect(restored.text, 'Hello World');
        expect(restored.fontSize, 24);
        expect(restored.fontWeight, FontWeight.bold);
      } else {
        fail('restored is not TextShape');
      }
    });
  });

  group('FreehandShape', () {
    test('simplifies points on creation', () {
      final fh = FreehandShape(
        id: 'fh1',
        points: [const Offset(0, 0), const Offset(1, 1), const Offset(2, 2), const Offset(100, 0)],
      );
      expect(fh.points.length, greaterThanOrEqualTo(2));
      expect(fh.isClosed, false);
    });
  });

  group('ShapeFactory', () {
    test('creates all known shape types', () {
      for (final type in ShapeType.values) {
        final json = <String, dynamic>{
          'id': 'test',
          'type': type.name,
          'x': 0.0,
          'y': 0.0,
          'width': 100.0,
          'height': 50.0,
          'strokeColor': 4278190080,
          'strokeWidth': 2.0,
          'strokeStyle': 'solid',
          'fillColor': 0,
          'fillStyle': 'none',
          'roughness': 'none',
          'opacity': 1.0,
          'layerOrder': 0,
          'isLocked': false,
          'isVisible': true,
          'createdAt': DateTime.now().toIso8601String(),
        };
        if (type == ShapeType.line || type == ShapeType.arrow) {
          json['startX'] = 0.0;
          json['startY'] = 0.0;
          json['endX'] = 100.0;
          json['endY'] = 50.0;
        }
        if (type == ShapeType.freehand) {
          json['points'] = <Map<String, dynamic>>[
            {'x': 0.0, 'y': 0.0},
            {'x': 10.0, 'y': 10.0},
          ];
        }
        if (type == ShapeType.text) {
          json['text'] = 'Test';
        }
        if (type == ShapeType.image) {
          json['imageBytes'] = <int>[];
          json['originalWidth'] = 100.0;
          json['originalHeight'] = 50.0;
        }
        if (type == ShapeType.roundedRect) {
          json['topLeftRadius'] = 0.0;
          json['topRightRadius'] = 0.0;
          json['bottomRightRadius'] = 0.0;
          json['bottomLeftRadius'] = 0.0;
        }
        if (type == ShapeType.arrow) {
          json['startArrowhead'] = 'none';
          json['endArrowhead'] = 'triangle';
        }
        expect(ShapeFactory.fromJson(json).type, type);
      }
    });

    test('returns RectangleShape for unknown type', () {
      final json = <String, dynamic>{
        'id': 'test',
        'type': 'unknown_type',
        'x': 0.0,
        'y': 0.0,
        'width': 100.0,
        'height': 50.0,
        'strokeColor': 4278190080,
        'strokeWidth': 2.0,
        'strokeStyle': 'solid',
        'fillColor': 0,
        'fillStyle': 'none',
        'roughness': 'none',
        'opacity': 1.0,
        'layerOrder': 0,
        'isLocked': false,
        'isVisible': true,
        'createdAt': DateTime.now().toIso8601String(),
      };
      final shape = ShapeFactory.fromJson(json);
      expect(shape, isA<RectangleShape>());
    });
  });
}
