enum FillStyle { solid, crossHatch, diagonalHatch, zigzag, dotted, none }

extension FillStyleExtension on FillStyle {
  String get label {
    switch (this) {
      case FillStyle.solid:
        return 'Solid';
      case FillStyle.crossHatch:
        return 'Cross Hatch';
      case FillStyle.diagonalHatch:
        return 'Diagonal Hatch';
      case FillStyle.zigzag:
        return 'Zigzag';
      case FillStyle.dotted:
        return 'Dotted';
      case FillStyle.none:
        return 'None';
    }
  }
}
