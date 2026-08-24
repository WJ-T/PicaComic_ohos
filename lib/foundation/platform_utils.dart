import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformUtils {
  static final bool isOhos = _detectOhos();

  static bool _detectOhos() {
    if (kIsWeb) {
      return false;
    }
    try {
      final os = Platform.operatingSystem.toLowerCase();
      if (os == "ohos" || os == "openharmony") {
        return true;
      }
      final version = Platform.operatingSystemVersion.toLowerCase();
      if (version.contains("openharmony") || version.contains("harmony")) {
        return true;
      }
      final env = Platform.environment;
      if (env.keys.any((key) => key.toLowerCase().contains('openharmony')) ||
          env.values.any((value) =>
              value.toLowerCase().contains('openharmony') ||
              value.toLowerCase().contains('ohos'))) {
        return true;
      }
    } catch (_) {
      // ignore
    }
    return false;
  }
}
