import '../../features/shapes/domain/entities/shape_type.dart';

enum DrawingTool {
  select,
  rectangle,
  ellipse,
  diamond,
  triangle,
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
      case DrawingTool.rectangle:
        return 'R';
      case DrawingTool.ellipse:
        return 'O';
      case DrawingTool.diamond:
        return 'D';
      case DrawingTool.triangle:
        return 'T';
      case DrawingTool.line:
        return 'L';
      case DrawingTool.arrow:
        return 'A';
      case DrawingTool.freehand:
        return 'P';
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
      case DrawingTool.rectangle:
        return 'Rectangle';
      case DrawingTool.ellipse:
        return 'Ellipse';
      case DrawingTool.diamond:
        return 'Diamond';
      case DrawingTool.triangle:
        return 'Triangle';
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
      case DrawingTool.rectangle:
        return ShapeType.rectangle;
      case DrawingTool.ellipse:
        return ShapeType.ellipse;
      case DrawingTool.diamond:
        return ShapeType.diamond;
      case DrawingTool.triangle:
        return ShapeType.triangle;
      case DrawingTool.line:
        return ShapeType.line;
      case DrawingTool.arrow:
        return ShapeType.arrow;
      case DrawingTool.freehand:
        return ShapeType.freehand;
      case DrawingTool.text:
        return ShapeType.text;
      case DrawingTool.image:
        return ShapeType.image;
      case DrawingTool.select:
        throw ArgumentError('Select tool has no shape type');
    }
  }
}
