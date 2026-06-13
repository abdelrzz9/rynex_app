enum Roughness { none, architect, artist, cartoon }

extension RoughnessExtension on Roughness {
  String get label {
    switch (this) {
      case Roughness.none:
        return 'None';
      case Roughness.architect:
        return 'Architect';
      case Roughness.artist:
        return 'Artist';
      case Roughness.cartoon:
        return 'Cartoon';
    }
  }

  double get jitterAmplitude {
    switch (this) {
      case Roughness.none:
        return 0;
      case Roughness.architect:
        return 0.5;
      case Roughness.artist:
        return 1.5;
      case Roughness.cartoon:
        return 3.0;
    }
  }

  int get iterations {
    switch (this) {
      case Roughness.none:
        return 1;
      case Roughness.architect:
        return 2;
      case Roughness.artist:
        return 2;
      case Roughness.cartoon:
        return 3;
    }
  }
}
