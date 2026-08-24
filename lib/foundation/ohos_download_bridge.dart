import 'dart:async';

import 'package:flutter/services.dart';

import 'platform_utils.dart';

class OhosDownloadBridge {
  OhosDownloadBridge._();

  static const MethodChannel _channel =
      MethodChannel('pica_comic/ohos_downloads');
  static String? _cachedPath;
  static Future<String?>? _pendingRequest;

  static Future<String?> ensureDownloadDir() {
    if (!PlatformUtils.isOhos) {
      return Future.value(null);
    }
    if (_cachedPath != null) {
      return Future.value(_cachedPath);
    }
    return _pendingRequest ??= _fetchDownloadDir();
  }

  static Future<String?> _fetchDownloadDir() async {
    try {
      final result = await _channel.invokeMethod<String>('ensureDownloadDir');
      if (result != null && result.isNotEmpty) {
        _cachedPath = result;
      }
      return _cachedPath;
    } finally {
      _pendingRequest = null;
    }
  }

  static void invalidateCache() {
    if (!PlatformUtils.isOhos) {
      return;
    }
    _cachedPath = null;
    _pendingRequest = null;
    _channel.invokeMethod<void>('resetCachedPath');
  }
}
