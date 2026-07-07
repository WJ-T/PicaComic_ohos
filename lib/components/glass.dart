part of 'components.dart';

bool get enableLiquidGlassUi =>
    appdata.settings.length > 103 && appdata.settings[103] == "1";

class GlassContainerLite extends StatelessWidget {
  const GlassContainerLite({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.useOwnLayer = false,
    this.quality = GlassQuality.minimal,
    this.shape,
    this.settings,
    required this.child,
  });

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool useOwnLayer;
  final GlassQuality quality;
  final dynamic shape;
  final LiquidGlassSettings? settings;
  final Widget child;

  double get _borderRadius {
    final currentShape = shape;
    if (currentShape is LiquidRoundedSuperellipse) {
      return currentShape.borderRadius;
    }
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassSettings = settings;
    final effectiveColor = glassSettings?.glassColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.28));
    final ambientStrength =
        glassSettings?.ambientStrength ?? (isDark ? 0.34 : 0.48);
    final blur = glassSettings?.blur ?? 0;
    final borderRadius = _borderRadius;
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);
    final borderOpacity =
        ((blur == 0 ? 0.14 : 0.12) + ambientStrength * 0.14).clamp(0.14, 0.24);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: borderOpacity)
        : scheme.outlineVariant.withValues(alpha: 0.26);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: content,
        ),
      ),
    );
  }
}

class GlassContainerLiteSettings extends StatelessWidget {
  const GlassContainerLiteSettings({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.useOwnLayer = false,
    this.quality = GlassQuality.minimal,
    this.shape,
    this.settings,
    required this.child,
  });

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool useOwnLayer;
  final GlassQuality quality;
  final dynamic shape;
  final LiquidGlassSettings? settings;
  final Widget child;

  double get _borderRadius {
    final currentShape = shape;
    if (currentShape is LiquidRoundedSuperellipse) {
      return currentShape.borderRadius;
    }
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassSettings = settings;
    final effectiveColor = glassSettings?.glassColor ??
        (isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.24)
            : Colors.white.withValues(alpha: 0.16));
    final ambientStrength =
        glassSettings?.ambientStrength ?? (isDark ? 0.34 : 0.48);
    final blur = glassSettings?.blur ?? 0;
    final borderRadius = _borderRadius;
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);
    final highlightOpacity = (0.08 + ambientStrength * 0.18).clamp(0.08, 0.18);
    final shadowOpacity = (blur == 0 ? 0.08 : 0.05) + (isDark ? 0.16 : 0.03);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: highlightOpacity)
              : Colors.white.withValues(alpha: highlightOpacity + 0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: shadowOpacity.clamp(0.08, 0.22)),
            blurRadius: blur == 0 ? 12 : 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: content,
        ),
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
    this.height,
    this.width,
    this.useOwnLayer = false,
    this.quality = GlassQuality.minimal,
    this.blur,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final bool useOwnLayer;
  final GlassQuality quality;
  final double? blur;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: width,
      height: height,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    Widget surface;
    if (enableLiquidGlassUi) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final effectiveBlur = blur ?? 5;
      final effectiveGlassColor = effectiveBlur == 0
          ? (isDark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.92)
              : scheme.surface.withValues(alpha: 0.95))
          : (isDark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.16));
      surface = GlassContainer(
        width: width,
        height: height,
        useOwnLayer: useOwnLayer,
        quality: quality,
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        settings: LiquidGlassSettings(
          blur: effectiveBlur,
          glassColor: effectiveGlassColor,
          ambientStrength: isDark ? 0.34 : 0.48,
          saturation: 1.14,
          thickness: 18,
        ),
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? content
              : InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: onTap,
                  child: content,
                ),
        ),
      );
    } else {
      surface = Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: surface,
      );
    }
    return surface;
  }
}

/// 参考 haka_comic的毛玻璃。减少卡顿
class GlassSurfaceLite extends StatelessWidget {
  const GlassSurfaceLite({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
    this.height,
    this.width,
    this.blur = 15.0,
    this.active = true,
    this.retainDuration = const Duration(milliseconds: 250),
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final double blur;
  final bool active;
  final Duration retainDuration;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBackgroundColor = backgroundColor ??
        (isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.30)
            : scheme.surface.withValues(alpha: 0.30));

    final content = SizedBox(
      width: width,
      height: height,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    Widget surface = RepaintBoundary(
      child: _DeferredBlur(
        active: active,
        retainDuration: retainDuration,
        blur: blur,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: content,
          ),
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: surface,
      );
    }
    return surface;
  }
}

/// 按需启用 [BackdropFilter] 的包装组件。
///
/// - [active] 为 true 时立即启用模糊；
/// - [active] 从 true 变为 false 后，等待 [retainDuration] 再卸载模糊，
///   避免外层隐藏动画中途模糊突然消失；
/// - [active] 为 false 且冷却期已过时直接返回 [child]，节省背景采样开销。
class _DeferredBlur extends StatefulWidget {
  const _DeferredBlur({
    required this.active,
    required this.child,
    this.blur = 15.0,
    this.borderRadius = BorderRadius.zero,
    this.retainDuration = const Duration(milliseconds: 250),
  });

  final bool active;
  final Widget child;
  final double blur;
  final BorderRadius borderRadius;
  final Duration retainDuration;

  @override
  State<_DeferredBlur> createState() => _DeferredBlurState();
}

class _DeferredBlurState extends State<_DeferredBlur> {
  late bool _blurActive = widget.active;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _DeferredBlur oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _timer?.cancel();
      _timer = null;
      if (!_blurActive) {
        setState(() => _blurActive = true);
      }
    } else if (_blurActive) {
      _timer?.cancel();
      _timer = Timer(widget.retainDuration, () {
        if (!mounted) return;
        setState(() => _blurActive = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_blurActive) return widget.child;
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: widget.borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: widget.blur,
          sigmaY: widget.blur,
          tileMode: ui.TileMode.mirror,
        ),
        child: widget.child,
      ),
    );
  }
}

class GlassChipTag extends StatelessWidget {
  const GlassChipTag({
    super.key,
    required this.label,
    this.tint,
    this.useOwnLayer = true,
    this.blur,
  });

  final String label;
  final Color? tint;
  final bool useOwnLayer;
  final double? blur;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = tint ?? scheme.primary;
    final effectiveBlur = blur ?? 10;

    if (enableLiquidGlassUi) {
      final effectiveGlassColor = effectiveBlur == 0
          ? color.withValues(alpha: isDark ? 0.30 : 0.18)
          : color.withValues(alpha: isDark ? 0.24 : 0.14);
      return GlassContainer(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        useOwnLayer: useOwnLayer,
        quality: GlassQuality.minimal,
        shape: const LiquidRoundedSuperellipse(borderRadius: 14),
        settings: LiquidGlassSettings(
          blur: effectiveBlur,
          glassColor: effectiveGlassColor,
          ambientStrength: 0.42,
          saturation: 1.16,
          thickness: 18,
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class GlassIconActionButton extends StatelessWidget {
  const GlassIconActionButton({
    super.key,
    this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40,
    this.useOwnLayer = false,
    this.blur,
    this.content,
    this.width,
    this.height,
    this.borderRadius = 18,
    this.backgroundColor,
    this.iconColor,
  }) : assert(icon != null || content != null);

  final IconData? icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final bool useOwnLayer;
  final double? blur;
  final Widget? content;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final buttonContent = SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: content ?? Center(child: Icon(icon, color: iconColor)),
    );

    Widget result;
    if (enableLiquidGlassUi) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final effectiveBlur = blur ?? 12;
      final effectiveGlassColor = backgroundColor ??
          (effectiveBlur == 0
              ? (isDark
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.92)
                  : scheme.surface.withValues(alpha: 0.95))
              : (isDark
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.5)));
      result = DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveGlassColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : scheme.outline.withValues(alpha: 0.3),
            width: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: buttonContent,
      );
      result = InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: result,
      );
    } else {
      if (content == null &&
          width == null &&
          height == null &&
          backgroundColor == null &&
          iconColor == null &&
          borderRadius == 18 &&
          size == 40) {
        result = IconButton(
          icon: Icon(icon),
          onPressed: onTap,
        );
      } else {
        result = Material(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: buttonContent,
          ),
        );
      }
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: result);
    }
    return result;
  }
}
