import 'dart:ui' as ui;

class PictureRecorderManager {
  final Map<String, ui.Picture> _cache = {};
  final Set<String> _dirtyIds = {};
  final Map<String, ui.Image> _imageCache = {};

  ui.Picture? get(String id) {
    if (_dirtyIds.contains(id)) {
      return null;
    }
    return _cache[id];
  }

  void markDirty(String id) {
    _dirtyIds.add(id);
  }

  void markAllDirty() {
    _dirtyIds.addAll(_cache.keys);
  }

  void cache(String id, ui.Picture picture) {
    _cache[id]?.dispose();
    _cache[id] = picture;
    _dirtyIds.remove(id);
  }

  void remove(String id) {
    _cache[id]?.dispose();
    _cache.remove(id);
    _dirtyIds.remove(id);
    _imageCache[id]?.dispose();
    _imageCache.remove(id);
  }

  bool isDirty(String id) => _dirtyIds.contains(id);

  ui.Image? getImage(String id) => _imageCache[id];

  void cacheImage(String id, ui.Image image) {
    _imageCache[id]?.dispose();
    _imageCache[id] = image;
  }

  void clear() {
    for (final picture in _cache.values) {
      picture.dispose();
    }
    _cache.clear();
    _dirtyIds.clear();
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
  }

  void dispose() {
    clear();
  }
}
