import 'dart:ui' as ui;

class PictureRecorderManager {
  static const int _maxCacheSize = 200;

  final _cache = <String, ui.Picture>{};
  final Set<String> _dirtyIds = {};
  final _imageCache = <String, ui.Image>{};

  ui.Picture? get(String id) {
    if (_dirtyIds.contains(id)) return null;
    final picture = _cache[id];
    if (picture != null) {
      _cache.remove(id);
      _cache[id] = picture;
    }
    return picture;
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
    _evictIfNeeded();
  }

  void remove(String id) {
    _cache[id]?.dispose();
    _cache.remove(id);
    _dirtyIds.remove(id);
    _imageCache[id]?.dispose();
    _imageCache.remove(id);
  }

  bool isDirty(String id) => _dirtyIds.contains(id);

  ui.Image? getImage(String id) {
    final image = _imageCache[id];
    if (image != null) {
      _imageCache.remove(id);
      _imageCache[id] = image;
    }
    return image;
  }

  void cacheImage(String id, ui.Image image) {
    _imageCache[id]?.dispose();
    _imageCache[id] = image;
    if (_imageCache.length > _maxCacheSize) {
      final eldest = _imageCache.keys.first;
      _imageCache[eldest]?.dispose();
      _imageCache.remove(eldest);
    }
  }

  void _evictIfNeeded() {
    while (_cache.length > _maxCacheSize) {
      final eldest = _cache.keys.first;
      _cache[eldest]?.dispose();
      _cache.remove(eldest);
      _dirtyIds.remove(eldest);
    }
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
