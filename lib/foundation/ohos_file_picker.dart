import 'package:flutter/services.dart';

import 'log.dart';
import 'platform_utils.dart';

class OhosFilePicker {
  static const MethodChannel _channel =
      MethodChannel('pica_comic/ohos_file_picker');

  static Future<String?> pickPicadataFile() async {
    try {
      final path = await _channel.invokeMethod<String>('pickPicadata');
      return path;
    } on MissingPluginException catch (_) {
      // Plugin not registered on this platform.
      if (PlatformUtils.isOhos) {
        LogManager.addLog(LogLevel.warning, 'FilePicker',
            'OHOS plugin channel not available');
      }
      return null;
    } catch (e, s) {
      LogManager.addLog(
          LogLevel.error, 'FilePicker', 'Failed to pick file on OHOS\n$e\n$s');
      return null;
    }
  }

  static Future<String?> pickLocalComicDirectory() async {
    try {
      return await _channel.invokeMethod<String>('pickLocalComicDirectory');
    } on MissingPluginException catch (_) {
      if (PlatformUtils.isOhos) {
        LogManager.addLog(LogLevel.warning, 'FilePicker',
            'OHOS directory picker channel not available');
      }
      return null;
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, 'FilePicker',
          'Failed to pick a comic directory on OHOS\n$e\n$s');
      return null;
    }
  }
}
