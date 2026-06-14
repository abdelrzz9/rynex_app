import '../../features/shapes/domain/entities/shape_type.dart';

enum DrawingTool {
  select,
  hand,
  pencil,
  pen,
  marker,
  brush,
  eraser,
  rectangle,
  roundedRect,
  ellipse,
  diamond,
  triangle,
  polygon,
  line,
  arrow,
  freehand,
  text,
  image,
}

extension DrawingToolKey on DrawingTool {
  String get shortcutLabel {
    switch (this) {
      case DrawingTool.select:
        return 'V';
      case DrawingTool.hand:
        return 'H';
      case DrawingTool.pencil:
        return 'N';
      case DrawingTool.pen:
        return 'P';
      case DrawingTool.marker:
        return 'M';
      case DrawingTool.brush:
        return 'B';
      case DrawingTool.eraser:
        return 'E';
      case DrawingTool.rectangle:
        return 'R';
      case DrawingTool.roundedRect:
        return 'U';
      case DrawingTool.ellipse:
        return 'O';
      case DrawingTool.diamond:
        return 'D';
      case DrawingTool.triangle:
        return 'T';
      case DrawingTool.polygon:
        return 'Y';
      case DrawingTool.line:
        return 'L';
      case DrawingTool.arrow:
        return 'A';
      case DrawingTool.freehand:
        return 'F';
      case DrawingTool.text:
        return 'X';
      case DrawingTool.image:
        return 'I';
    }
  }

  String get label {
    switch (this) {
      case DrawingTool.select:
        return 'Select';
      case DrawingTool.hand:
        return 'Hand';
      case DrawingTool.pencil:
        return 'Pencil';
      case DrawingTool.pen:
        return 'Pen';
      case DrawingTool.marker:
        return 'Marker';
      case DrawingTool.brush:
        return 'Brush';
      case DrawingTool.eraser:
        return 'Eraser';
      case DrawingTool.rectangle:
        return 'Rectangle';
      case DrawingTool.roundedRect:
        return 'Rounded Rect';
      case DrawingTool.ellipse:
        return 'Ellipse';
      case DrawingTool.diamond:
        return 'Diamond';
      case DrawingTool.triangle:
        return 'Triangle';
      case DrawingTool.polygon:
        return 'Polygon';
      case DrawingTool.line:
        return 'Line';
      case DrawingTool.arrow:
        return 'Arrow';
      case DrawingTool.freehand:
        return 'Freehand';
      case DrawingTool.text:
        return 'Text';
      case DrawingTool.image:
        return 'Image';
    }
  }

  ShapeType toShapeType() {
    switch (this) {
      case DrawingTool.pencil:
      case DrawingTool.pen:
      case DrawingTool.marker:
      case DrawingTool.brush:
      case DrawingTool.freehand:
        return ShapeType.freehand;
      case DrawingTool.rectangle:
        return ShapeType.rectangle;
      case DrawingTool.roundedRect:
        return ShapeType.roundedRect;
      case DrawingTool.ellipse:
        return ShapeType.ellipse;
      case DrawingTool.diamond:
        return ShapeType.diamond;
      case DrawingTool.triangle:
        return ShapeType.triangle;
      case DrawingTool.polygon:
        return ShapeType.polygon;
      case DrawingTool.line:
        return ShapeType.line;
      case DrawingTool.arrow:
        return ShapeType.arrow;
      case DrawingTool.text:
        return ShapeType.text;
      case DrawingTool.image:
        return ShapeType.image;
      case DrawingTool.select:
        throw ArgumentError('Select tool has no shape type');
      case DrawingTool.hand:
        throw ArgumentError('Hand tool has no shape type');
      case DrawingTool.eraser:
        throw ArgumentError('Eraser tool has no shape type');
    }
  }

  bool get isDrawingTool {
    switch (this) {
      case DrawingTool.pencil:
      case DrawingTool.pen:
      case DrawingTool.marker:
      case DrawingTool.brush:
      case DrawingTool.freehand:
        return true;
      default:
        return false;
    }
  }

  bool get isNavigationTool {
    switch (this) {
      case DrawingTool.hand:
        return true;
      default:
        return false;
    }
  }

  bool get isShapeTool {
    switch (this) {
      case DrawingTool.rectangle:
      case DrawingTool.roundedRect:
      case DrawingTool.ellipse:
      case DrawingTool.diamond:
      case DrawingTool.triangle:
      case DrawingTool.polygon:
      case DrawingTool.line:
      case DrawingTool.arrow:
        return true;
      default:
        return false;
    }
  }
}
