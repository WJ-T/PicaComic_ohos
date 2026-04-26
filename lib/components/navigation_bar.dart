part of 'components.dart';

class PaneItemEntry {
  String label;

  IconData icon;

  IconData activeIcon;

  PaneItemEntry({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class PaneActionEntry {
  String label;

  IconData icon;

  VoidCallback onTap;

  PaneActionEntry({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class NaviPane extends StatefulWidget {
  const NaviPane({
    required this.paneItems,
    required this.paneActions,
    required this.pageBuilder,
    this.initialPage = 0,
    this.onPageChanged,
    required this.observer,
    required this.navigatorKey,
    super.key,
  });

  final List<PaneItemEntry> paneItems;

  final List<PaneActionEntry> paneActions;

  final Widget Function(int page) pageBuilder;

  final void Function(int index)? onPageChanged;

  final int initialPage;

  final NaviObserver observer;

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<NaviPane> createState() => NaviPaneState();

  static NaviPaneState of(BuildContext context) {
    return context.findAncestorStateOfType<NaviPaneState>()!;
  }
}

typedef NaviItemTapListener = void Function(int);

class NaviPaneState extends State<NaviPane>
    with SingleTickerProviderStateMixin {
  late int _currentPage = widget.initialPage;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    if (value == _currentPage) return;
    _currentPage = value;
    widget.onPageChanged?.call(value);
  }

  void Function()? mainViewUpdateHandler;

  late AnimationController controller;

  final _naviItemTapListeners = <NaviItemTapListener>[];

  void addNaviItemTapListener(NaviItemTapListener listener) {
    _naviItemTapListeners.add(listener);
  }

  void removeNaviItemTapListener(NaviItemTapListener listener) {
    _naviItemTapListeners.remove(listener);
  }

  static const _kBottomBarHeight = 58.0;

  static const _kFoldedSideBarWidth = 72.0;

  static const _kSideBarWidth = 224.0;

  static const _kTopBarHeight = 48.0;

  bool get enableLiquidGlassBottomBar =>
      PlatformUtils.isOhos &&
      appdata.settings.length > 103 &&
      appdata.settings[103] == "1";

  double get bottomBarHeight =>
      _kBottomBarHeight + MediaQuery.of(context).padding.bottom;

  void onNavigatorStateChange() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      if (mounted) setState(() {});
    }
    onRebuild(context);
  }

  void updatePage(int index) {
    for (var listener in _naviItemTapListeners) {
      listener(index);
    }
    if (widget.observer.routes.length > 1) {
      widget.navigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
    if (currentPage == index) {
      return;
    }
    setState(() {
      currentPage = index;
    });
    mainViewUpdateHandler?.call();
  }

  @override
  void initState() {
    controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      lowerBound: 0,
      upperBound: 3,
      vsync: this,
    );
    widget.observer.addListener(onNavigatorStateChange);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    widget.observer.removeListener(onNavigatorStateChange);
    super.dispose();
  }

  double targetFormContext(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    double target = 0;
    if (width > changePoint) {
      target = 2;
    }
    if (width > changePoint2) {
      target = 3;
    }
    return target;
  }

  double? animationTarget;

  void onRebuild(BuildContext context) {
    double target = targetFormContext(context);
    if (controller.value != target || animationTarget != target) {
      if (controller.isAnimating) {
        if (animationTarget == target) {
          return;
        } else {
          controller.stop();
        }
      }
      controller.animateTo(target);
      animationTarget = target;
    }
  }

  String _getTitle() {
    if (widget.observer.routes.length > 1) {
      var route = widget.observer.routes.last;
      if (route is AppPageRoute) {
        if (route.label == 'DownloadPage') return '已下载'.tl;
        if (route.label == 'ImageFavoritesPage') return '图片收藏'.tl;
        if (route.label == 'HistoryPage') return '历史记录'.tl;
        if (route.label == 'ComicSourceSettings') return '漫画源'.tl;
      }
      if (route.settings.name == '/SettingsPage') return '设置'.tl;
    } else if (currentPage == 0) {
      return '我的'.tl;
    }
    return widget.paneItems[currentPage].label;
  }

  @override
  Widget build(BuildContext context) {
    if (App.isFluent) {
      return fluent.NavigationView(
        appBar: fluent.NavigationAppBar(
          title: Text(_getTitle()),
          automaticallyImplyLeading: false,
          leading: widget.observer.routes.length > 1
              ? fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.back),
                  onPressed: () {
                    widget.navigatorKey.currentState!.pop();
                  },
                )
              : null,
          actions: ValueListenableBuilder(
            valueListenable: App.mainAppbarActions,
            builder: (context, value, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: value ?? const SizedBox(),
                  ),
                ),
              );
            },
          ),
        ),
        pane: fluent.NavigationPane(
          selected: currentPage,
          onChanged: (index) {
            updatePage(index);
          },
          displayMode: fluent.PaneDisplayMode.auto,
          items: List.generate(widget.paneItems.length, (index) {
            var entry = widget.paneItems[index];
            return fluent.PaneItem(
              icon: Icon(entry.icon),
              title: Text(entry.label),
              body: const SizedBox.shrink(),
              onTap: () {
                updatePage(index);
              },
            );
          }),
          footerItems: widget.paneActions.map((e) {
            return fluent.PaneItemAction(
              icon: Icon(e.icon),
              title: Text(e.label),
              onTap: e.onTap,
            );
          }).toList(),
        ),
        transitionBuilder: (child, animation) {
          return buildMainView();
        },
      );
    }
    final mq = MediaQuery.of(context);
    final enableFloatingGlassSideDock =
        enableLiquidGlassBottomBar && mq.size.width > changePoint;
    final sideInsets = (App.isMobile && mq.orientation == Orientation.landscape)
        ? EdgeInsets.only(
            left: math.max(mq.viewPadding.left, mq.systemGestureInsets.left),
            right: math.max(mq.viewPadding.right, mq.systemGestureInsets.right),
          )
        : EdgeInsets.zero;
    onRebuild(context);
    bool internalCanPop = widget.observer.routes.length > 1;
    bool rootCanPop = Navigator.of(context).canPop();
    return PopScope(
      canPop: !internalCanPop && !rootCanPop,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        if (internalCanPop) {
          App.mainNavigatorKey!.currentState!.maybePop();
        } else if (rootCanPop) {
          SystemNavigator.pop();
        }
      },
      child: _NaviPopScope(
        action: () {
          if (App.mainNavigatorKey!.currentState!.canPop()) {
            App.mainNavigatorKey!.currentState!.maybePop();
          } else {
            SystemNavigator.pop();
          }
        },
        popGesture: App.isIOS && context.width >= changePoint,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final value = controller.value;
            final showFloatingGlassSideDock = enableFloatingGlassSideDock &&
                widget.observer.routes.length <= 1;
            final floatingDockLeft =
                math.max(MediaQuery.of(context).viewPadding.left, 16.0);
            final floatingDockHiddenOffset = value == 3 ? 72.0 : 56.0;
            final leftOffset =
                _kFoldedSideBarWidth * ((value - 1).clamp(0, 1)) +
                    (_kSideBarWidth - _kFoldedSideBarWidth) *
                        ((value - 2).clamp(0, 1));
            Widget content = Stack(
              children: [
                if (!enableFloatingGlassSideDock)
                  Positioned(
                    left:
                        _kFoldedSideBarWidth * ((value - 2.0).clamp(-1.0, 0.0)),
                    top: 0,
                    bottom: 0,
                    child: buildLeft(
                      useLiquidSelection: false,
                    ),
                  ),
                Positioned.fill(
                  left: enableFloatingGlassSideDock ? 0 : leftOffset,
                  child: buildMainView(),
                ),
                if (enableFloatingGlassSideDock)
                  AnimatedPositioned(
                    duration: _fastAnimationDuration,
                    curve: Curves.easeOutCubic,
                    left: showFloatingGlassSideDock
                        ? floatingDockLeft
                        : floatingDockLeft - floatingDockHiddenOffset,
                    bottom: math.max(
                      MediaQuery.of(context).viewPadding.bottom,
                      16.0,
                    ),
                    child: IgnorePointer(
                      ignoring: !showFloatingGlassSideDock,
                      child: AnimatedOpacity(
                        duration: _fastAnimationDuration,
                        curve: Curves.easeOut,
                        opacity: showFloatingGlassSideDock ? 1 : 0,
                        child: RepaintBoundary(
                          child: buildFloatingLeftDock(showTitle: value == 3),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            if (sideInsets != EdgeInsets.zero) {
              content = Padding(
                padding: sideInsets,
                child: content,
              );
            }
            return content;
          },
        ),
      ),
    );
  }

  Widget buildMainView() {
    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
      child: NavigatorPopHandler(
        onPopWithResult: (result) {
          widget.navigatorKey.currentState?.maybePop(result);
        },
        child: Navigator(
          observers: [widget.observer],
          key: widget.navigatorKey,
          onGenerateRoute: (settings) => AppPageRoute(
            preventRebuild: false,
            builder: (context) {
              return _NaviMainView(state: this);
            },
          ),
        ),
      ),
    );
  }

  Widget buildMainViewContent() {
    return widget.pageBuilder(currentPage);
  }

  Widget buildTop() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.86),
      ),
      height: _kTopBarHeight,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: [
          Text(
            widget.paneItems[currentPage].label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          for (var action in widget.paneActions)
            Tooltip(
              message: action.label,
              child: IconButton(
                icon: Icon(action.icon),
                onPressed: action.onTap,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildBottom() {
    if (enableLiquidGlassBottomBar) {
      final theme = Theme.of(context);
      final primary = theme.colorScheme.primary;
      final isDark = theme.brightness == Brightness.dark;
      final bottomPadding =
          math.max(MediaQuery.of(context).viewPadding.bottom, 10.0);
      final baseGlassColor = isDark
          ? const Color.fromRGBO(28, 28, 32, 0.58)
          : const Color.fromRGBO(255, 255, 255, 0.16);
      final indicatorGlassColor = primary.withValues(
        alpha: isDark ? 0.28 : 0.20,
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 488),
            child: GlassBottomBar(
              quality: GlassQuality.premium,
              selectedIconColor: primary,
              unselectedIconColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.72),
              indicatorColor: primary.withValues(alpha: 0.10),
              magnification: 1.18,
              indicatorSettings: LiquidGlassSettings(
                blur: 0,
                glassColor: indicatorGlassColor,
                saturation: 1.18,
                ambientStrength: 0.48,
                thickness: 28,
              ),
              glassSettings: LiquidGlassSettings(
                blur: 28,
                glassColor: baseGlassColor,
                ambientStrength: isDark ? 0.36 : 0.52,
                saturation: 1.16,
                thickness: 18,
              ),
              verticalPadding: 14,
              barHeight: 56,
              selectedIndex: currentPage,
              onTabSelected: updatePage,
              tabs: widget.paneItems
                  .map(
                    (e) => GlassBottomBarTab(
                      label: e.label,
                      icon: Icon(e.icon),
                      activeIcon: Icon(e.activeIcon),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    }
    return Material(
      textStyle: Theme.of(context).textTheme.labelSmall,
      elevation: 0,
      child: Container(
        height: _kBottomBarHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: List<Widget>.generate(widget.paneItems.length, (index) {
            return Expanded(
              child: _SingleBottomNaviWidget(
                enabled: currentPage == index,
                entry: widget.paneItems[index],
                onTap: () {
                  updatePage(index);
                },
                key: ValueKey(index),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget buildLeft({required bool useLiquidSelection}) {
    final value = controller.value;
    const paddingHorizontal = 12.0;
    return Material(
      child: Container(
        width: _kFoldedSideBarWidth +
            (_kSideBarWidth - _kFoldedSideBarWidth) * ((value - 2).clamp(0, 1)),
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(height: MediaQuery.of(context).padding.top),
            ...List<Widget>.generate(
              widget.paneItems.length,
              (index) => _SideNaviWidget(
                enabled: currentPage == index,
                entry: widget.paneItems[index],
                showTitle: value == 3,
                useLiquidSelection: useLiquidSelection,
                onTap: () {
                  updatePage(index);
                },
                key: ValueKey(index),
              ),
            ),
            const Spacer(),
            ...List<Widget>.generate(
              widget.paneActions.length,
              (index) => _PaneActionWidget(
                entry: widget.paneActions[index],
                showTitle: value == 3,
                key: ValueKey(index + widget.paneItems.length),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildFloatingLeftDock({required bool showTitle}) {
    final actions = <PaneActionEntry>[
      if (widget.paneActions.length == 1)
        PaneActionEntry(
          label: "搜索".tl,
          icon: Icons.search,
          onTap: () {
            final navContext = widget.navigatorKey.currentContext;
            if (navContext == null) {
              return;
            }
            App.to(navContext, () => PreSearchPage());
          },
        ),
      ...widget.paneActions,
    ];

    return _FloatingGlassSideBarDock(
      entries: widget.paneItems,
      actions: actions,
      currentPage: currentPage,
      showTitle: showTitle,
      onSelect: updatePage,
    );
  }
}

class _FloatingGlassSideBarDock extends StatelessWidget {
  const _FloatingGlassSideBarDock({
    required this.entries,
    required this.actions,
    required this.currentPage,
    required this.showTitle,
    required this.onSelect,
  });

  final List<PaneItemEntry> entries;
  final List<PaneActionEntry> actions;
  final int currentPage;
  final bool showTitle;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    const width = 72.0;
    const itemExtent = 48.0;
    const contentVerticalPadding = 20.0;
    final dividerHeight = actions.isEmpty ? 0.0 : 17.0;
    final totalHeight = contentVerticalPadding +
        entries.length * itemExtent +
        dividerHeight +
        actions.length * itemExtent;

    Widget buildIconButton({
      required Widget icon,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final color = selected ? theme.colorScheme.primary : unselectedColor;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GlassButton.custom(
          onTap: onTap,
          width: 48,
          height: 44,
          quality: GlassQuality.premium,
          interactionScale: 1.12,
          glowRadius: selected ? 1.1 : 0.8,
          glowColor: theme.colorScheme.primary.withValues(
            alpha: selected ? 0.18 : 0.08,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 22),
          settings: LiquidGlassSettings(
            blur: 0,
            glassColor: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            saturation: 1.18,
            ambientStrength: selected ? 0.48 : 0.30,
            thickness: selected ? 28 : 14,
          ),
          style:
              selected ? GlassButtonStyle.filled : GlassButtonStyle.transparent,
          child: IconTheme(
            data: IconThemeData(
              color: color,
              size: 22,
            ),
            child: icon,
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: totalHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: GlassSideBar(
            width: width,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            border: Border.all(color: Colors.transparent, width: 0),
            glassSettings: LiquidGlassSettings(
              blur: 28,
              glassColor: isDark
                  ? const Color.fromRGBO(28, 28, 32, 0.58)
                  : const Color.fromRGBO(255, 255, 255, 0.16),
              ambientStrength: isDark ? 0.36 : 0.52,
              saturation: 1.16,
              thickness: 18,
            ),
            quality: GlassQuality.premium,
            header: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(entries.length, (index) {
                    final entry = entries[index];
                    final selected = currentPage == index;
                    return buildIconButton(
                      icon: Icon(selected ? entry.activeIcon : entry.icon),
                      selected: selected,
                      onTap: () => onSelect(index),
                    );
                  }),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                  ...List.generate(actions.length, (index) {
                    final action = actions[index];
                    return buildIconButton(
                      icon: Icon(action.icon),
                      selected: false,
                      onTap: action.onTap,
                    );
                  }),
                ],
              ),
            ),
            footer: null,
            children: const [],
          ),
        ),
      ),
    );
  }
}

class _SideNaviWidget extends StatefulWidget {
  const _SideNaviWidget({
    required this.enabled,
    required this.entry,
    required this.onTap,
    required this.showTitle,
    required this.useLiquidSelection,
    super.key,
  });

  final bool enabled;

  final PaneItemEntry entry;

  final VoidCallback onTap;

  final bool showTitle;

  final bool useLiquidSelection;

  @override
  State<_SideNaviWidget> createState() => _SideNaviWidgetState();
}

class _SideNaviWidgetState extends State<_SideNaviWidget> {
  bool _pressed = false;

  double _itemHeight() {
    if (widget.useLiquidSelection) {
      return widget.showTitle ? 42 : 40;
    }
    return 38;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemHeight = _itemHeight();
    final active = widget.enabled || (widget.useLiquidSelection && _pressed);
    final restingIndicatorColor = colorScheme.primary.withValues(alpha: 0.05);
    final pressedGlassColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.28)
        : colorScheme.primary.withValues(alpha: 0.20);
    final activeColor =
        widget.useLiquidSelection && active ? colorScheme.primary : null;
    final icon = Icon(
      active ? widget.entry.activeIcon : widget.entry.icon,
      color: activeColor,
    );
    final label = Text(
      widget.entry.label,
      style: activeColor == null ? null : TextStyle(color: activeColor),
    );

    Widget child = widget.showTitle
        ? Row(
            children: [icon, const SizedBox(width: 12), label],
          )
        : Align(alignment: Alignment.centerLeft, child: icon);

    if (widget.useLiquidSelection) {
      final scaledChild = AnimatedScale(
        duration: _fastAnimationDuration,
        curve: Curves.easeOutCubic,
        scale: _pressed ? 1.18 : 1.0,
        child: child,
      );

      Widget surface;
      if (_pressed) {
        surface = GlassContainer(
          width: double.infinity,
          height: itemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(borderRadius: 20),
          settings: LiquidGlassSettings(
            blur: 0,
            glassColor: pressedGlassColor,
            saturation: 1.18,
            ambientStrength: 0.48,
            thickness: 28,
          ),
          child: scaledChild,
        );
      } else {
        surface = AnimatedContainer(
          duration: _fastAnimationDuration,
          width: double.infinity,
          height: itemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.enabled ? restingIndicatorColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: scaledChild,
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: surface,
      ).paddingVertical(4);
    }

    Widget surface = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: itemHeight,
      decoration: BoxDecoration(
        color: widget.enabled ? colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.onTap,
      child: surface,
    ).paddingVertical(4);
  }
}

class _PaneActionWidget extends StatelessWidget {
  const _PaneActionWidget({
    required this.entry,
    required this.showTitle,
    super.key,
  });

  final PaneActionEntry entry;

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(entry.icon);
    final itemHeight = showTitle ? 42.0 : 40.0;
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: itemHeight,
        child: showTitle
            ? Row(
                children: [icon, const SizedBox(width: 12), Text(entry.label)],
              )
            : Align(alignment: Alignment.centerLeft, child: icon),
      ),
    ).paddingVertical(4);
  }
}

class _SingleBottomNaviWidget extends StatefulWidget {
  const _SingleBottomNaviWidget({
    required this.enabled,
    required this.entry,
    required this.onTap,
    super.key,
  });

  final bool enabled;

  final PaneItemEntry entry;

  final VoidCallback onTap;

  @override
  State<_SingleBottomNaviWidget> createState() =>
      _SingleBottomNaviWidgetState();
}

class _SingleBottomNaviWidgetState extends State<_SingleBottomNaviWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  bool isHovering = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SingleBottomNaviWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        controller.forward(from: 0);
      } else {
        controller.reverse(from: 1);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      value: widget.enabled ? 1 : 0,
      vsync: this,
      duration: _fastAnimationDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: controller, curve: Curves.ease),
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (details) => setState(() => isHovering = true),
          onExit: (details) => setState(() => isHovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            child: buildContent(),
          ),
        );
      },
    );
  }

  Widget buildContent() {
    final value = controller.value;
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Icon(
      widget.enabled ? widget.entry.activeIcon : widget.entry.icon,
    );
    return Center(
      child: Container(
        width: 64,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          color: isHovering ? colorScheme.surfaceContainer : Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 32 + value * 32,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(32)),
              color: value != 0
                  ? colorScheme.secondaryContainer
                  : Colors.transparent,
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class NaviObserver extends NavigatorObserver implements Listenable {
  var routes = Queue<Route>();

  int get pageCount {
    int count = 0;
    for (var route in routes) {
      if (route is AppPageRoute) {
        count++;
      }
    }
    return count;
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    routes.removeLast();
    notifyListeners();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    routes.addLast(route);
    notifyListeners();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    routes.remove(route);
    notifyListeners();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    routes.remove(oldRoute);
    if (newRoute != null) {
      routes.add(newRoute);
    }
    notifyListeners();
  }

  List<VoidCallback> listeners = [];

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in listeners) {
      listener();
    }
  }
}

class _NaviPopScope extends StatelessWidget {
  const _NaviPopScope({
    required this.child,
    this.popGesture = false,
    required this.action,
  });

  final Widget child;
  final bool popGesture;
  final VoidCallback action;

  static bool panStartAtEdge = false;

  @override
  Widget build(BuildContext context) {
    Widget res = child;
    if (popGesture) {
      res = GestureDetector(
        onPanStart: (details) {
          if (details.globalPosition.dx < 64) {
            panStartAtEdge = true;
          }
        },
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx < 0 ||
              details.velocity.pixelsPerSecond.dx > 0) {
            if (panStartAtEdge) {
              action();
            }
          }
          panStartAtEdge = false;
        },
        child: res,
      );
    }
    return res;
  }
}

class _NaviMainView extends StatefulWidget {
  const _NaviMainView({required this.state});

  final NaviPaneState state;

  @override
  State<_NaviMainView> createState() => _NaviMainViewState();
}

class _NaviMainViewState extends State<_NaviMainView> {
  NaviPaneState get state => widget.state;

  @override
  void initState() {
    state.mainViewUpdateHandler = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (App.isFluent) {
      return state.buildMainViewContent();
    }
    var shouldShowAppBar = state.controller.value < 2;
    var useLiquidGlassBottomBar =
        shouldShowAppBar && state.enableLiquidGlassBottomBar;
    return Scaffold(
      extendBody: useLiquidGlassBottomBar,
      appBar: shouldShowAppBar
          ? AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: NaviPaneState._kTopBarHeight,
              titleSpacing: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(0.86),
              title: Text(
                state.widget.paneItems[state.currentPage].label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                for (var action in state.widget.paneActions)
                  Tooltip(
                    message: action.label,
                    child: IconButton(
                      icon: Icon(action.icon),
                      onPressed: action.onTap,
                    ),
                  ),
              ],
            )
          : null,
      body: AnimatedSwitcher(
        duration: _fastAnimationDuration,
        child: state.buildMainViewContent(),
      ),
      bottomNavigationBar: shouldShowAppBar
          ? (useLiquidGlassBottomBar
              ? state.buildBottom()
              : SafeArea(top: false, bottom: true, child: state.buildBottom()))
          : null,
    );
  }
}
