import 'dart:ui' as ui;

class PictureRecorderManager {
  final Map<String, ui.Picture> _cache = {};
  final Set<String> _dirtyIds = {};

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
  }

  bool isDirty(String id) => _dirtyIds.contains(id);

  void clear() {
    for (final picture in _cache.values) {
      picture.dispose();
    }
    _cache.clear();
    _dirtyIds.clear();
  }

  void dispose() {
    clear();
  }
}
