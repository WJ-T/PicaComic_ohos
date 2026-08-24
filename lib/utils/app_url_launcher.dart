import 'dart:async';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../foundation/log.dart';
import '../foundation/platform_utils.dart';

class AppUrlLauncher {
  static const _ohosChannel = MethodChannel('pica_comic/ohos_url_launcher');

  static Future<bool> launchExternalUrl(String url) async {
    if (url.isEmpty) {
      return false;
    }
    if (PlatformUtils.isOhos) {
      try {
        await _ohosChannel.invokeMethod('launch', {'url': url});
        return true;
      } catch (e, s) {
        LogManager.addLog(LogLevel.error, 'UrlLauncher',
            'Failed to open $url on OHOS\n$e\n$s');
        return false;
      }
    }
    return launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}
