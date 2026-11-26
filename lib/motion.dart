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

/// Floating surfaces alone sample the content behind them.
class FloatingGlass extends StatelessWidget {
  static final _controlBlur = ImageFilter.blur(sigmaX: 10, sigmaY: 10);
  static final _panelBlur = ImageFilter.blur(sigmaX: 16, sigmaY: 16);
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool _panel;
  const FloatingGlass({
    super.key,
    required this.child,
    this.radius = 999,
    this.padding = EdgeInsets.zero,
  }) : _panel = false;
  const FloatingGlass.panel({
    super.key,
    required this.child,
    this.radius = 30,
    this.padding = EdgeInsets.zero,
  }) : _panel = true;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(radius);
    final tone = toneOf(context);
    final dark = tone.mode == 2;
    final topOpacity = _panel ? .82 : (dark ? .58 : .51);
    final bottomOpacity = _panel ? .67 : (dark ? .40 : .32);
    return ClipRRect(
      borderRadius: corners,
      child: BackdropFilter(
        filter: _panel ? _panelBlur : _controlBlur,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: corners,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tone.panelA.withValues(alpha: topOpacity),
                tone.panelB.withValues(alpha: bottomOpacity),
              ],
            ),
          ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: corners,
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? .18 : .91),
                width: .8,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
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
