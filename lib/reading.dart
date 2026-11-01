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
  Color get paper => Theme.of(context).colorScheme.surface;
  Color get textColor => uiInk(context);
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
      s.recordVisit();
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
    if (awake != s.keepAwake) {
      awake = s.keepAwake;
      unawaited(setAwake(s.keepAwake));
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
      save(context, s);
    }
  }

  void track() {
    if (restoring || selected.isNotEmpty) return;
    debounce?.cancel();
    debounce = Timer(Duration(milliseconds: 350), () {
      if (!mounted) return;
      final edge = MediaQuery.paddingOf(context).top + (controls ? 68 : 10);
      for (final e in keys.entries) {
        final box = e.value.currentContext?.findRenderObject();
        if (box is RenderBox &&
            box.hasSize &&
            box.localToGlobal(Offset.zero).dy >= edge) {
          if (s.verse != e.key) {
            s.verse = e.key;
            s.recordVisit();
            save(context, s);
          }
          break;
        }
      }
    });
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
    debounce?.cancel();
    if (s.haptics) HapticFeedback.selectionClick();
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
  }

  void move(int delta) {
    if (selected.isNotEmpty) return;
    debounce?.cancel();
    if (s.adjacent(delta)) {
      save(context, s);
      setState(() => controls = true);
    }
  }

  void passage() => picker(
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
  Widget tool(IconData icon, String label, VoidCallback? tap) =>
      SizedBox.square(
        dimension: 44,
        child: IconButton(
          tooltip: label,
          onPressed: tap,
          padding: EdgeInsets.zero,
          icon: AppIcon(
            icon,
            size: 20,
            color: tap == null ? textColor.withValues(alpha: .25) : textColor,
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
                        CupertinoIcons.checkmark_circle_fill,
                        size: 13,
                        color: textColor,
                      ),
                    )
                  else if (s.bookmarks.contains(v.id) || hasNote)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: AppIcon(
                        hasNote
                            ? CupertinoIcons.doc_text
                            : CupertinoIcons.bookmark_fill,
                        size: 9,
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
      child: content,
    );
  }

  Widget chrome(String name, bool visible, Offset hidden, Widget child) =>
      IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : hidden,
            duration: motionDuration(context, 220),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              key: ValueKey(name),
              opacity: visible ? 1 : 0,
              duration: motionDuration(context, 180),
              child: child,
            ),
          ),
        ),
      );
  Widget readerIcon(
    IconData icon,
    String label,
    VoidCallback? tap, {
    bool dark = false,
  }) => SizedBox.square(
    dimension: 44,
    child: FloatingGlass(
      blur: true,
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
        selected.isNotEmpty
            ? CupertinoIcons.xmark
            : CupertinoIcons.chevron_left,
        selected.isNotEmpty ? 'Cancel selection' : 'Close reader',
        selected.isNotEmpty ? clearSelection : () => Navigator.pop(context),
        dark: s.theme == 2,
      ),
      SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 44,
          child: FloatingGlass(
            blur: true,
            radius: 999,
            dark: s.theme == 2,
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
                  AppIcon(CupertinoIcons.chevron_down, size: 11),
                ],
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: 12),
      readerIcon(
        CupertinoIcons.search,
        'Search Bible',
        openSearch,
        dark: s.theme == 2,
      ),
    ],
  );
  void openSearch() => Navigator.push(
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
  Widget bottomBar() {
    if (selected.isNotEmpty) {
      return Row(
        key: ValueKey('selectionBar'),
        children: [
          tool(CupertinoIcons.xmark, 'Clear selection', clearSelection),
          Expanded(
            child: Text(
              rangeMode ? 'Tap last verse' : '${selected.length} selected',
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
          tool(CupertinoIcons.arrow_up_arrow_down, 'Select a range', () {
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
          CupertinoIcons.chevron_left,
          'Previous chapter',
          s.book == 'GEN' && s.chapter == 1 ? null : () => move(-1),
        ),
        tool(CupertinoIcons.list_bullet, 'Go to passage', passage),
        SizedBox.square(
          dimension: 44,
          child: TextButton(
            onPressed: () => appearance(context, s),
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
          CupertinoIcons.chevron_right,
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
        if (scrollIntent.abs() >= 14) {
          controls = scrollIntent < 0;
          scrollIntent = 0;
        }
      }
      return false;
    },
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (selected.isEmpty) controls = !controls;
      },
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0).abs() > 250) {
          move(d.primaryVelocity! < 0 ? 1 : -1);
        }
      },
      child: SingleChildScrollView(
        key: ValueKey('readerScroll'),
        controller: scroll,
        physics: const ContentScrollPhysics(),
        child: chapterContent(interactive: true),
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
          if (!didPop && selected.isNotEmpty) clearSelection();
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
                final visible = showChrome || selected.isNotEmpty;
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
                            topExtent: top + 120,
                            bottomExtent: bottom + 120,
                          ),
                        ),
                      ),
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
                            key: const ValueKey('reader-bottom-glass'),
                            radius: 28,
                            dark: s.theme == 2,
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
            paper.withValues(alpha: .92),
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
  ScriptureMarkPainter({
    required this.text,
    this.number,
    required this.style,
    required this.color,
    required this.selected,
    required this.scaler,
    required this.direction,
  });
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
      _boxes = layout.getBoxesForSelection(
        TextSelection(
          baseOffset: number == null ? 0 : number!.length + 2,
          extentOffset: text.length + (number == null ? 0 : number!.length + 2),
        ),
      );
      layout.dispose();
    }
    int line = 0;
    for (final box in _boxes!) {
      if (box.right - box.left < 1) continue;
      final left = box.left, right = box.right;
      canvas.save();
      canvas.clipRect(box.toRect());
      final top = box.top + box.toRect().height * .12;
      final bottom = box.bottom - box.toRect().height * .05;
      final height = bottom - top;
      final path = Path()..moveTo(left + 1, top + 1);
      const steps = 18;
      for (int i = 1; i <= steps; i++) {
        final x = left + (right - left) * i / steps;
        path.lineTo(x, top + math.sin(i * 1.8 + line) * .65);
      }
      path.quadraticBezierTo(
        right + 3,
        (top + bottom) / 2,
        right - 2,
        bottom - 1,
      );
      for (int i = steps - 1; i >= 0; i--) {
        final x = left + (right - left) * i / steps;
        path.lineTo(x, bottom + math.sin(i * 1.3 + line + 2) * .75);
      }
      path.quadraticBezierTo(left - 3, (top + bottom) / 2, left + 1, top + 1);
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: selected ? 0.085 : 0.26),
      );
      if (!selected) {
        canvas.save();
        canvas.clipPath(path);
        final grain = math.Random(517 + line);
        for (int i = 0; i < (right - left) * height / 35; i++) {
          final x = left + grain.nextDouble() * (right - left);
          final y = top + grain.nextDouble() * height;
          canvas.drawLine(
            Offset(x, y),
            Offset(x + 1 + grain.nextDouble() * 3, y + .3),
            Paint()
              ..color = color.withValues(alpha: .16)
              ..strokeWidth = .6 + grain.nextDouble(),
          );
        }
        // Uneven translucent pigment gives a hand-drawn crayon texture.
        for (int band = 1; band < 8; band++) {
          final y = top + height * band / 8;
          canvas.drawLine(
            Offset(left + 1, y),
            Offset(right - 2, y + math.sin(band + line) * .7),
            Paint()
              ..color = color.withValues(alpha: band.isEven ? 0.075 : 0.035)
              ..strokeWidth = 1.1
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.restore();
      }
      canvas.restore();
      line++;
    }
  }

  @override
  bool shouldRepaint(covariant ScriptureMarkPainter old) =>
      text != old.text ||
      number != old.number ||
      style != old.style ||
      color != old.color ||
      selected != old.selected ||
      scaler != old.scaler ||
      direction != old.direction;
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
