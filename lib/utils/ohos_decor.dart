import 'package:flutter/services.dart';

import '../foundation/log.dart';
import '../foundation/platform_utils.dart';

class OhosDecorBridge {
  static const MethodChannel _channel = MethodChannel('pica_comic/ohos_decor');
  static final Set<Object> _darkDecorOwners = <Object>{};

  static void holdDecorDark(Object owner) {
    if (!PlatformUtils.isOhos) return;
    final wasEmpty = _darkDecorOwners.isEmpty;
    _darkDecorOwners.add(owner);
    if (wasEmpty) {
      _setDecorButtonDark(true);
    }
  }

  static void releaseDecorDark(Object owner) {
    if (!PlatformUtils.isOhos) return;
    if (_darkDecorOwners.remove(owner) && _darkDecorOwners.isEmpty) {
      _setDecorButtonDark(false);
    }
  }

  static void _setDecorButtonDark(bool dark) {
    _channel
        .invokeMethod<bool>('setDecorButtonDark', {'dark': dark}).catchError(
      (Object e, StackTrace s) {
        LogManager.addLog(
          LogLevel.warning,
          'OHOS Decor',
          'Failed to update decor button style\n$e\n$s',
        );
        return null;
      },
    );
  }
}
