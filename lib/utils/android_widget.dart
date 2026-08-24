import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';

/// Android 桌面小组件桥接服务。
///
/// 与鸿蒙端的 [OhosWidgetService] 对称，通过 `pica_comic/android_widget`
/// 通道把最近阅读快照推送到原生侧，并处理从小组件点击启动 App 的动作。
class AndroidWidgetService {
  AndroidWidgetService._();

  static final AndroidWidgetService instance = AndroidWidgetService._();

  static const MethodChannel _channel = MethodChannel('pica_comic/android_widget');

  bool _initialized = false;
  bool _launchedFromWidget = false;
  String? _pendingAction;
  Future<void> Function(String action)? _handler;

  bool get launchedFromWidget => App.isAndroid && _launchedFromWidget;

  bool get hasPendingAction => App.isAndroid && _pendingAction != null;

  String? get pendingAction => App.isAndroid ? _pendingAction : null;

  Future<void> initialize() async {
    if (!App.isAndroid || _initialized) {
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
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'AndroidWidget',
        'Failed to initialize widget bridge: $error\n$stack',
      );
    }
  }

  void setHandler(Future<void> Function(String action) handler) {
    if (!App.isAndroid) {
      return;
    }
    _handler = handler;
  }

  String? takePendingAction() {
    if (!App.isAndroid) {
      return null;
    }
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  Future<void> dispatchPendingAction() async {
    if (!App.isAndroid) {
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
    if (!App.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('updateHistorySnapshot', {
        'snapshot': jsonEncode(items),
      });
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'AndroidWidget',
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