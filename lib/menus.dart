part of 'main.dart';

Future<void> appearance(BuildContext context, BibleStore s) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      builder: (_) => ReadingAppearance(store: s),
    );

class ReadingAppearance extends StatelessWidget {
  final BibleStore store;
  const ReadingAppearance({super.key, required this.store});

  void update(
    BuildContext context,
    VoidCallback change, {
    bool persist = true,
  }) {
    change();
    store.changed();
    if (persist) save(context, store);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Theme(
      data: appTheme(store.theme),
      child: Builder(
        builder: (context) {
          final s = store;
          final sample = s.byId['PSA.23.1']?.text ?? s.current.first.text;
          return LayoutBuilder(
            builder: (context, box) {
              return Column(
                children: [
                  // This preview sits outside the scrolling control panel.
                  Container(
                    key: const ValueKey('typeface-preview'),
                    height: (box.maxHeight * .31).clamp(130.0, 240.0),
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: toneOf(context).background,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: ClipRect(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'സങ്കീർത്തനങ്ങൾ 23',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 13,
                              height: 1.6,
                              color: uiMuted(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text.rich(
                                key: const ValueKey('live-preview-text'),
                                TextSpan(
                                  children: [
                                    if (s.numbers)
                                      TextSpan(
                                        text: '1  ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: uiMuted(context),
                                        ),
                                      ),
                                    TextSpan(text: sample),
                                  ],
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: s.fontSize,
                                  height: s.lineHeight,
                                  color: uiInk(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: toneOf(context).background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            sheetGrip(context),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 8, 12, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: heading('Appearance', size: 21),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Done'),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                key: const ValueKey('appearance-controls'),
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  0,
                                  22,
                                  20,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      menuLabel(context, 'Text size'),
                                      const Spacer(),
                                      Text(
                                        '${s.fontSize.round()} pt',
                                        style: TextStyle(
                                          color: uiAccent(context),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Decrease text size',
                                        icon: const Icon(
                                          CupertinoIcons.minus,
                                          size: 18,
                                        ),
                                        onPressed: s.fontSize > 16
                                            ? () => update(
                                                context,
                                                () => s.fontSize =
                                                    (s.fontSize - 1).clamp(
                                                      16,
                                                      34,
                                                    ),
                                              )
                                            : null,
                                      ),
                                      Expanded(
                                        child: CupertinoSlider(
                                          key: const ValueKey(
                                            'text-size-slider',
                                          ),
                                          min: 16,
                                          max: 34,
                                          divisions: 18,
                                          activeColor: uiAccent(context),
                                          value: s.fontSize.clamp(16, 34),
                                          onChanged: (v) => update(
                                            context,
                                            () => s.fontSize = v,
                                            persist: false,
                                          ),
                                          onChangeEnd: (_) => save(context, s),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Increase text size',
                                        icon: const Icon(
                                          CupertinoIcons.plus,
                                          size: 18,
                                        ),
                                        onPressed: s.fontSize < 34
                                            ? () => update(
                                                context,
                                                () => s.fontSize =
                                                    (s.fontSize + 1).clamp(
                                                      16,
                                                      34,
                                                    ),
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  menuLabel(context, 'Theme'),
                                  const SizedBox(height: 10),
                                  PillSegments<int>(
                                    items: const {
                                      0: 'Light',
                                      1: 'Paper',
                                      2: 'Dark',
                                    },
                                    selected: s.theme,
                                    onChanged: (v) =>
                                        update(context, () => s.theme = v),
                                  ),
                                  const SizedBox(height: 20),
                                  menuLabel(context, 'Typeface'),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 82,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: readingFonts.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (context, i) {
                                        final e = readingFonts.entries
                                            .elementAt(i);
                                        return InkWell(
                                          key: ValueKey('font-${e.key}'),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          onTap: () => update(
                                            context,
                                            () => s.fontFamily = e.key,
                                          ),
                                          child: Container(
                                            width: 112,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: uiFill(context),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                width: 1.5,
                                                color: s.fontFamily == e.key
                                                    ? uiAccent(context)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'അക്ഷരം',
                                                  style: TextStyle(
                                                    fontFamily: e.key,
                                                    fontSize: 18,
                                                    height: 1.6,
                                                    color: uiInk(context),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  e.value,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: uiMuted(context),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  menuLabel(context, 'Line spacing'),
                                  const SizedBox(height: 10),
                                  PillSegments<double>(
                                    items: {
                                      1.6: 'Tight',
                                      1.9: 'Normal',
                                      2.2: 'Wide',
                                    },
                                    selected: [1.6, 1.9, 2.2].reduce(
                                      (a, b) =>
                                          (a - s.lineHeight).abs() <
                                              (b - s.lineHeight).abs()
                                          ? a
                                          : b,
                                    ),
                                    onChanged: (v) =>
                                        update(context, () => s.lineHeight = v),
                                  ),
                                  const SizedBox(height: 10),
                                  iosSwitchRow(
                                    'Verse numbers',
                                    s.numbers,
                                    (v) => update(context, () => s.numbers = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

Widget menuLabel(BuildContext context, String text) => Text(
  text,
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: uiMuted(context),
  ),
);

Future<void> picker(
  BuildContext context,
  BibleStore s, {
  VoidCallback? onGo,
}) async {
  final target = await showModalBottomSheet<Verse>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PassageSheet(store: s),
  );
  if (target != null) {
    s.go(target.book, target.chapter, target.number);
    if (context.mounted) await save(context, s);
    onGo?.call();
  }
}

class PassageSheet extends StatefulWidget {
  final BibleStore store;
  const PassageSheet({super.key, required this.store});
  @override
  State<PassageSheet> createState() => _PassageSheetState();
}

class _PassageSheetState extends State<PassageSheet> {
  BibleStore get s => widget.store;
  late String book = s.book, verse = s.verse;
  late int chapter = s.chapter;
  late bool nt = bookNames.keys.toList().indexOf(book) >= 39;
  int stage = 1;
  String query = '';
  final search = TextEditingController();
  final extent = DraggableScrollableController();
  @override
  void dispose() {
    extent.dispose();
    search.dispose();
    super.dispose();
  }

  List<Verse> get verses => s.chapters['$book.$chapter']!;
  void chooseBook(String code) {
    setState(() {
      book = code;
      chapter = 1;
      verse = s.chapters['$code.1']!.first.number;
      stage = 1;
      query = '';
      search.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void open() => Navigator.pop(
    context,
    verses.firstWhere((v) => v.number == verse, orElse: () => verses.first),
  );
  @override
  Widget build(BuildContext context) {
    final refs = query.contains(RegExp(r'\d')) ? s.search(query) : <Verse>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, box) {
          final available = box.maxHeight;
          final min = (240 / available).clamp(.32, .88);
          final initial = (440 / available).clamp(min, .94);
          return DraggableScrollableSheet(
            key: const ValueKey('passage-draggable'),
            controller: extent,
            expand: false,
            initialChildSize: initial,
            minChildSize: min,
            maxChildSize: .96,
            snap: true,
            snapSizes: [initial],
            builder: (context, sheetScroll) => GlassPanel(
              radius: 30,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (d) {
                          if (extent.isAttached) {
                            extent.jumpTo(
                              (extent.size - d.delta.dy / available).clamp(
                                min,
                                .96,
                              ),
                            );
                          }
                        },
                        onVerticalDragEnd: (d) {
                          if (!extent.isAttached) return;
                          if (extent.size < min + .025 &&
                              (d.primaryVelocity ?? 0) > 0) {
                            Navigator.pop(context);
                            return;
                          }
                          final target = extent.size > initial + .12
                              ? 0.96
                              : initial;
                          extent.animateTo(
                            target,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Column(
                          children: [
                            sheetGrip(context),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  'Passage',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                    color: uiInk(context),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox.shrink(),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: search,
                          onTap: () {
                            if (extent.isAttached) {
                              extent.animateTo(
                                .96,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          onChanged: (v) => setState(() => query = v.trim()),
                          onSubmitted: (_) {
                            if (refs.isNotEmpty) {
                              Navigator.pop(context, refs.first);
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Book or reference',
                            prefixIcon: AppIcon(
                              CupertinoIcons.search,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: step(0, 'Book', bookNames[book]!),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: step(1, 'Chapter', '$chapter'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: step(2, 'Verse', verse)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: query.isNotEmpty
                            ? searchResults(refs, sheetScroll)
                            : stage == 0
                            ? bookList(sheetScroll)
                            : numberGrid(sheetScroll),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: primaryPill(
                          'Open ${bookNames[book]} $chapter:$verse',
                          open,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget step(int index, String label, String value) => InkWell(
    key: ValueKey('stage-$index'),
    borderRadius: BorderRadius.circular(16),
    onTap: () => setState(() => stage = index),
    child: Container(
      height: 54,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: stage == index
            ? uiAccent(context).withValues(alpha: .12)
            : uiFill(context).withValues(alpha: .65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: uiMuted(context))),
          SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: uiInk(context),
            ),
          ),
        ],
      ),
    ),
  );
  Widget searchResults(List<Verse> refs, ScrollController sheetScroll) {
    final matches = bookNames.entries.where(
      (e) =>
          e.value.toLowerCase().contains(query.toLowerCase()) ||
          e.key.toLowerCase() == query.toLowerCase(),
    );
    return ListView(
      controller: sheetScroll,
      children: [
        if (refs.isNotEmpty)
          ListTile(
            title: Text(
              refs.first.reference,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: uiInk(context),
              ),
            ),
            onTap: () => Navigator.pop(context, refs.first),
          ),
        for (final b in matches)
          ListTile(
            dense: true,
            title: Text(
              b.value,
              style: TextStyle(fontSize: 14, color: uiInk(context)),
            ),
            trailing: AppIcon(CupertinoIcons.chevron_right, size: 12),
            onTap: () => chooseBook(b.key),
          ),
      ],
    );
  }

  Widget bookList(ScrollController sheetScroll) => Column(
    children: [
      PillSegments<bool>(
        items: {false: 'Old Testament', true: 'New Testament'},
        selected: nt,
        onChanged: (v) {
          if (sheetScroll.hasClients) {
            sheetScroll.jumpTo(0);
          }
          setState(() => nt = v);
        },
      ),
      SizedBox(height: 10),
      Expanded(
        child: ListView(
          controller: sheetScroll,
          children: [
            for (final e in bookNames.entries.where(
              (e) => (bookNames.keys.toList().indexOf(e.key) >= 39) == nt,
            ))
              ListTile(
                dense: true,
                title: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: e.key == book
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: uiInk(context),
                  ),
                ),
                trailing: AppIcon(
                  e.key == book
                      ? CupertinoIcons.checkmark
                      : CupertinoIcons.chevron_right,
                  size: 13,
                  color: uiMuted(context),
                ),
                onTap: () => chooseBook(e.key),
              ),
          ],
        ),
      ),
    ],
  );
  Widget numberGrid(ScrollController sheetScroll) => PassageNumberGrid(
    controller: sheetScroll,
    key: ValueKey('grid-$stage-$book-$chapter'),
    kind: stage == 1 ? 'chapter' : 'verse',
    items: stage == 1
        ? [for (int i = 1; i <= s.count(book); i++) '$i']
        : [for (final v in verses) v.number],
    selected: stage == 1 ? '$chapter' : verse,
    onChanged: (item) => setState(() {
      if (stage == 1) {
        chapter = int.parse(item);
        verse = s.chapters['$book.$chapter']!.first.number;
        stage = 2;
      } else {
        verse = item;
      }
    }),
  );
}

class PassageNumberGrid extends StatefulWidget {
  final String kind, selected;
  final ScrollController? controller;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const PassageNumberGrid({
    super.key,
    this.controller,
    required this.kind,
    required this.selected,
    required this.items,
    required this.onChanged,
  });
  @override
  State<PassageNumberGrid> createState() => _PassageNumberGridState();
}

class _PassageNumberGridState extends State<PassageNumberGrid> {
  ScrollController? controller;
  bool positioned = false;
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = (c.maxWidth / 52).floor().clamp(4, 8);
      final cell = (c.maxWidth - 8 * (columns - 1)) / columns;
      final row =
          widget.items
              .indexOf(widget.selected)
              .clamp(0, widget.items.length - 1) ~/
          columns;
      controller ??= ScrollController(
        initialScrollOffset: ((row - 2).clamp(0, 999)) * (cell + 8),
      );
      if (widget.controller != null && !positioned) {
        positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final external = widget.controller;
          if (!mounted || external == null || !external.hasClients) return;
          final visibleRows = (external.position.viewportDimension / (cell + 8))
              .floor()
              .clamp(1, 999);
          final firstRow = (row - (visibleRows - 1) ~/ 2).clamp(0, 999);
          external.jumpTo(
            (firstRow * (cell + 8)).clamp(0, external.position.maxScrollExtent),
          );
        });
      }
      return GridView.builder(
        controller: widget.controller ?? controller,
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, i) {
          final item = widget.items[i];
          final chosen = item == widget.selected;
          return Center(
            child: SizedBox.square(
              dimension: 44,
              child: TextButton(
                key: ValueKey('${widget.kind}-$item'),
                onPressed: () => widget.onChanged(item),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: chosen
                      ? uiAccent(context)
                      : uiFill(context).withValues(alpha: .6),
                  foregroundColor: chosen
                      ? uiOnAccent(context)
                      : uiInk(context),
                  shape: CircleBorder(),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
