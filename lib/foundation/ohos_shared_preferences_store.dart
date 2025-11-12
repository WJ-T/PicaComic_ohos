import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Simple file-based implementation for SharedPreferences on OHOS.
class OhosSharedPreferencesStore extends SharedPreferencesStorePlatform {
  OhosSharedPreferencesStore(this.filePath);

  final String filePath;
  final Map<String, Object> _cache = <String, Object>{};
  bool _loaded = false;
  bool _loading = false;

  File get _file => File(filePath);

  Future<void> _ensureLoaded() async {
    if (_loaded || _loading) {
      while (_loading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return;
    }
    _loading = true;
    try {
      if (await _file.exists()) {
        final raw = await _file.readAsString();
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            decoded.forEach((key, value) {
              final normalized = _normalizeValue(value);
              if (normalized != null) {
                _cache[key] = normalized;
              }
            });
          }
        }
      } else {
        await _file.create(recursive: true);
      }
      _loaded = true;
    } finally {
      _loading = false;
    }
  }

  Object? _normalizeValue(Object? value) {
    if (value is bool || value is String) {
      return value;
    }
    if (value is num) {
      return value;
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  Future<void> _persist() async {
    await _file.writeAsString(jsonEncode(_cache));
  }

  Map<String, Object> _filter(PreferencesFilter filter) {
    final Map<String, Object> result = <String, Object>{};
    final String prefix = filter.prefix;
    final Set<String>? allowList = filter.allowList;
    _cache.forEach((key, value) {
      if (prefix.isNotEmpty && !key.startsWith(prefix)) {
        return;
      }
      if (allowList != null && allowList.isNotEmpty && !allowList.contains(key)) {
        return;
      }
      result[key] = value;
    });
    return result;
  }

  @override
  Future<bool> remove(String key) async {
    await _ensureLoaded();
    final bool existed = _cache.remove(key) != null;
    if (existed) {
      await _persist();
    }
    return existed;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await _ensureLoaded();
    if (valueType == 'StringList' && value is List) {
      _cache[key] = List<String>.from(value);
    } else {
      _cache[key] = value;
    }
    await _persist();
    return true;
  }

  @override
  Future<bool> clear() async {
    await _ensureLoaded();
    if (_cache.isEmpty) {
      return true;
    }
    _cache.clear();
    await _persist();
    return true;
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    await _ensureLoaded();
    final PreferencesFilter filter = parameters.filter;
    final List<String> keysToRemove = <String>[];
    _cache.forEach((key, _) {
      if (filter.prefix.isNotEmpty && !key.startsWith(filter.prefix)) {
        return;
      }
      final Set<String>? allowList = filter.allowList;
      if (allowList != null && allowList.isNotEmpty && !allowList.contains(key)) {
        return;
      }
      keysToRemove.add(key);
    });
    if (keysToRemove.isEmpty) {
      return true;
    }
    for (final String key in keysToRemove) {
      _cache.remove(key);
    }
    await _persist();
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    await _ensureLoaded();
    return Map<String, Object>.from(_cache);
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
      GetAllParameters parameters) async {
    await _ensureLoaded();
    return _filter(parameters.filter);
  }

  @override
  Future<bool> clearWithPrefix(String prefix) {
    return clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: prefix)),
    );
  }

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix,
      {Set<String>? allowList}) {
    final PreferencesFilter filter =
        PreferencesFilter(prefix: prefix, allowList: allowList);
    return getAllWithParameters(GetAllParameters(filter: filter));
  }
}
