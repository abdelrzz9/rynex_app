class CanvasConstants {
  const CanvasConstants._();

  static const double minZoom = 0.1;
  static const double maxZoom = 64.0;
  static const double defaultZoom = 1.0;
  static const double zoomStep = 0.1;
  static const double scrollZoomSpeed = 0.001;
  static const double gridSize = 20.0;
  static const int gridDivisions = 5;
  static const double snapThreshold = 10.0;
  static const double handleSize = 10.0;
  static const double rotationHandleSize = 14.0;
  static const double hitTestThreshold = 5.0;
  static const double cullingPadding = 200.0;
  static const int maxRecentColors = 10;
  static const int maxImageDimension = 4096;
  static const int maxFileSize = 50 * 1024 * 1024;
  static const int maxFreehandPoints = 500;
  static const double freehandSimplifyEpsilon = 2.0;
  static const int historyLimit = 100;
  static const double zoomInFactor = 1.25;
  static const double zoomOutFactor = 0.8;
}
