part of 'main.dart';

Future<void> appearance(BuildContext context, BibleStore s) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close appearance',
      barrierColor: Colors.black.withValues(alpha: .18),
      transitionDuration: motionDuration(context, 300),
      pageBuilder: (popup, animation, secondaryAnimation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(popup),
                child: BackdropFilter(
                  key: const ValueKey('appearance-backdrop'),
                  filter: ImageFilter.blur(
                    sigmaX: 14 * animation.value,
                    sigmaY: 14 * animation.value,
                  ),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: .92,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, .06),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ReadingAppearance(store: s),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          child,
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
          final panel = Color.alphaBlend(
            toneOf(context).panelA,
            toneOf(context).background,
          );
          Widget divider() => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: uiInk(context).withValues(alpha: .07)),
          );
          return LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                Container(
                  key: const ValueKey('typeface-preview'),
                  height: (box.maxHeight * .34).clamp(155.0, 290.0),
                  margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eyebrow('PREVIEW'),
                      const SizedBox(height: 10),
                      Text(
                        'സങ്കീർത്തനങ്ങൾ 23',
                        style: TextStyle(
                          fontFamily: s.fontFamily,
                          fontSize: 20,
                          color: uiInk(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ClipRect(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (final n in ['1', '2'])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (s.numbers) ...[
                                          Text(
                                            n,
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 2.2,
                                              color: uiMuted(context),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                        ],
                                        Expanded(
                                          child: Text(
                                            s.byId['PSA.23.$n']?.text ?? '',
                                            key: n == '1'
                                                ? const ValueKey(
                                                    'live-preview-text',
                                                  )
                                                : null,
                                            style: TextStyle(
                                              fontFamily: s.fontFamily,
                                              fontSize: s.fontSize,
                                              height: s.lineHeight,
                                              color: uiInk(context),
                                            ),
                                          ),
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
                  ),
                ),
                Expanded(
                  child: Material(
                    color: panel,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          sheetGrip(context),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 6, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: heading('Appearance', size: 25),
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
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                              children: [
                                menuLabel(context, 'Text size'),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Decrease text size',
                                      onPressed: s.fontSize > 16
                                          ? () => update(
                                              context,
                                              () => s.fontSize--,
                                            )
                                          : null,
                                      icon: const Text(
                                        'A',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoSlider(
                                        key: const ValueKey('text-size-slider'),
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
                                      onPressed: s.fontSize < 34
                                          ? () => update(
                                              context,
                                              () => s.fontSize++,
                                            )
                                          : null,
                                      icon: const Text(
                                        'A',
                                        style: TextStyle(fontSize: 23),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: uiFill(
                                          context,
                                        ).withValues(alpha: .5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${s.fontSize.round()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: uiInk(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                divider(),
                                menuLabel(context, 'Theme'),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Semantics(
                                        selected: s.theme == i,
                                        button: true,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          onTap: () => update(
                                            context,
                                            () => s.theme = i,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 4,
                                            ),
                                            child: Column(
                                              children: [
                                                AnimatedContainer(
                                                  duration: motionDuration(
                                                    context,
                                                    200,
                                                  ),
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: [
                                                      const Color(0xfffdfdfd),
                                                      const Color(0xfff4eddf),
                                                      const Color(0xff252525),
                                                    ][i],
                                                    border: Border.all(
                                                      color: s.theme == i
                                                          ? uiAccent(context)
                                                          : uiMuted(
                                                              context,
                                                            ).withValues(
                                                              alpha: .12,
                                                            ),
                                                      width: s.theme == i
                                                          ? 2
                                                          : 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 7),
                                                Text(
                                                  ['Light', 'Paper', 'Dark'][i],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: uiInk(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                divider(),
                                menuLabel(context, 'Typeface'),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 76,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: readingFonts.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, i) {
                                      final e = readingFonts.entries.elementAt(
                                        i,
                                      );
                                      return Semantics(
                                        selected: s.fontFamily == e.key,
                                        button: true,
                                        child: InkWell(
                                          key: ValueKey('font-${e.key}'),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          onTap: () => update(
                                            context,
                                            () => s.fontFamily = e.key,
                                          ),
                                          child: AnimatedContainer(
                                            duration: motionDuration(
                                              context,
                                              180,
                                            ),
                                            width: 106,
                                            padding: const EdgeInsets.all(9),
                                            decoration: BoxDecoration(
                                              color: s.fontFamily == e.key
                                                  ? uiAccent(
                                                      context,
                                                    ).withValues(alpha: .08)
                                                  : uiFill(
                                                      context,
                                                    ).withValues(alpha: .4),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
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
                                                    color: uiInk(context),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  e.value,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: uiMuted(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                divider(),
                                menuLabel(context, 'Line spacing'),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Expanded(
                                        child: Semantics(
                                          selected:
                                              (s.lineHeight -
                                                      [1.6, 1.9, 2.2][i])
                                                  .abs() <
                                              .1,
                                          button: true,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () => update(
                                              context,
                                              () => s.lineHeight = [
                                                1.6,
                                                1.9,
                                                2.2,
                                              ][i],
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: i == 2 ? 0 : 6,
                                              ),
                                              child: Column(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: motionDuration(
                                                      context,
                                                      180,
                                                    ),
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (s.lineHeight -
                                                                      [
                                                                        1.6,
                                                                        1.9,
                                                                        2.2,
                                                                      ][i])
                                                                  .abs() <
                                                              .1
                                                          ? uiAccent(
                                                              context,
                                                            ).withValues(
                                                              alpha: .12,
                                                            )
                                                          : uiFill(
                                                              context,
                                                            ).withValues(
                                                              alpha: .4,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          for (
                                                            int j = 0;
                                                            j < 3;
                                                            j++
                                                          )
                                                            Container(
                                                              width: j == 1
                                                                  ? 17
                                                                  : 23,
                                                              height: 1.5,
                                                              margin:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        1.5 +
                                                                        i * 1.4,
                                                                  ),
                                                              color:
                                                                  (s.lineHeight -
                                                                              [
                                                                                1.6,
                                                                                1.9,
                                                                                2.2,
                                                                              ][i])
                                                                          .abs() <
                                                                      .1
                                                                  ? uiAccent(
                                                                      context,
                                                                    )
                                                                  : uiMuted(
                                                                      context,
                                                                    ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    [
                                                      'Compact',
                                                      'Normal',
                                                      'Spacious',
                                                    ][i],
                                                    style: TextStyle(
                                                      fontSize: 11,
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
                                ),
                                const SizedBox(height: 14),
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
            ),
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
          const initial = .96;
          return DraggableScrollableSheet(
            key: const ValueKey('passage-draggable'),
            controller: extent,
            expand: false,
            initialChildSize: initial,
            minChildSize: min,
            maxChildSize: .96,
            snap: true,
            snapSizes: const [],
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
                            child: step(0, 'Book', s.bookLabel(book)),
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
          e.key.toLowerCase() == query.toLowerCase() ||
          malayalamBooks[e.key]!.contains(query),
    );
    return ListView(
      controller: sheetScroll,
      children: [
        if (refs.isNotEmpty)
          ListTile(
            title: Text(
              s.verseLabel(refs.first),
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
              s.bookLabel(b.key),
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
                  s.bookLabel(e.key),
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
        open();
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

Widget appearanceGroup(BuildContext context, List<Widget> children) =>
    GlassPanel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
