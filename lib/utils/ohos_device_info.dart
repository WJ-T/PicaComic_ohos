import 'package:flutter/services.dart';

import '../foundation/log.dart';
import '../foundation/platform_utils.dart';

class OhosDeviceInfoBridge {
  static const MethodChannel _channel =
      MethodChannel('pica_comic/ohos_device_info');

  static bool _initialized = false;
  static String? _deviceType;

  static Future<void> initialize() async {
    if (!PlatformUtils.isOhos || _initialized) {
      return;
    }
    _initialized = true;
    try {
      final type = await _channel.invokeMethod<String>('getDeviceType');
      _deviceType = type?.toLowerCase();
    } catch (e, s) {
      LogManager.addLog(
        LogLevel.warning,
        'OhosDeviceInfo',
        'Failed to read OHOS device type\n$e\n$s',
      );
    }
  }

  static String? get deviceType => _deviceType;

  static bool get isLargeScreenDevice =>
      _deviceType == 'tablet' || _deviceType == '2in1';

  static bool get shouldLockAppPortrait {
    if (!PlatformUtils.isOhos) {
      return false;
    }
    return !isLargeScreenDevice;
  }
}
