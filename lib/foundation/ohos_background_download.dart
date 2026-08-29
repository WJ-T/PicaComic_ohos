import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/foundation/platform_utils.dart';

class OhosBackgroundDownload {
  static const MethodChannel _channel =
      MethodChannel('pica_comic/ohos_background_download');

  static bool _requested = false;

  static Future<void> setActive(bool active) async {
    if (!PlatformUtils.isOhos || _requested == active) {
      return;
    }
    _requested = active;
    try {
      final success =
          await _channel.invokeMethod<bool>(active ? 'start' : 'stop');
      if (success != true) {
        _requested = !active;
        LogManager.addLog(
          LogLevel.error,
          'OhosBackgroundDownload',
          'Failed to ${active ? 'start' : 'stop'} dataTransfer task',
        );
      }
    } catch (error, stackTrace) {
      _requested = !active;
      LogManager.addLog(
        LogLevel.error,
        'OhosBackgroundDownload',
        '$error\n$stackTrace',
      );
    }
  }
}
