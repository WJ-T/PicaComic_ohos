import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/foundation/app_page_route.dart';

void main() {
  testWidgets('route state survives display inset changes', (tester) async {
    final harnessKey = GlobalKey<_RouteInsetHarnessState>();
    final navigatorKey = GlobalKey<NavigatorState>();
    var initCount = 0;
    var disposeCount = 0;

    await tester.pumpWidget(
      _RouteInsetHarness(
        key: harnessKey,
        navigatorKey: navigatorKey,
      ),
    );

    navigatorKey.currentState!.push(
      AppPageRoute<void>(
        builder: (_) => _LifecycleProbe(
          onInit: () => initCount++,
          onDispose: () => disposeCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(initCount, 1);
    expect(disposeCount, 0);

    harnessKey.currentState!.setInset(72);
    await tester.pump();
    harnessKey.currentState!.setInset(0);
    await tester.pump();

    expect(initCount, 1);
    expect(disposeCount, 0);
  });
}

class _RouteInsetHarness extends StatefulWidget {
  const _RouteInsetHarness({
    required this.navigatorKey,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_RouteInsetHarness> createState() => _RouteInsetHarnessState();
}

class _RouteInsetHarnessState extends State<_RouteInsetHarness> {
  double inset = 0;

  void setInset(double value) {
    setState(() => inset = value);
  }

  @override
  Widget build(BuildContext context) {
    return RouteDisplayInsets(
      padding: EdgeInsets.only(left: inset),
      child: MaterialApp(
        navigatorKey: widget.navigatorKey,
        home: const SizedBox(),
      ),
    );
  }
}

class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe({
    required this.onInit,
    required this.onDispose,
  });

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
