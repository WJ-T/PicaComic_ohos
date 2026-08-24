import 'package:flutter/services.dart';

import '../foundation/log.dart';
import '../foundation/platform_utils.dart';

class OhosBatteryStatus {
  final int level;
  final bool charging;

  const OhosBatteryStatus({
    required this.level,
    required this.charging,
  });
}

class OhosBatteryBridge {
  static const MethodChannel _channel = MethodChannel('pica_comic/ohos_battery');

  static bool get isSupported => PlatformUtils.isOhos;

  static Future<OhosBatteryStatus?> read() async {
    if (!isSupported) {
      return null;
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getStatus');
      if (result == null) {
        return null;
      }
      final rawLevel = result['level'];
      final rawCharging = result['charging'];
      if (rawLevel is! num) {
        return null;
      }
      final level = rawLevel.toInt();
      if (level < 0 || level > 100) {
        return null;
      }
      return OhosBatteryStatus(
        level: level,
        charging: rawCharging == true,
      );
    } catch (e, s) {
      LogManager.addLog(
        LogLevel.warning,
        'Battery',
        'Failed to read OHOS battery status\n$e\n$s',
      );
      return null;
    }
  }
}
