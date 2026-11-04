part of 'main.dart';

Duration motionDuration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// Fling velocity follows the platform; content never translates past its bounds.
class ContentScrollBehavior extends MaterialScrollBehavior {
  const ContentScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ContentScrollPhysics();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : StretchingOverscrollIndicator(
          axisDirection: details.direction,
          child: child,
        );
}

class ContentScrollPhysics extends ClampingScrollPhysics {
  const ContentScrollPhysics({super.parent});
  @override
  ContentScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      ContentScrollPhysics(parent: buildParent(ancestor));
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) =>
      position.maxScrollExtent > position.minScrollExtent &&
      super.shouldAcceptUserOffset(position);
}

/// Reader-only momentum: continuous friction and spring edges, without scaling glyphs.
class ReaderScrollPhysics extends BouncingScrollPhysics {
  const ReaderScrollPhysics({super.parent});
  @override
  ReaderScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      ReaderScrollPhysics(parent: buildParent(ancestor));
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) =>
      position.maxScrollExtent > position.minScrollExtent &&
      super.shouldAcceptUserOffset(position);
}

class ReaderScrollBehavior extends ContentScrollBehavior {
  const ReaderScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// Tiny, contiguous Gaussian kernel mixed with the unmodified source.
/// Mixing source pixels (not masking filter alpha) guarantees an unchanged
/// final row and avoids clipping a separately blurred layer at the fade edge.
class StatusBarVeil extends StatefulWidget {
  const StatusBarVeil({super.key});
  @override
  State<StatusBarVeil> createState() => _StatusBarVeilState();
}

class _StatusBarVeilState extends State<StatusBarVeil> {
  static Future<FragmentProgram>? program;
  FragmentShader? shader;
  @override
  void initState() {
    super.initState();
    if (ImageFilter.isShaderFilterSupported) {
      (program ??= FragmentProgram.fromAsset('shaders/status_veil.frag'))
          .then((value) {
            if (mounted) setState(() => shader = value.fragmentShader());
          })
          .catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    if (inset <= 0) return const SizedBox.shrink();
    final height = inset + 6;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (shader != null) {
      shader!
        ..setFloat(2, height * dpr)
        ..setFloat(3, .75 * dpr);
      return IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.shader(shader!),
            blendMode: BlendMode.src,
            child: SizedBox(height: height),
          ),
        ),
      );
    }
    // Older renderers use a barely visible continuous tint, never a clipped blur.
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                toneOf(context).background.withValues(alpha: .06),
                toneOf(context).background.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

FragmentProgram? _glassProgram;
Future<void>? _glassWarmup;
Future<void> warmLiquidGlass() => _glassWarmup ??= () async {
  if (!ImageFilter.isShaderFilterSupported) return;
  try {
    _glassProgram = await FragmentProgram.fromAsset(
      'shaders/liquid_glass.frag',
    );
  } catch (_) {
    /* Frosted glass remains available. */
  }
}();

/// Only floating chrome listens to this; scripture never rebuilds for glass motion.
class GlassMotionScope extends InheritedNotifier<ValueNotifier<bool>> {
  const GlassMotionScope({
    super.key,
    required ValueNotifier<bool> motion,
    required super.child,
  }) : super(notifier: motion);
  static bool moving(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GlassMotionScope>()
          ?.notifier
          ?.value ??
      false;
}

class FloatingGlass extends StatefulWidget {
  final Widget child;
  final bool? dark;
  final bool blur;
  final double radius;
  final EdgeInsets padding;
  const FloatingGlass({
    super.key,
    required this.child,
    this.radius = 999,
    this.dark,
    this.blur = false,
    this.padding = EdgeInsets.zero,
  });
  @override
  State<FloatingGlass> createState() => _FloatingGlassState();
}

class _FloatingGlassState extends State<FloatingGlass> {
  FragmentShader? shader;
  @override
  void initState() {
    super.initState();
    if (widget.blur && _glassProgram != null) {
      shader = _glassProgram!.fragmentShader();
    } else if (widget.blur) {
      warmLiquidGlass().then((_) {
        if (mounted && _glassProgram != null) {
          setState(() => shader = _glassProgram!.fragmentShader());
        }
      });
    }
  }

  @override
  void dispose() {
    shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moving = GlassMotionScope.moving(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final lens = widget.blur && shader != null && !moving && !reduced;
    if (lens) {
      shader!
        ..setFloat(2, widget.radius * dpr)
        ..setFloat(3, .035)
        ..setFloat(4, 1.5 * dpr);
    }
    final frostSigma = shader != null && !reduced ? 1.1 : 8.0;
    final surface = toneOf(context).background;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .10 : .025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          enabled: widget.blur,
          filter: lens
              ? ImageFilter.shader(shader!)
              : ImageFilter.blur(sigmaX: frostSigma, sigmaY: frostSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: dark ? .065 : .16),
                    surface.withValues(alpha: widget.blur ? .76 : 1),
                  ),
                  surface.withValues(alpha: widget.blur ? .66 : 1),
                ],
              ),
            ),
            child: CustomPaint(
              foregroundPainter: GlassRimPainter(widget.radius, dark),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassRimPainter extends CustomPainter {
  final double radius;
  final bool dark;
  const GlassRimPainter(this.radius, this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(.65);
    if (bounds.isEmpty) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: dark ? .30 : .9),
            Colors.white.withValues(alpha: .035),
            Colors.white.withValues(alpha: dark ? .13 : .45),
          ],
          stops: const [0, .55, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant GlassRimPainter old) =>
      radius != old.radius || dark != old.dark;
}

class GlassSelectionPill extends StatelessWidget {
  final double lift;
  const GlassSelectionPill({super.key, required this.lift});
  @override
  Widget build(BuildContext context) => Transform.scale(
    scaleX: 1 + lift * .07,
    scaleY: 1 + lift * .045,
    child: DecoratedBox(
      key: const ValueKey('dock-indicator'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: .12 + .12 * lift),
          width: .65,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            uiAccent(context).withValues(alpha: .17 + .04 * lift),
            uiAccent(context).withValues(alpha: .09 + .02 * lift),
          ],
        ),
      ),
    ),
  );
}

Widget sheetGrip(BuildContext context) => Semantics(
  label: 'Dismiss sheet',
  onDismiss: () => Navigator.pop(context),
  child: Center(
    child: SizedBox(
      height: 14,
      width: 72,
      child: Center(
        child: Container(
          width: 34,
          height: 4,
          decoration: BoxDecoration(
            color: uiMuted(context).withValues(alpha: .3),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    ),
  ),
);

/// Paint-only press feedback; the child's layout and tap semantics stay intact.
class PressScale extends StatefulWidget {
  final Widget child;
  const PressScale({super.key, required this.child});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool pressed = false;
  void update(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => update(true),
    onPointerUp: (_) => update(false),
    onPointerCancel: (_) => update(false),
    child: AnimatedScale(
      scale: pressed && !MediaQuery.disableAnimationsOf(context) ? .975 : 1,
      duration: motionDuration(context, pressed ? 100 : 320),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}
