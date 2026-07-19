import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';

const bool kEnableOhosContinuation = true;

class OhosContinuationService {
  OhosContinuationService._();

  static final OhosContinuationService instance = OhosContinuationService._();

  static const MethodChannel _channel =
      MethodChannel('pica_comic/ohos_continuation');

  bool _initialized = false;
  bool _startupPayloadLoaded = false;
  bool _launchedFromContinuation = false;
  Map<String, dynamic>? _pendingPayload;
  Map<String, dynamic>? _startupPayload;
  Map<String, dynamic>? _currentReaderPayload;
  Future<void> Function(Map<String, dynamic>)? _handler;

  Future<void> preloadInitialPayload() async {
    if (!kEnableOhosContinuation) {
      return;
    }
    if (_startupPayloadLoaded) {
      return;
    }
    _startupPayloadLoaded = true;
    try {
      final rawPayload = await _channel.invokeMethod<Object?>(
        'getInitialContinuation',
      );
      final payload = _decodePayload(rawPayload);
      if (payload != null) {
        _startupPayload = payload;
        _launchedFromContinuation = true;
      }
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosContinuation',
        'Failed to preload continuation payload: $error\n$stack',
      );
    }
  }

  Future<void> initialize() async {
    if (!kEnableOhosContinuation) {
      return;
    }
    if (_initialized) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    if (_startupPayload != null) {
      _pendingPayload = _startupPayload;
      _startupPayload = null;
      return;
    }
    if (!_startupPayloadLoaded) {
      try {
        final rawPayload = await _channel.invokeMethod<Object?>(
          'getInitialContinuation',
        );
        final payload = _decodePayload(rawPayload);
        if (payload != null) {
          _pendingPayload = payload;
          _launchedFromContinuation = true;
        }
      } catch (error, stack) {
        LogManager.addLog(
          LogLevel.error,
          'OhosContinuation',
          'Failed to initialize continuation bridge: $error\n$stack',
        );
      }
    }
  }

  void setHandler(Future<void> Function(Map<String, dynamic>) handler) {
    if (!kEnableOhosContinuation) {
      return;
    }
    _handler = handler;
  }

  bool get hasPendingPayload =>
      kEnableOhosContinuation && _pendingPayload != null;

  bool get launchedFromContinuation =>
      kEnableOhosContinuation && _launchedFromContinuation;

  bool get hasStartupPayload =>
      kEnableOhosContinuation && _startupPayload != null;

  Map<String, dynamic>? takeStartupPayload() {
    if (!kEnableOhosContinuation) {
      return null;
    }
    final payload = _startupPayload;
    _startupPayload = null;
    return payload;
  }

  Future<void> dispatchPendingPayload() async {
    if (!kEnableOhosContinuation) {
      return;
    }
    final payload = _pendingPayload;
    if (payload == null) {
      return;
    }
    _pendingPayload = null;
    await _dispatch(payload);
  }

  Future<void> publishReaderState(Map<String, dynamic> payload) async {
    if (!kEnableOhosContinuation) {
      return;
    }
    _currentReaderPayload = Map<String, dynamic>.from(payload);
    try {
      await _channel.invokeMethod<void>('setReaderState', {
        'payload': payload,
      });
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosContinuation',
        'Failed to publish reader state: $error\n$stack',
      );
    }
  }

  Future<void> clearReaderState() async {
    if (!kEnableOhosContinuation) {
      return;
    }
    _currentReaderPayload = null;
    try {
      await _channel.invokeMethod<void>('clearReaderState');
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosContinuation',
        'Failed to clear reader state: $error\n$stack',
      );
    }
  }

  Future<void> _dispatch(Map<String, dynamic> payload) async {
    final handler = _handler;
    if (handler == null) {
      _pendingPayload = payload;
      return;
    }
    await handler(payload);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getReaderState':
        final payload = _currentReaderPayload;
        return payload == null ? null : jsonEncode(payload);
      case 'onContinuation':
        final payload = _decodePayload(call.arguments);
        if (payload != null) {
          await _dispatch(payload);
        }
    }
  }

  Map<String, dynamic>? _decodePayload(Object? rawPayload) {
    if (rawPayload == null) {
      return null;
    }
    try {
      if (rawPayload is String) {
        if (rawPayload.isEmpty) {
          return null;
        }
        return Map<String, dynamic>.from(
          jsonDecode(rawPayload) as Map,
        );
      }
      if (rawPayload is Map) {
        return Map<String, dynamic>.from(rawPayload);
      }
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.error,
        'OhosContinuation',
        'Failed to decode continuation payload: $error\n$stack',
      );
    }
    return null;
  }
}
