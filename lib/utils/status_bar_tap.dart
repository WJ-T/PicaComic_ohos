import 'package:flutter/widgets.dart';

/// Handles the system status-bar tap delivered by Flutter.
class StatusBarTapObserver with WidgetsBindingObserver {
  StatusBarTapObserver({required this.onTap});

  final VoidCallback onTap;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  StatusBarTapObserver register() {
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void handleStatusBarTap() {
    if (_lifecycleState == AppLifecycleState.resumed) {
      onTap();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }
}
