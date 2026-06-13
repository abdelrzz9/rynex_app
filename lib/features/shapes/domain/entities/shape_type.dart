enum ShapeType {
  rectangle,
  roundedRect,
  ellipse,
  diamond,
  triangle,
  line,
  arrow,
  freehand,
  text,
  image,
}

extension ShapeTypeExtension on ShapeType {
  String get label {
    switch (this) {
      case ShapeType.rectangle:
        return 'Rectangle';
      case ShapeType.roundedRect:
        return 'Rounded Rectangle';
      case ShapeType.ellipse:
        return 'Ellipse';
      case ShapeType.diamond:
        return 'Diamond';
      case ShapeType.triangle:
        return 'Triangle';
      case ShapeType.line:
        return 'Line';
      case ShapeType.arrow:
        return 'Arrow';
      case ShapeType.freehand:
        return 'Freehand';
      case ShapeType.text:
        return 'Text';
      case ShapeType.image:
        return 'Image';
    }
  }
}
