part of './media_picker.dart';

class AssetCache {
  static final LRUCache<String, Uint8List> _map = LRUCache(maxSize: 128);

  static Uint8List getData(String hashCode) {
    return _map.get(hashCode);
  }

  static void setData(String hashCode, Uint8List list) {
    _map.put(hashCode, list);
  }
}

class LRUCache<K, V> {
  LRUCache({this.maxSize});

  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();
  final int maxSize;

  V get(K key) {
    final V value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > maxSize) {
      final K evictedKey = _map.keys.first;
      _map.remove(evictedKey);
    }
  }

  void remove(K key) {
    _map.remove(key);
  }
}
