part of 'main.dart';

class Reader extends StatefulWidget {
  final BibleStore store;
  const Reader({super.key, required this.store});
  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> with WidgetsBindingObserver {
  BibleStore get s => widget.store;
  final scroll = ScrollController();
  Map<String, GlobalKey> keys = {};
  final selected = <String>{};
  String chapterKey = '';
  String? anchor;
  final chromeVisible = ValueNotifier<bool>(true);
  bool get controls => chromeVisible.value;
  set controls(bool value) => chromeVisible.value = value;
  bool restoring = false, rangeMode = false;
  double scrollIntent = 0;
  bool? awake;
  Timer? debounce;
  Future<void>? autoScrollMotion;
  bool get autoScrolling => autoScrollMotion != null;
  Color get paper => Theme.of(context).colorScheme.surface;
  Color get textColor => toneOf(context).mode == 2
      ? const Color(0xffdededb)
      : toneOf(context).mode == 1
      ? const Color(0xff3c3933)
      : const Color(0xff292b30);
  List<Verse> get selection =>
      s.current.where((v) => selected.contains(v.id)).toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scroll.addListener(track);
    s.addListener(syncAwake);
    syncAwake();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      save(context, s);
    });
  }

  Future<void> setAwake(bool enabled) async {
    try {
      await BibleStore.storage.invokeMethod<void>('awake', enabled);
    } on PlatformException catch (_) {
      /* Native flag unavailable on this host. */
    } on MissingPluginException catch (_) {
      /* Allows non-Android previews. */
    }
  }

  void syncAwake() {
    final enabled = s.keepAwake || autoScrolling;
    if (awake != enabled) {
      awake = enabled;
      unawaited(setAwake(enabled));
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    s.removeListener(syncAwake);
    unawaited(setAwake(false));
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    chromeVisible.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (!pauseAutoScroll()) save(context, s);
    }
  }

  void track() {
    if (restoring || selected.isNotEmpty) return;
    if (autoScrolling && (debounce?.isActive ?? false)) return;
    debounce?.cancel();
    debounce = Timer(
      Duration(milliseconds: autoScrolling ? 1000 : 350),
      captureReadingPosition,
    );
  }

  void captureReadingPosition() {
    if (!mounted || restoring || selected.isNotEmpty) return;
    final edge = MediaQuery.paddingOf(context).top + (controls ? 68 : 10);
    for (final e in keys.entries) {
      final box = e.value.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          box.localToGlobal(Offset.zero).dy >= edge) {
        if (s.verse != e.key) {
          s.verse = e.key;
          save(context, s);
        }
        break;
      }
    }
  }

  bool pauseAutoScroll({bool interrupt = true}) {
    if (!autoScrolling) return false;
    setState(() => autoScrollMotion = null);
    if (interrupt && scroll.hasClients) scroll.jumpTo(scroll.offset);
    debounce?.cancel();
    captureReadingPosition();
    syncAwake();
    return true;
  }

  Future<void> startAutoScroll() async {
    if (!scroll.hasClients || scroll.position.extentAfter <= 1) return;
    debounce?.cancel();
    final target = scroll.position.maxScrollExtent;
    final seconds = (target - scroll.offset) / (24 * s.autoScrollSpeed);
    final motion = scroll.animateTo(
      target,
      duration: Duration(milliseconds: (seconds * 1000).ceil()),
      curve: Curves.linear,
    );
    setState(() {
      autoScrollMotion = motion;
      controls = true;
    });
    syncAwake();
    await motion;
    // Dragging takes over the ScrollPosition and completes its animation.
    if (mounted && identical(autoScrollMotion, motion)) {
      pauseAutoScroll(interrupt: false);
    }
  }

  Future<void> showAutoScroll() async {
    if (pauseAutoScroll()) return;
    var speed = s.autoScrollSpeed;
    final canStart = scroll.hasClients && scroll.position.extentAfter > 1;
    final start = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        top: false,
        child: GlassPanel(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: StatefulBuilder(
              builder: (context, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sheetGrip(sheet),
                  const SizedBox(height: 14),
                  heading('Auto-scroll', size: 22),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Text('Scroll speed')),
                      Text('${speed % 1 == 0 ? speed.toInt() : speed}×'),
                    ],
                  ),
                  Slider(
                    value: speed,
                    min: BibleStore.minAutoScrollSpeed,
                    max: BibleStore.maxAutoScrollSpeed,
                    divisions: 10,
                    semanticFormatterCallback: (value) => '$value times',
                    onChanged: (value) => setSheetState(() => speed = value),
                  ),
                  if (!canStart)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('You’re at the end of this chapter.'),
                    ),
                  FilledButton.icon(
                    onPressed: canStart
                        ? () => Navigator.pop(sheet, true)
                        : null,
                    icon: const AppIcon(LucideIcons.play, size: 15),
                    label: const Text('Start auto-scroll'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (speed != s.autoScrollSpeed) {
      s.autoScrollSpeed = speed;
      unawaited(save(context, s));
    }
    if (start == true) unawaited(startAutoScroll());
  }

  void prepare() {
    final id = '${s.book}.${s.chapter}';
    if (chapterKey == id) return;
    chapterKey = id;
    selected.clear();
    anchor = null;
    rangeMode = false;
    restoring = true;
    debounce?.cancel();
    keys = {for (final v in s.current) v.number: GlobalKey()};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scroll.hasClients) return;
      if (s.verse == s.current.first.number) {
        scroll.jumpTo(0);
      } else {
        final box = keys[s.verse]?.currentContext?.findRenderObject();
        if (box is RenderBox) {
          final y =
              scroll.offset +
              box.localToGlobal(Offset.zero).dy -
              MediaQuery.paddingOf(context).top -
              78;
          scroll.jumpTo(y.clamp(0, scroll.position.maxScrollExtent));
        }
      }
      restoring = false;
    });
  }

  void clearSelection() {
    setState(() {
      selected.clear();
      rangeMode = false;
      anchor = null;
      controls = true;
    });
    track();
  }

  void select(Verse v, {bool extend = false}) {
    pauseAutoScroll();
    debounce?.cancel();
    if (s.haptics) HapticFeedback.selectionClick();
    final previousSelection = Set.of(selected);
    setState(() {
      controls = true;
      if ((extend || rangeMode) && anchor != null) {
        final a = s.current.indexWhere((x) => x.id == anchor);
        final b = s.current.indexOf(v);
        if (a >= 0) {
          for (int i = (a < b ? a : b); i <= (a > b ? a : b); i++) {
            selected.add(s.current[i].id);
          }
        }
        rangeMode = false;
      } else {
        if (!selected.add(v.id)) {
          selected.remove(v.id);
        }
        anchor = v.id;
      }
      if (selected.isEmpty) {
        anchor = null;
        rangeMode = false;
      }
    });
    final added = selected.difference(previousSelection);
    if (added.isNotEmpty) {
      s.recordVerseSelection(added);
      save(context, s);
    }
  }

  void move(int delta) {
    if (selected.isNotEmpty) return;
    pauseAutoScroll();
    debounce?.cancel();
    if (s.adjacent(delta)) {
      save(context, s);
      setState(() => controls = true);
    }
  }

  void passage() {
    pauseAutoScroll();
    picker(
      context,
      s,
      onGo: () {
        if (mounted) {
          setState(() {
            chapterKey = '';
            controls = true;
          });
        }
      },
    );
  }

  Widget tool(
    IconData icon,
    String label,
    VoidCallback? tap, {
    bool active = false,
  }) => SizedBox.square(
    dimension: 44,
    child: IconButton(
      tooltip: label,
      onPressed: tap,
      padding: EdgeInsets.zero,
      icon: AppIcon(
        icon,
        size: 20,
        color: tap == null
            ? textColor.withValues(alpha: .25)
            : active
            ? uiAccent(context)
            : textColor,
      ),
    ),
  );
  Widget chapterContent({required bool interactive}) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, top + 100, 26, bottom + 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '${malayalamBooks[s.book]} ${s.chapter}',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 22,
                height: 1.6,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 46),
          for (final v in s.current) verseBody(v, interactive),
        ],
      ),
    );
  }

  Widget verseBody(Verse v, bool interactive) {
    final chosen = selected.contains(v.id),
        marked = s.highlights.contains(v.id);
    final hasNote =
        s.notes.containsKey(v.id) ||
        s.noteRanges.values.any((ids) => ids.contains(v.id));
    final style = TextStyle(
      fontFamily: s.fontFamily,
      fontSize: s.fontSize,
      height: s.lineHeight,
      leadingDistribution: TextLeadingDistribution.even,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: textColor,
    );
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                children: [
                  if (s.numbers)
                    Text(
                      v.number,
                      key: ValueKey('verse-number-${v.id}'),
                      style: TextStyle(fontSize: 10, color: uiMuted(context)),
                    ),
                  if (chosen)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: AppIcon(
                        LucideIcons.circleCheck,
                        size: 13,
                        color: textColor,
                      ),
                    )
                  else if (s.bookmarks.contains(v.id) || hasNote)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: AppIcon(
                        hasNote
                            ? LucideIcons.fileText
                            : LucideIcons.bookmarkCheck,
                        size: 11,
                        color: uiMuted(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: MarkedScripture(
              text: v.text,
              style: style,
              selected: chosen,
              color: chosen
                  ? textColor
                  : marked
                  ? highlightPalette[s.highlightColors[v.id] ?? 3]
                  : null,
            ),
          ),
        ],
      ),
    );
    if (!interactive) return content;
    return GestureDetector(
      key: keys[v.number],
      behavior: HitTestBehavior.opaque,
      onTap: () => select(v),
      onLongPress: () => select(v, extend: true),
      child: RepaintBoundary(child: content),
    );
  }

  Widget chrome(String name, bool visible, Offset hidden, Widget child) =>
      IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : hidden,
            duration: motionDuration(context, 420),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              key: ValueKey(name),
              opacity: visible ? 1 : 0,
              duration: motionDuration(context, 360),
              child: child,
            ),
          ),
        ),
      );
  Widget readerIcon(IconData icon, String label, VoidCallback? tap) =>
      SizedBox.square(
        dimension: 44,
        child: FloatingGlass(
          blur: true,
          readerStyle: true,
          child: IconButton(
            tooltip: label,
            onPressed: tap,
            icon: AppIcon(icon, size: 19),
          ),
        ),
      );
  Widget topBar() => Row(
    children: [
      readerIcon(
        selected.isNotEmpty ? LucideIcons.x : LucideIcons.chevronLeftDir,
        selected.isNotEmpty ? 'Cancel selection' : 'Close reader',
        selected.isNotEmpty ? clearSelection : () => Navigator.pop(context),
      ),
      SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 44,
          child: FloatingGlass(
            blur: true,
            readerStyle: true,
            radius: 999,
            child: TextButton(
              onPressed: passage,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: EdgeInsets.symmetric(horizontal: 12),
                shape: StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      '${malayalamBooks[s.book]} ${s.chapter}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  AppIcon(LucideIcons.chevronDown, size: 11),
                ],
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: 12),
      readerIcon(LucideIcons.search, 'Search Bible', openSearch),
    ],
  );
  void openSearch() {
    pauseAutoScroll();
    Navigator.push(
      context,
      CupertinoPageRoute<void>(
        builder: (page) => Scaffold(
          body: AppBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  pageHeader(page, 'Search'),
                  Expanded(child: SearchPage(store: s, showTitle: false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomBar() {
    if (selected.isNotEmpty) {
      return Row(
        key: ValueKey('selectionBar'),
        children: [
          tool(LucideIcons.x, 'Clear selection', clearSelection),
          Expanded(
            child: Text(
              rangeMode ? 'Tap last verse' : '${selected.length} selected',
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
          tool(LucideIcons.arrowDownUp, 'Select a range', () {
            setState(() => rangeMode = !rangeMode);
          }),
          primaryPill(
            'Actions',
            () => selectionActions(
              context,
              s,
              selection,
              onApplied: clearSelection,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        tool(
          LucideIcons.chevronLeftDir,
          'Previous chapter',
          s.book == 'GEN' && s.chapter == 1 ? null : () => move(-1),
        ),
        tool(LucideIcons.list, 'Go to passage', passage),
        tool(
          autoScrolling ? LucideIcons.circlePause : LucideIcons.circlePlay,
          autoScrolling ? 'Pause auto-scroll' : 'Auto-scroll',
          showAutoScroll,
          active: autoScrolling,
        ),
        SizedBox.square(
          dimension: 44,
          child: TextButton(
            onPressed: () {
              pauseAutoScroll();
              appearance(context, s);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: textColor,
            ),
            child: Text(
              'Aa',
              style: TextStyle(fontFamily: 'Editorial', fontSize: 21),
            ),
          ),
        ),
        tool(
          LucideIcons.chevronRightDir,
          'Next chapter',
          s.book == 'REV' && s.chapter == 22 ? null : () => move(1),
        ),
      ],
    );
  }

  Widget readingScroll() => NotificationListener<ScrollNotification>(
    onNotification: (n) {
      if (s.autoHide &&
          selected.isEmpty &&
          n is ScrollUpdateNotification &&
          n.dragDetails != null) {
        final delta = n.scrollDelta ?? 0;
        if (delta.sign != scrollIntent.sign) scrollIntent = 0;
        scrollIntent += delta;
        if (scrollIntent.abs() >= 48) {
          controls = scrollIntent < 0;
          scrollIntent = 0;
        }
      }
      return false;
    },
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!pauseAutoScroll() && selected.isEmpty) controls = !controls;
      },
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0).abs() > 250) {
          move(d.primaryVelocity! < 0 ? 1 : -1);
        }
      },
      child: ScrollConfiguration(
        behavior: const ReaderScrollBehavior().copyWith(scrollbars: false),
        child: RawScrollbar(
          key: const ValueKey('chapter-progress'),
          controller: scroll,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: false,
          scrollbarOrientation: ScrollbarOrientation.right,
          thickness: 3,
          radius: const Radius.circular(2),
          trackRadius: const Radius.circular(2),
          trackColor: uiMuted(context).withValues(alpha: .12),
          trackBorderColor: Colors.transparent,
          thumbColor: uiAccent(context).withValues(alpha: .65),
          padding:
              MediaQuery.paddingOf(context) +
              const EdgeInsets.fromLTRB(0, 64, 4, 64),
          minThumbLength: 24,
          child: SingleChildScrollView(
            key: const ValueKey('readerScroll'),
            controller: scroll,
            physics: const ReaderScrollPhysics(),
            child: chapterContent(interactive: true),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) {
      prepare();
      final top = MediaQuery.paddingOf(context).top;
      final bottom = MediaQuery.paddingOf(context).bottom;
      return PopScope(
        canPop: selected.isEmpty,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            pauseAutoScroll();
          } else if (selected.isNotEmpty) {
            clearSelection();
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: s.theme == 2
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: paper,
            body: ValueListenableBuilder<bool>(
              valueListenable: chromeVisible,
              child: RepaintBoundary(
                key: const ValueKey('stable-reader-page'),
                child: readingScroll(),
              ),
              builder: (context, showChrome, page) {
                final visible =
                    showChrome || selected.isNotEmpty || autoScrolling;
                return Stack(
                  children: [
                    Positioned.fill(child: page!),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          key: ValueKey('readerEdgeBlur'),
                          opacity: visible && s.blurStrength > 0 ? 1 : 0,
                          duration: motionDuration(context, 200),
                          child: ReaderEdgeFade(
                            paper: paper,
                            topExtent: top + 76,
                            bottomExtent: bottom + 120,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: StatusBarVeil(),
                    ),
                    Positioned(
                      top: 0,
                      left: 18,
                      right: 18,
                      child: chrome(
                        'readerTopControls',
                        visible,
                        Offset(0, -1.2),
                        Padding(
                          padding: EdgeInsets.only(top: top + 8, bottom: 8),
                          child: topBar(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 18,
                      right: 18,
                      child: chrome(
                        'readerBottomControls',
                        visible,
                        Offset(0, 1.8),
                        Padding(
                          padding: EdgeInsets.only(bottom: bottom + 12),
                          child: FloatingGlass(
                            blur: true,
                            readerStyle: true,
                            key: const ValueKey('reader-bottom-glass'),
                            radius: 28,
                            padding: EdgeInsets.all(6),
                            child: bottomBar(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class ReaderEdgeFade extends StatelessWidget {
  final Color paper;
  final double topExtent, bottomExtent;
  const ReaderEdgeFade({
    super.key,
    required this.paper,
    required this.topExtent,
    required this.bottomExtent,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            paper.withValues(alpha: .68),
            paper.withValues(alpha: 0),
            paper.withValues(alpha: 0),
            // Let the dock sample scripture rather than an opaque edge wash.
            paper.withValues(alpha: .08),
          ],
          stops: [
            0,
            (topExtent / c.maxHeight).clamp(0.0, .4),
            (1 - bottomExtent / c.maxHeight).clamp(.6, 1.0),
            1,
          ],
        ),
      ),
    ),
  );
}

class MarkedScripture extends StatelessWidget {
  final String text;
  final String? number;
  final TextStyle style;
  final Color? color;
  final bool selected;
  const MarkedScripture({
    super.key,
    required this.text,
    this.number,
    required this.style,
    required this.selected,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final child = Text.rich(
      scriptureSpan(text, number, effectiveStyle),
      style: effectiveStyle,
    );
    if (color == null) return child;
    return CustomPaint(
      painter: ScriptureMarkPainter(
        text: text,
        number: number,
        style: effectiveStyle,
        color: color!,
        selected: selected,
        scaler: MediaQuery.textScalerOf(context),
        direction: Directionality.of(context),
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: child,
    );
  }
}

class ScriptureMarkPainter extends CustomPainter {
  final String text;
  final String? number;
  final TextStyle style;
  final Color color;
  final bool selected;
  final TextScaler scaler;
  final TextDirection direction;
  final bool dark;
  ScriptureMarkPainter({
    required this.text,
    this.number,
    required this.style,
    required this.color,
    required this.selected,
    required this.scaler,
    required this.direction,
    this.dark = false,
  });
  List<(RRect, Path)>? _marks;
  List<TextBox>? _boxes;
  double? _width;
  @override
  void paint(Canvas canvas, Size size) {
    if (_boxes == null || _width != size.width) {
      final layout = TextPainter(
        text: scriptureSpan(text, number, style),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: size.width);
      _width = size.width;
      _marks = null;
      _boxes = layout.getBoxesForSelection(
        TextSelection(
          baseOffset: number == null ? 0 : number!.length + 2,
          extentOffset: text.length + (number == null ? 0 : number!.length + 2),
        ),
      );
      layout.dispose();
      // Shaped Malayalam can yield overlapping boxes for one line. Merge them
      // before painting so pigment is applied once and caps stay continuous.
      final lines = <Rect>[];
      for (final box in _boxes!) {
        final rect = box.toRect();
        final index = lines.indexWhere(
          (line) =>
              (line.center.dy - rect.center.dy).abs() <
              math.min(line.height, rect.height) * .25,
        );
        if (index < 0) {
          lines.add(rect);
        } else {
          lines[index] = lines[index].expandToInclude(rect);
        }
      }
      _boxes = [
        for (final line in lines)
          TextBox.fromLTRBD(
            line.left,
            line.top,
            line.right,
            line.bottom,
            direction,
          ),
      ];
    }
    // Geometry is built once for this text/style/width, not on scrolling frames.
    _marks ??= [
      for (int line = 0; line < _boxes!.length; line++)
        _buildMark(_boxes![line], line),
    ];
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final fill = Paint()
      ..color = color.withValues(
        alpha: selected
            ? .085
            : dark
            ? .20
            : .24,
      );
    final chalk = Paint()..color = color.withValues(alpha: dark ? .12 : .10);
    for (final (shape, grain) in _marks!) {
      canvas.drawRRect(shape, fill);
      if (!selected) {
        canvas.save();
        canvas.clipRRect(shape);
        canvas.drawPath(grain, chalk);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  (RRect, Path) _buildMark(TextBox box, int line) {
    final bounds = Rect.fromLTRB(
      box.left,
      box.top + box.toRect().height * .12,
      box.right,
      box.bottom - box.toRect().height * .05,
    );
    final shape = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(math.min(3, bounds.height / 4)),
    );
    final grain = Path();
    final random = math.Random(517 + line);
    // Fine, deterministic chalk deposits: straight edges, uneven pigment inside.
    final count = (bounds.width * bounds.height / 25).round();
    for (int i = 0; i < count; i++) {
      final x = bounds.left + random.nextDouble() * bounds.width;
      final y = bounds.top + random.nextDouble() * bounds.height;
      grain.addOval(
        Rect.fromLTWH(
          x,
          y,
          .4 + random.nextDouble() * 2.2,
          .35 + random.nextDouble() * .7,
        ),
      );
    }
    for (int band = 1; band < 6; band++) {
      grain.addRect(
        Rect.fromLTWH(
          bounds.left,
          bounds.top + bounds.height * band / 6,
          bounds.width,
          .3,
        ),
      );
    }
    return (shape, grain);
  }

  @override
  bool shouldRepaint(covariant ScriptureMarkPainter old) =>
      text != old.text ||
      number != old.number ||
      style != old.style ||
      color != old.color ||
      selected != old.selected ||
      scaler != old.scaler ||
      direction != old.direction ||
      dark != old.dark;
}

TextSpan scriptureSpan(String text, String? number, TextStyle style) =>
    TextSpan(
      style: style,
      children: [
        if (number != null)
          TextSpan(
            text: '$number  ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xffff5035),
            ),
          ),
        TextSpan(text: text),
      ],
    );
