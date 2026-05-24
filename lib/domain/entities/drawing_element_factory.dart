import 'drawing_element.dart';
import 'stroke_element.dart';
import 'rect_element.dart';
import 'line_element.dart';

// ---------------------------------------------------------------------------
// DrawingElementFactory
//
// Central deserialisation entry point. The DB layer and any JSON import path
// ALWAYS call [DrawingElementFactory.fromJson] rather than each subclass
// factory directly. This keeps the type-switching logic in one place and
// makes adding new element types a single-file change.
// ---------------------------------------------------------------------------
abstract final class DrawingElementFactory {
  const DrawingElementFactory._();

  /// Reconstruct the correct [DrawingElement] subclass from a JSON map.
  /// Throws [UnknownElementTypeException] for unrecognised [type] values.
  static DrawingElement fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;

    return switch (typeStr) {
      'stroke' => StrokeElement.fromJson(json),
      'rect' => RectElement.fromJson(json),
      'line' => LineElement.fromJson(json),
      _ => throw UnknownElementTypeException(typeStr),
    };
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class UnknownElementTypeException implements Exception {
  final String? receivedType;
  const UnknownElementTypeException(this.receivedType);

  @override
  String toString() =>
      'UnknownElementTypeException: Cannot deserialise element '
      'with type "$receivedType". '
      'Did you forget to register a new subclass in DrawingElementFactory?';
}
