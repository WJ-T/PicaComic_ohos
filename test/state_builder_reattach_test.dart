import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/state_controller.dart';

class _TestController extends StateController {
  int value = 0;
}

class _ReattachHarness extends StatefulWidget {
  const _ReattachHarness({required this.tag, super.key});

  final Object tag;

  @override
  State<_ReattachHarness> createState() => _ReattachHarnessState();
}

class _ReattachHarnessState extends State<_ReattachHarness> {
  bool useColumn = false;
  bool showBuilder = true;
  _TestController? currentController;

  void changeParent() {
    setState(() => useColumn = !useColumn);
  }

  void removeBuilder() {
    setState(() => showBuilder = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!showBuilder) return const SizedBox();

    final child = StateBuilder<_TestController>(
      init: _TestController(),
      tag: widget.tag,
      reuseControllerOnReattach: true,
      builder: (controller) {
        currentController = controller;
        return Text('${controller.value}');
      },
    );

    return useColumn ? Column(children: [child]) : Row(children: [child]);
  }
}

class _ScrollReattachHarness extends StatefulWidget {
  const _ScrollReattachHarness({required this.tag, super.key});

  final Object tag;

  @override
  State<_ScrollReattachHarness> createState() => _ScrollReattachHarnessState();
}

class _ScrollReattachHarnessState extends State<_ScrollReattachHarness> {
  bool useColumn = false;
  ComicsPageLogic<int>? currentController;

  void changeParent() {
    setState(() => useColumn = !useColumn);
  }

  @override
  Widget build(BuildContext context) {
    final child = Expanded(
      child: StateBuilder<ComicsPageLogic<int>>(
        init: ComicsPageLogic<int>(),
        tag: widget.tag,
        reuseControllerOnReattach: true,
        builder: (controller) {
          currentController = controller;
          return ListView.builder(
            controller: controller.scrollController,
            itemExtent: 80,
            itemCount: 100,
            itemBuilder: (_, index) => Text('$index'),
          );
        },
      ),
    );

    return useColumn ? Column(children: [child]) : Row(children: [child]);
  }
}

void main() {
  testWidgets('controller survives responsive reparenting', (tester) async {
    final tag = Object();
    final key = GlobalKey<_ReattachHarnessState>();

    await tester.pumpWidget(
      MaterialApp(home: _ReattachHarness(key: key, tag: tag)),
    );
    final originalController = key.currentState!.currentController!;
    originalController.value = 42;

    key.currentState!.changeParent();
    await tester.pump();

    expect(key.currentState!.currentController, same(originalController));
    expect(key.currentState!.currentController!.value, 42);

    key.currentState!.removeBuilder();
    await tester.pump();
    await tester.pump();

    expect(StateController.findOrNull<_TestController>(tag: tag), isNull);
  });

  testWidgets('scroll offset survives responsive reparenting', (tester) async {
    final tag = Object();
    final key = GlobalKey<_ScrollReattachHarnessState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _ScrollReattachHarness(key: key, tag: tag),
        ),
      ),
    );
    final controller = key.currentState!.currentController!.scrollController;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    key.currentState!.changeParent();
    await tester.pump();
    await tester.pump();

    expect(key.currentState!.currentController!.scrollController,
        same(controller));
    expect(
      controller.offset,
      moreOrLessEquals(controller.position.maxScrollExtent, epsilon: 0.5),
    );

    controller.jumpTo(3200);
    await tester.pump();
    key.currentState!.changeParent();
    await tester.pump();
    await tester.pump();

    expect(controller.offset, moreOrLessEquals(3200, epsilon: 0.5));
  });
}
