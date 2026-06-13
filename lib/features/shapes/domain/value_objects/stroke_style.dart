enum StrokeStyle { solid, dashed, dotted }

extension StrokeStyleExtension on StrokeStyle {
  String get label {
    switch (this) {
      case StrokeStyle.solid:
        return 'Solid';
      case StrokeStyle.dashed:
        return 'Dashed';
      case StrokeStyle.dotted:
        return 'Dotted';
    }
  }
}
