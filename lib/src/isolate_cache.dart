class _CacheEntry<V> {
  final V value;
  final int? expirationTime;

  _CacheEntry({required this.value, this.expirationTime});

  bool get isExpired =>
      expirationTime != null &&
      expirationTime! < DateTime.now().millisecondsSinceEpoch;

  @override
  String toString() {
    return 'CacheEntry(value: $value, expirationTime: $expirationTime)';
  }
}

/// Isolate cache to cache values in isolate
/// Use to cache values in isolate
///
/// [maxEntries] is the maximum number of entries in the cache
/// [defaultTtl] is the default time to live for the entries
class IsolateCache<K, V> {
  static const String tag = 'IsolateCache';

  final int? maxEntries;
  final Duration? defaultTtl;

  IsolateCache({this.maxEntries, this.defaultTtl});

  /// Cache to store the entries
  final _cache = <K, _CacheEntry<V>>{};

  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.value;
  }

  void set(K key, V value, {Duration? ttl}) {
    final entry = _CacheEntry(
      value: value,
      expirationTime: _calculateExpirationTime(ttl ?? defaultTtl),
    );
    _cache[key] = entry;
    evictExpiredEntries();
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void remove(K key) => _cache.remove(key);

  void clear() => _cache.clear();

  /// Get the value from the cache or set it if it is not present
  ///
  /// [key] is the key to get the value from
  /// [valueFactory] is the function to create the value if it is not present
  /// [ttl] is the time to live for the entry
  V getOrSet(K key, V Function() valueFactory, {Duration? ttl}) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      final value = valueFactory();
      set(key, value, ttl: ttl ?? defaultTtl);
      return value;
    }
    return entry.value;
  }

  /// Get the value from the cache or set it if it is not present
  ///
  /// [key] is the key to get the value from
  /// [valueFactory] is the function to create the value if it is not present
  /// [ttl] is the time to live for the entry
  Future<V> getOrSetAsync(
    K key,
    Future<V> Function() valueFactory, {
    Duration? ttl,
  }) async {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      final value = await valueFactory();
      set(key, value, ttl: ttl ?? defaultTtl);
      return value;
    }
    return entry.value;
  }

  int? _calculateExpirationTime(Duration? ttl) {
    if (ttl == null) {
      return null;
    }
    return DateTime.now().add(ttl).millisecondsSinceEpoch;
  }

  void evictExpiredEntries() {
    if (maxEntries == null) {
      return;
    }
    if (_cache.length <= maxEntries!) {
      return;
    }
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  void releaseMemory() {
    if (maxEntries == null) return;
    while (_cache.length > maxEntries!) {
      final entry = _cache.entries.first;
      _cache.remove(entry.key);
    }
  }
}
