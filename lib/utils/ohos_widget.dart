import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/foundation/platform_utils.dart';

class OhosWidgetService {
  OhosWidgetService._();

  static final OhosWidgetService instance = OhosWidgetService._();

  static const MethodChannel _channel = MethodChannel('pica_comic/ohos_widget');

  bool _initialized = false;
  bool _launchedFromWidget = false;
  String? _pendingAction;
  List<Map<String, Object?>>? _pendingHistorySnapshot;
  Future<void> Function(String action)? _handler;
  String? _lastThemePayload;

  bool get launchedFromWidget => PlatformUtils.isOhos && _launchedFromWidget;

  bool get hasPendingAction => PlatformUtils.isOhos && _pendingAction != null;

  String? get pendingAction => PlatformUtils.isOhos ? _pendingAction : null;

  Future<void> initialize() async {
    if (!PlatformUtils.isOhos || _initialized) {
      return;
    }
    _channel.setMethodCallHandler(_handleMethodCall);
    try {
      final action = await _channel.invokeMethod<String?>(
        'getInitialWidgetAction',
      );
      _initialized = true;
      if (action != null && action.isNotEmpty) {
        _pendingAction = action;
        _launchedFromWidget = true;
      }
      await _flushPendingHistorySnapshot();
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosWidget',
        'Failed to initialize widget bridge: $error\n$stack',
      );
    }
  }

  void setHandler(Future<void> Function(String action) handler) {
    if (!PlatformUtils.isOhos) {
      return;
    }
    _handler = handler;
  }

  String? takePendingAction() {
    if (!PlatformUtils.isOhos) {
      return null;
    }
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  Future<void> dispatchPendingAction() async {
    if (!PlatformUtils.isOhos) {
      return;
    }
    final action = _pendingAction;
    if (action == null) {
      return;
    }
    _pendingAction = null;
    await _dispatch(action);
  }

  Future<void> updateHistorySnapshot(
    List<Map<String, Object?>> items,
  ) async {
    if (!PlatformUtils.isOhos) {
      return;
    }
    if (!_initialized) {
      _pendingHistorySnapshot = List<Map<String, Object?>>.from(items);
      return;
    }
    await _sendHistorySnapshot(items);
  }

  Future<void> updateThemeColors({
    required ColorScheme lightScheme,
    required ColorScheme darkScheme,
    required int themeMode,
  }) async {
    if (!PlatformUtils.isOhos || !_initialized) {
      return;
    }
    final colors = <String, Object>{
      ..._palette('light', lightScheme),
      ..._palette('dark', darkScheme),
      'themeMode': themeMode.toString(),
    };
    final payload = jsonEncode(colors);
    if (payload == _lastThemePayload) {
      return;
    }
    _lastThemePayload = payload;
    try {
      await _channel.invokeMethod<void>('updateWidgetTheme', colors);
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosWidget',
        'Failed to update widget theme: $error\n$stack',
      );
    }
  }

  Map<String, String> _palette(String prefix, ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    return <String, String>{
      '${prefix}Background': _toHex(scheme.surface),
      '${prefix}Primary': _toHex(onSurface),
      '${prefix}Secondary': _toHex(Color.alphaBlend(
        onSurface.withValues(alpha: 0.72),
        scheme.surface,
      )),
      '${prefix}Tertiary': _toHex(Color.alphaBlend(
        onSurface.withValues(alpha: 0.56),
        scheme.surface,
      )),
      '${prefix}Divider': _toHex(scheme.surfaceContainerHighest),
    };
  }

  String _toHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<void> _flushPendingHistorySnapshot() async {
    final items = _pendingHistorySnapshot;
    if (items == null) {
      return;
    }
    _pendingHistorySnapshot = null;
    await _sendHistorySnapshot(items);
  }

  Future<void> _sendHistorySnapshot(
    List<Map<String, Object?>> items,
  ) async {
    try {
      await _channel.invokeMethod<void>('updateHistorySnapshot', {
        'snapshot': jsonEncode(items),
      });
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosWidget',
        'Failed to update history widget: $error\n$stack',
      );
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWidgetAction':
        final action = call.arguments;
        if (action is String && action.isNotEmpty) {
          _launchedFromWidget = true;
          await _dispatch(action);
        }
        break;
    }
  }

  Future<void> _dispatch(String action) async {
    final handler = _handler;
    if (handler == null) {
      _pendingAction = action;
      return;
    }
    await handler(action);
  }
}

String readOhosWidgetActionName(String payload) {
  if (payload == 'open_history') {
    return payload;
  }
  try {
    final data = jsonDecode(payload);
    if (data is Map) {
      return data['action']?.toString() ?? '';
    }
  } catch (_) {}
  return '';
}

OhosWidgetReaderParams? readOhosWidgetReaderParams(String payload) {
  try {
    final data = jsonDecode(payload);
    if (data is! Map) {
      return null;
    }
    final target = data['target']?.toString() ?? '';
    final type = int.tryParse(data['type']?.toString() ?? '');
    if (target.isEmpty || type == null) {
      return null;
    }
    return OhosWidgetReaderParams(
      type: type,
      target: target,
      ep: int.tryParse(data['ep']?.toString() ?? '') ?? 0,
      page: int.tryParse(data['page']?.toString() ?? '') ?? 0,
    );
  } catch (_) {
    return null;
  }
}

class OhosWidgetReaderParams {
  const OhosWidgetReaderParams({
    required this.type,
    required this.target,
    required this.ep,
    required this.page,
  });

  final int type;
  final String target;
  final int ep;
  final int page;
}
