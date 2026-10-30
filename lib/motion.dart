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
    final height = inset + 12;
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      enabled: blur,
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: GlassPanel(
        radius: radius,
        padding: padding,
        translucent: true,
        glassOpacity: blur ? .68 : null,
        child: child,
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
