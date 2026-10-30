part of 'main.dart';

class AppTone extends ThemeExtension<AppTone> {
  final int mode;
  final Color background, fill, panelA, panelB, border;
  const AppTone(
    this.mode,
    this.background,
    this.fill,
    this.panelA,
    this.panelB,
    this.border,
  );
  @override
  AppTone copyWith({
    int? mode,
    Color? background,
    Color? fill,
    Color? panelA,
    Color? panelB,
    Color? border,
  }) => AppTone(
    mode ?? this.mode,
    background ?? this.background,
    fill ?? this.fill,
    panelA ?? this.panelA,
    panelB ?? this.panelB,
    border ?? this.border,
  );
  @override
  AppTone lerp(covariant AppTone? other, double t) => other == null
      ? this
      : AppTone(
          t < .5 ? mode : other.mode,
          Color.lerp(background, other.background, t)!,
          Color.lerp(fill, other.fill, t)!,
          Color.lerp(panelA, other.panelA, t)!,
          Color.lerp(panelB, other.panelB, t)!,
          Color.lerp(border, other.border, t)!,
        );
}

AppTone toneOf(BuildContext context) =>
    Theme.of(context).extension<AppTone>() ??
    const AppTone(
      0,
      Color(0xfff3f2ee),
      Color(0xffeae9e4),
      Color(0xe8ffffff),
      Color(0xb9ffffff),
      Color(0xb0ffffff),
    );
Color uiInk(BuildContext context) => Theme.of(context).colorScheme.onSurface;
Color uiMuted(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;
Color uiAccent(BuildContext context) => Theme.of(context).colorScheme.primary;
Color uiOnAccent(BuildContext context) =>
    Theme.of(context).colorScheme.onPrimary;
Color uiFill(BuildContext context) => toneOf(context).fill;

final _themeCache = <int, ThemeData>{};
ThemeData appTheme(int mode) => _themeCache.putIfAbsent(mode, () {
  final dark = mode == 2;
  final bg = dark
      ? const Color(0xff080808)
      : mode == 1
      ? const Color(0xfff4eddf)
      : const Color(0xfff3f2ee);
  final primary = mode == 1
      ? const Color(0xff806b4b)
      : dark
      ? const Color(0xff8ba9dc)
      : const Color(0xff486ba3);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: dark ? const Color(0xff101927) : Colors.white,
        secondary: primary,
        onSecondary: dark ? const Color(0xff101927) : Colors.white,
        surfaceTint: Colors.transparent,
        outlineVariant: (dark ? Colors.white : ink).withValues(alpha: .10),
        surface: bg,
        onSurface: dark ? const Color(0xfffafafa) : ink,
        onSurfaceVariant: dark ? const Color(0xffb3b3b3) : muted,
      );
  final tone = AppTone(
    mode,
    bg,
    dark
        ? const Color(0xff252525)
        : mode == 1
        ? const Color(0xffeae2d1)
        : const Color(0xffeae9e4),
    dark
        ? const Color(0xff181818)
        : mode == 1
        ? const Color(0xe6fff9ec)
        : const Color(0xe8ffffff),
    dark
        ? const Color(0xff181818)
        : mode == 1
        ? const Color(0xc2f3ead8)
        : const Color(0xb9ffffff),
    dark ? const Color(0x00ffffff) : const Color(0xc8ffffff),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    extensions: [tone],
    splashFactory: NoSplash.splashFactory,
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: scheme.onSurface,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: scheme.onSurface,
      ),
      backgroundColor: tone.fill,
      selectedColor: primary.withValues(alpha: .12),
      checkmarkColor: scheme.onSurface,
      side: BorderSide.none,
    ),
    dividerColor: scheme.onSurface.withValues(alpha: .08),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: .08),
      thickness: .7,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    textTheme: (dark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    iconTheme: IconThemeData(color: scheme.onSurface, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: primary,
        foregroundColor: scheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: primary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: bg,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tone.fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
    ),
  );
});

class SheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  final String closeLabel;
  final bool scrollable;
  const SheetShell({
    super.key,
    required this.title,
    required this.child,
    this.closeLabel = 'Close',
    this.scrollable = false,
  });
  @override
  Widget build(BuildContext context) => GlassPanel(
    radius: 30,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sheetGrip(context),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: uiInk(context),
                      letterSpacing: -.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  physics: const ContentScrollPhysics(),
                  child: child,
                ),
              )
            else
              child,
          ],
        ),
      ),
    ),
  );
}

class PillSegments<T> extends StatelessWidget {
  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;
  const PillSegments({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final index = items.keys
        .toList()
        .indexOf(selected)
        .clamp(0, items.length - 1);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: uiFill(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: math.max(40, MediaQuery.textScalerOf(context).scale(12) + 24),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                key: const ValueKey('segment-indicator'),
                alignment: Alignment(
                  items.length == 1 ? 0 : -1 + 2 * index / (items.length - 1),
                  0,
                ),
                duration: motionDuration(context, 200),
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / items.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final e in items.entries)
                  Expanded(
                    child: Semantics(
                      selected: e.key == selected,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: e.key == selected
                            ? null
                            : () => onChanged(e.key),
                        child: Center(
                          child: Text(
                            e.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: uiInk(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeTiles extends StatelessWidget {
  final BibleStore store;
  const ThemeTiles({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (int i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: Semantics(
            selected: store.theme == i,
            button: true,
            child: InkWell(
              key: ValueKey('theme-tile-$i'),
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                store.theme = i;
                store.changed();
                save(context, store);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: uiFill(context).withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: store.theme == i
                        ? uiAccent(context)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 54,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: [
                          Colors.white,
                          const Color(0xfff4eddf),
                          const Color(0xff252525),
                        ][i],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int j = 0; j < 3; j++)
                            Container(
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 6),
                              width: j == 2 ? 24 : 44,
                              color: i == 2
                                  ? const Color(0xff666666)
                                  : const Color(0xffcccccc),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ['Light', 'Paper', 'Dark'][i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: uiInk(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
