import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, FragmentProgram, FragmentShader;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';

part 'surfaces.dart';
part 'selection.dart';
part 'reading.dart';
part 'theme.dart';
part 'menus.dart';
part 'plans.dart';
part 'motion.dart';
part 'icons.dart';
part 'dashboard.dart';
part 'tags.dart';

const ink = Color(0xff16181d);
const accent = Color(0xff526FA3);
const muted = Color(0xff727580);
final attribution =
    'Malayalam Bible 1910 edition, digitized, revised and published by volunteers of The Free Bible Foundation in the contemporary orthography.\n\nCopyright © 2015 The Free Bible Foundation.\nEdition ID: mal2015 / MALFBF.\n\nScripture text: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0).\nhttps://creativecommons.org/licenses/by-sa/4.0/\n\nSource: https://ebible.org/mal2015/\nhttps://ebible.org/Scriptures/mal2015_vpl.zip\n\nThe text is distributed under the same license. Its wording has not been intentionally changed. The publisher’s verse-per-line text has been converted to JSON for offline reading; section headings, notes and original formatting are not included in that source export. This app is not endorsed by the publisher.\n\nNoto Serif Malayalam font: SIL Open Font License 1.1.\n\nBible 2.3.0 · Flutter for Android\nYour bookmarks and notes are stored on this device.';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final name in ['NotoSansMalayalam', 'Manjari', 'Gayathri']) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString('assets/fonts/$name-OFL.txt'));
    }
    yield LicenseEntryWithLineBreaks([
      'Inter',
    ], await rootBundle.loadString('assets/fonts/Inter-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Lora',
    ], await rootBundle.loadString('assets/fonts/Lora-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Noto Serif Malayalam',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Malayalam Bible · The Free Bible Foundation',
    ], await rootBundle.loadString('assets/ATTRIBUTION.txt'));
  });
  runApp(WordApp());
}

class WordApp extends StatefulWidget {
  final BibleStore? store;
  const WordApp({super.key, this.store});
  @override
  State<WordApp> createState() => _WordAppState();
}

class _WordAppState extends State<WordApp> {
  late final store = widget.store ?? BibleStore();
  late final Future<void> loading = store.all.isEmpty
      ? store.load()
      : Future<void>.value();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: store.themeChanges,
    builder: (context, mode, _) => MaterialApp(
      title: 'Bible',
      scrollBehavior: const ContentScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: appTheme(mode),
      themeAnimationDuration: const Duration(milliseconds: 180),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: mode == 2
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: mode == 2 ? Brightness.dark : Brightness.light,
            primaryColor: uiAccent(context),
            scaffoldBackgroundColor: toneOf(context).background,
          ),
          child: child!,
        ),
      ),
      home: FutureBuilder(
        future: loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Unable to open Bible',
                  style: TextStyle(color: uiInk(context)),
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold();
          }
          return Home(store: store);
        },
      ),
    ),
  );
}

Widget heading(String t, {double size = 32, Color? color}) => Builder(
  builder: (context) => Text(
    t,
    style: TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? uiInk(context),
      letterSpacing: -.7,
    ),
  ),
);
Widget eyebrow(String t) => Builder(
  builder: (context) => Text(
    t,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.4,
      color: uiMuted(context),
    ),
  ),
);
Widget surface(Widget child, {EdgeInsets padding = const EdgeInsets.all(18)}) =>
    GlassPanel(padding: padding, child: child);
Widget roundButton(
  IconData icon,
  VoidCallback? action,
  String label, {
  Color? color,
}) => glassIcon(icon, label, action);
Future<void> save(BuildContext context, BibleStore store) async {
  try {
    await store.persist();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save: $e')));
    }
  }
}

Future<void> openReader(
  BuildContext context,
  BibleStore store, {
  Verse? verse,
}) async {
  if (verse != null) store.go(verse.book, verse.chapter, verse.number);
  await Navigator.of(
    context,
  ).push(CupertinoPageRoute<void>(builder: (_) => Reader(store: store)));
  if (context.mounted) store.changed();
}

class Home extends StatefulWidget {
  final BibleStore store;
  const Home({super.key, required this.store});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late final tabMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late final tabOpacity = tabMotion.drive(
    Tween<double>(
      begin: .35,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeOutCubic)),
  );
  late final tabOffset = tabMotion.drive(
    Tween<Offset>(
      begin: const Offset(0, .018),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)),
  );
  final visited = <int>{0};
  bool openingReader = false;
  @override
  void dispose() {
    tabMotion.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    if (tab == index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      tab = index;
      visited.add(index);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      tabMotion.value = 1;
    } else {
      tabMotion.forward(from: 0);
    }
  }

  late final pages = <Widget>[
    RepaintBoundary(
      child: ListenableBuilder(
        listenable: s,
        builder: (context, _) => library(),
      ),
    ),
    const SizedBox(),
    RepaintBoundary(child: SearchPage(store: s)),
    RepaintBoundary(child: SavedPage(store: s)),
  ];
  int tab = 0;
  BibleStore get s => widget.store;
  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: AppBackdrop(
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: tabOpacity,
              child: SlideTransition(
                position: tabOffset,
                child: IndexedStack(
                  index: tab,
                  children: [
                    for (int i = 0; i < pages.length; i++)
                      TickerMode(
                        enabled: tab == i,
                        child: !visited.contains(i)
                            ? const SizedBox.shrink()
                            : i < 2
                            ? pages[i]
                            : SafeArea(bottom: false, child: pages[i]),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (tab == 0)
            const Positioned(top: 0, left: 0, right: 0, child: StatusBarVeil()),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: FloatingGlass(
        blur: true,
        radius: 28,
        padding: EdgeInsets.all(5),
        child: LayoutBuilder(
          builder: (context, c) => SizedBox(
            height: math.max(
              56,
              MediaQuery.textScalerOf(context).scale(11) * 1.3 + 40,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedAlign(
                    alignment: Alignment(-1 + 2 * tab / 3, 0),
                    duration: motionDuration(context, 340),
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: .25,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: uiAccent(context).withValues(alpha: .11),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    nav(CupertinoIcons.square_grid_2x2, 'Library', 0),
                    nav(CupertinoIcons.book, 'Read', 1),
                    nav(CupertinoIcons.search, 'Search', 2),
                    nav(CupertinoIcons.bookmark, 'Saved', 3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget nav(IconData icon, String title, int index) => Expanded(
    child: Semantics(
      selected: tab == index,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          if (index == 1) {
            if (openingReader) return;
            openingReader = true;
            try {
              await openReader(context, s);
            } finally {
              openingReader = false;
            }
          } else {
            switchTab(index);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon,
                color: tab == index ? uiAccent(context) : uiMuted(context),
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: tab == index ? FontWeight.w600 : FontWeight.w400,
                  color: tab == index ? uiAccent(context) : uiMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget library() => ReadingHub(store: s, onSaved: () => switchTab(3));
}

void showAbout(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (sheet) => SheetShell(
    title: 'About Bible',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Malayalam Bible',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: uiInk(sheet),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '1910 · Contemporary orthography',
          style: TextStyle(fontSize: 14, color: uiMuted(sheet)),
        ),
        const SizedBox(height: 20),
        Text(
          'Digitized, revised and published by volunteers of The Free Bible Foundation.',
          style: TextStyle(fontSize: 14, height: 1.6, color: uiInk(sheet)),
        ),
        const SizedBox(height: 12),
        Text(
          '© 2015 The Free Bible Foundation · CC BY-SA 4.0',
          style: TextStyle(fontSize: 12, height: 1.6, color: uiMuted(sheet)),
        ),
        const SizedBox(height: 20),
        settingsRow(
          sheet,
          CupertinoIcons.doc_text,
          'Edition & licenses',
          onTap: () {
            Navigator.push(
              sheet,
              CupertinoPageRoute<void>(
                builder: (page) => Scaffold(
                  body: SafeArea(
                    child: Column(
                      children: [
                        pageHeader(page, 'Edition & licenses'),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                            children: [
                              SelectableText(
                                attribution,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: () => showLicensePage(
                                  context: page,
                                  applicationName: 'Bible',
                                  applicationVersion: '2.3.0',
                                ),
                                child: const Text('Open-source licenses'),
                              ),
                            ],
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
        const SizedBox(height: 12),
        Text(
          'Version 2.3.0',
          style: TextStyle(fontSize: 12, color: uiMuted(sheet)),
        ),
      ],
    ),
  ),
);

class SearchPage extends StatefulWidget {
  final BibleStore store;
  final bool showTitle;
  const SearchPage({super.key, required this.store, this.showTitle = true});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  Timer? debounce;
  List<Verse> results = [];
  String query = '';
  @override
  void dispose() {
    controller.dispose();
    debounce?.cancel();
    super.dispose();
  }

  void search(String value) {
    debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        query = '';
        results = [];
      });
      return;
    }
    debounce = Timer(Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          query = value.trim();
          results = widget.store.search(query);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              heading('Search', size: 32),
              SizedBox(height: 18),
            ],
            TextField(
              controller: controller,
              onChanged: search,
              decoration: InputDecoration(
                hintText: 'Word or reference',
                prefixIcon: AppIcon(CupertinoIcons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            controller.clear();
                            search('');
                          },
                          icon: AppIcon(CupertinoIcons.xmark, size: 18),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: query.isEmpty
            ? empty(
                CupertinoIcons.search,
                'Search scripture',
                'Search Malayalam words and phrases,\nor enter an English reference such as John 3:16.',
              )
            : results.isEmpty
            ? empty(
                CupertinoIcons.search,
                'No matching verses',
                'Try a different spelling or a book reference.',
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 112),
                itemCount: results.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${results.length} results',
                        style: TextStyle(color: uiMuted(context), fontSize: 12),
                      ),
                    );
                  }
                  final v = results[i - 1];
                  return verseCard(context, widget.store, v);
                },
              ),
      ),
    ],
  );
}

Widget empty(IconData icon, String title, String description) => Builder(
  builder: (context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 28, color: uiMuted(context)),
          SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: uiMuted(context),
            ),
          ),
        ],
      ),
    ),
  ),
);
Widget verseCard(
  BuildContext context,
  BibleStore s,
  Verse v, {
  String? note,
  Widget? footer,
}) => Padding(
  padding: EdgeInsets.only(bottom: 12),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => openReader(context, s, verse: v),
    onLongPress: () => verseActions(context, s, v),
    child: surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note != null && s.noteRanges.containsKey(v.id)
                      ? passageLabel([
                          for (final id in s.noteRanges[v.id]!)
                            if (s.byId.containsKey(id)) s.byId[id]!,
                        ])
                      : v.reference,
                  style: TextStyle(
                    color: uiAccent(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (s.bookmarks.contains(v.id))
                AppIcon(
                  CupertinoIcons.bookmark_fill,
                  size: 14,
                  color: uiAccent(context),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            v.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: s.fontFamily,
              fontSize: 17,
              height: 1.8,
            ),
          ),
          if (note != null) ...[
            Divider(height: 28),
            Text(
              note,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 10), footer],
        ],
      ),
    ),
  ),
);

class SavedPage extends StatefulWidget {
  final BibleStore store;
  const SavedPage({super.key, required this.store});
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  int tab = 0;
  String? tag;
  String order = "Bible order";
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final s = widget.store;
      final ids =
          (tab == 0
                  ? s.bookmarks
                  : tab == 1
                  ? s.highlights
                  : s.notes.keys)
              .toSet();
      final verses = ids
          .map((id) => s.byId[id])
          .whereType<Verse>()
          .where(
            (v) =>
                (tab != 0 ||
                tag == null ||
                (s.bookmarkTags[v.id] ?? []).contains(tag)),
          )
          .toList();
      verses.sort(
        (a, b) => (s.verseOrder[a.id] ?? 0).compareTo(s.verseOrder[b.id] ?? 0),
      );
      if (tab == 0 && order == 'Recently saved') {
        final ranked = {
          for (final e
              in s.bookmarks.toList().reversed.toList().asMap().entries)
            e.value: e.key,
        };
        verses.sort((a, b) => ranked[a.id]!.compareTo(ranked[b.id]!));
      }
      if (tab == 0 && order == 'Tag name') {
        verses.sort(
          (a, b) => (s.bookmarkTags[a.id] ?? []).join().compareTo(
            (s.bookmarkTags[b.id] ?? []).join(),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading('Saved', size: 32),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PillSegments<int>(
                    items: const {0: 'Bookmarks', 1: 'Highlights', 2: 'Notes'},
                    selected: tab,
                    onChanged: (v) => setState(() => tab = v),
                  ),
                ),
              ],
            ),
          ),
          if (tab == 0 && s.bookmarks.isNotEmpty) ...[
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ChoiceChip(
                    label: const Text('All tags'),
                    selected: tag == null,
                    onSelected: (_) => setState(() => tag = null),
                  ),
                  for (final t in s.knownTags)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: tag == t,
                        onSelected: (_) =>
                            setState(() => tag = tag == t ? null : t),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Spacer(),
                  DropdownButton<String>(
                    value: order,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: uiMuted(context),
                    ),
                    items: [
                      for (final v in [
                        'Bible order',
                        'Recently saved',
                        'Tag name',
                      ])
                        DropdownMenuItem(value: v, child: Text(v)),
                    ],
                    onChanged: (v) => setState(() => order = v!),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: verses.isEmpty
                ? empty(
                    CupertinoIcons.bookmark,
                    tag != null && tab == 0
                        ? 'No verses with this tag'
                        : [
                            'No bookmarks yet',
                            'No highlights yet',
                            'No notes yet',
                          ][tab],
                    'Tap a verse while reading to add a\nbookmark, highlight, or personal note.',
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 112),
                    itemCount: verses.length,
                    itemBuilder: (context, i) => verseCard(
                      context,
                      s,
                      verses[i],
                      note: tab == 2 ? s.notes[verses[i].id] : null,
                      footer: tab != 0
                          ? null
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (s.bookmarkTags[verses[i].id] ?? [])
                                        .map((v) => '#$v')
                                        .join('  '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: uiMuted(context),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => editBookmarkTags(
                                    context,
                                    s,
                                    [verses[i].id],
                                  ),
                                  child: Text(
                                    (s.bookmarkTags[verses[i].id] ?? []).isEmpty
                                        ? 'Add tags'
                                        : 'Edit tags',
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
}
