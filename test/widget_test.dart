import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_bible/data.dart';
import 'package:word_bible/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String state = '{}';
  final awakeCalls = <bool>[];
  setUpAll(() async {
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final entry in {
      'Inter': 'Inter.ttf',
      'Editorial': 'Lora.ttf',
      'Malayalam': 'NotoSerifMalayalam.ttf',
      'MalayalamSans': 'NotoSansMalayalam.ttf',
      'Manjari': 'Manjari.ttf',
      'Gayathri': 'Gayathri.ttf',
      'Chilanka': 'Chilanka.ttf',
      'BalooChettan2': 'BalooChettan2.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
    }
  });
  setUp(() {
    state = '{}';
    awakeCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(BibleStore.storage, (call) async {
          if (call.method == 'awake') {
            awakeCalls.add(call.arguments as bool);
            return null;
          }
          if (call.method == 'read') return state;
          if (call.method == 'write') {
            state = call.arguments as String;
            return true;
          }
          throw PlatformException(code: 'unexpected');
        });
  });
  test(
    'Complete corpus, real search, boundaries and state survive reload',
    () async {
      final s = BibleStore();
      await s.load();
      expect(s.all.length, 31098);
      expect(s.chapters.length, 1189);
      expect(bookNames.length, 66);
      expect(
        s.byId['GEN.1.1']!.text,
        'ആദിയിൽ ദൈവം ആകാശവും ഭൂമിയും സൃഷ്ടിച്ചു.',
      );
      expect(s.byId.containsKey('REV.22.21'), true);
      expect(s.search('John 3:16').single.id, 'JOH.3.16');
      expect(s.search('1 John 1:1').single.id, '1JO.1.1');
      expect(s.search('ദൈവം').length, greaterThan(100));
      expect(s.search('John 999:1'), isEmpty);
      s.go('GEN', 1);
      expect(s.adjacent(-1), false);
      s.go('REV', 22);
      expect(s.adjacent(1), false);
      s.go('JOH', 3, '16');
      s.bookmarks.add('JOH.3.16');
      s.highlights.add('PSA.23.1');
      s.notes['JOH.3.16'] = 'A reflection';
      s.theme = 2;
      s.fontSize = 28;
      s.fontFamily = 'Manjari';
      await s.persist();
      expect(jsonDecode(state)['book'], 'JOH');
      final restored = BibleStore();
      await restored.load();
      expect(restored.verse, '16');
      expect(restored.bookmarks, contains('JOH.3.16'));
      expect(restored.notes['JOH.3.16'], 'A reflection');
      expect(restored.theme, 2);
      expect(restored.fontSize, 28);
      expect(restored.fontFamily, 'Manjari');
    },
  );
  test(
    'Version 1 annotations and location upgrade without losing data',
    () async {
      state = jsonEncode({
        'book': 'JOH',
        'chapter': 3,
        'verse': '16',
        'bookmarks': ['JOH.3.16'],
        'highlights': ['PSA.23.1'],
        'notes': jsonEncode({'JOH.3.16': 'Existing note'}),
        'theme': 2,
        'fontSize': 24.0,
      });
      final s = BibleStore();
      await s.load();
      expect(s.book, 'JOH');
      expect(s.chapter, 3);
      expect(s.verse, '16');
      expect(s.bookmarks, contains('JOH.3.16'));
      expect(s.notes['JOH.3.16'], 'Existing note');
      expect(s.fontFamily, 'Malayalam');
      expect(s.theme, 2);
      await s.persist();
      final restored = BibleStore();
      await restored.load();
      expect(restored.notes['JOH.3.16'], 'Existing note');
    },
  );
  test(
    'Backup round trip merges annotations; malformed files preserve data',
    () async {
      final source = BibleStore();
      await source.load();
      source.bookmarks.add('JOH.3.16');
      source.highlights.add('PSA.23.1');
      source.highlightColors['PSA.23.1'] = 2;
      source.notes['JOH.3.16'] = 'A note';
      source.noteRanges['JOH.3.16'] = ['JOH.3.16'];
      source.tagBookmarks(['JOH.3.16'], ['Hope']);
      final backup = source.exportBackup();
      final target = BibleStore();
      await target.load();
      target.bookmarks.add('GEN.1.1');
      await target.restoreBackup(backup);
      expect(target.bookmarks, containsAll(['GEN.1.1', 'JOH.3.16']));
      expect(target.notes['JOH.3.16'], 'A note');
      expect(target.highlightColors['PSA.23.1'], 2);
      expect(target.bookmarkTags['JOH.3.16'], ['Hope']);
      target.renameTag('Hope', 'Faith');
      expect(target.bookmarkTags['JOH.3.16'], ['Faith']);
      target.deleteTag('Faith');
      expect(target.knownTags, isEmpty);
      final before = target.exportBackup();
      await expectLater(
        target.restoreBackup('{"format":"wrong"}'),
        throwsFormatException,
      );
      final damaged = jsonDecode(backup);
      damaged['data']['notes'] = '{"BAD":"x"}';
      await expectLater(
        target.restoreBackup(jsonEncode(damaged)),
        throwsFormatException,
      );
      expect(target.exportBackup(), before);
      target.malayalamNames = true;
      await target.persist();
      final restored = BibleStore();
      await restored.load();
      expect(restored.malayalamNames, isTrue);
      expect(restored.bookLabel('JOH'), malayalamBooks['JOH']);
      expect(restored.search('John 3:16').single.id, 'JOH.3.16');
      expect(restored.search('John').first.book, 'JOH');
      expect(
        restored.search('${malayalamBooks['JOH']} 3:16').single.id,
        'JOH.3.16',
      );
    },
  );

  test(
    'History keeps five local calendar days, deduplicates and survives reload',
    () async {
      var now = DateTime(2026, 11, 1, 9);
      final store = BibleStore(clock: () => now);
      await store.load();
      store.go('JOH', 3, '16');
      now = now.add(const Duration(hours: 1));
      store.go('JOH', 3, '16');
      expect(store.recentHistory.length, 1);
      now = DateTime(2026, 11, 2, 0, 1);
      store.go('JOH', 3, '16');
      expect(store.recentHistory.length, 2);
      now = DateTime(2026, 11, 5, 23, 59);
      store.go('PSA', 23, '1');
      expect(store.recentHistory.length, 3);
      await store.persist();
      final loaded = BibleStore(clock: () => now);
      await loaded.load();
      expect(loaded.recentHistory.map((v) => v.verseId), [
        'PSA.23.1',
        'JOH.3.16',
        'JOH.3.16',
      ]);
      now = DateTime(2026, 11, 6);
      expect(loaded.recentHistory.length, 2);
      now = DateTime(2026, 11, 10);
      expect(loaded.recentHistory, isEmpty);
    },
  );

  testWidgets(
    'Selected Malayalam font updates UI fallback and history reopens a verse',
    (tester) async {
      final store = BibleStore();
      await tester.runAsync(store.load);
      store.go('JOH', 3, '16');
      store.malayalamNames = true;
      await tester.pumpWidget(WordApp(store: store));
      await tester.pumpAndSettle();
      for (final family in ['Chilanka', 'BalooChettan2']) {
        store.fontFamily = family;
        store.changed();
        await tester.pumpAndSettle();
        final theme = tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!;
        expect(
          theme.textTheme.bodyMedium!.fontFamilyFallback,
          contains(family),
        );
        final context = tester.element(
          find.text('${malayalamBooks['JOH']} 3:16'),
        );
        expect(
          DefaultTextStyle.of(context).style.fontFamilyFallback,
          contains(family),
        );
      }
      await tester.tap(find.byTooltip('Reading history'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsNothing);
      expect(find.text('TODAY'), findsOneWidget);
      await expectLater(
        find.byType(ReadingHistory),
        matchesGoldenFile('screens/reading-history.png'),
      );
      await tester.tap(find.text('${malayalamBooks['JOH']} 3:16'));
      await tester.pumpAndSettle();
      expect(find.byType(Reader), findsOneWidget);
      expect(store.verse, '16');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('English library, search and reader navigation', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(s.theme),
        home: Home(store: s),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bible'), findsOneWidget);
    expect(find.text('Complete Bible · Available offline'), findsNothing);
    expect(find.text('SATHYAVEDAPUSTHAKAM'), findsNothing);
    await tester.tap(find.text('Search').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'John 3:16');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('John 3:16', skipOffstage: true).last, findsOneWidget);
    await tester.tap(find.text('John 3:16').last);
    await tester.pumpAndSettle();
    expect(find.text('യോഹന്നാൻ 3'), findsNWidgets(2));
    expect(find.byTooltip('Go to passage'), findsOneWidget);
    await tester.tap(find.byTooltip('Go to passage'));
    await tester.pumpAndSettle();
    expect(find.text('Passage'), findsOneWidget);
    expect(find.byType(PassageSheet), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    await dismissSheet(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Render library, reader and appearance at phone size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(s.theme),
          home: Home(store: s),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('screens/library.png'),
    );
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('screens/reader.png'),
    );
    await tester.tap(find.text('Aa'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('screens/appearance.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'Scroll hides both bars without shifting layout, fonts persist, wheels navigate',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(s.theme),
            home: Reader(store: s),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byKey(const ValueKey('readerScroll')));
      await tester.drag(
        find.byKey(const ValueKey('readerScroll')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerTopControls')),
            )
            .opacity,
        0,
      );
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerBottomControls')),
            )
            .opacity,
        0,
      );
      expect(tester.getSize(find.byKey(const ValueKey('readerScroll'))), size);
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('readerScroll')),
          )
          .controller!;
      final offset = scroll.offset;
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(offset, .1));
      expect(find.byKey(const ValueKey('selectionBar')), findsOneWidget);
      await tester.tap(find.byTooltip('Clear selection'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerTopControls')),
            )
            .opacity,
        1,
      );
      expect(find.byType(ReaderEdgeFade), findsOneWidget);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/reader-blur.png'),
      );
      await tester.tap(find.text('Aa'));
      await tester.pumpAndSettle();
      for (final family in ['MalayalamSans', 'Manjari', 'Gayathri']) {
        await tester.ensureVisible(find.byKey(ValueKey('font-$family')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('font-$family')));
        await tester.pumpAndSettle();
        expect(s.fontFamily, family);
        expect(jsonDecode(state)['fontFamily'], family);
      }
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/appearance-fonts.png'),
      );
      await dismissSheet(tester);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.textContaining(s.current.first.text).first)
            .style!
            .fontFamily,
        'Gayathri',
      );
      await tester.tap(find.byTooltip('Go to passage'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stage-0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'John'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chapter-3')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/passage-picker.png'),
      );
      await tester.tap(find.byKey(const ValueKey('verse-16')));
      await tester.pumpAndSettle();
      expect(find.byType(PassageSheet), findsNothing);

      expect(s.book, 'JOH');
      expect(s.chapter, 3);
      expect(s.verse, '16');
      final y = tester
          .getTopLeft(find.textContaining(s.byId['JOH.3.16']!.text).first)
          .dy;
      expect(y, greaterThanOrEqualTo(55));
      expect(y, lessThan(760));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  test(
    'Reading plans cover every intended chapter and new settings survive upgrade',
    () async {
      final s = BibleStore();
      await s.load();
      for (final p in readingPlans) {
        final days = [for (int d = 0; d < p.days; d++) s.planChapters(p, d)];
        expect(days.every((d) => d.isNotEmpty), true);
        final flat = days.expand((d) => d).toList();
        final expected = s.chapters.keys
            .where(
              (k) => p.books.isEmpty || p.books.contains(k.split('.').first),
            )
            .toList();
        expect(flat, expected);
        expect(flat.toSet().length, flat.length);
      }
      final p = readingPlans.first;
      s.activePlan = p.id;
      s.completePlanDay(p, 0, true);
      expect(s.nextPlanDay(p), 1);
      s.colorVerses(['PSA.23.1', 'PSA.23.2'], 4);
      s.bookmarkVerses(['PSA.23.1', 'PSA.23.2'], true);
      s.notes['PSA.23.1'] = 'Range note';
      s.noteRanges['PSA.23.1'] = ['PSA.23.1', 'PSA.23.2'];
      s.autoHide = false;
      s.keepAwake = true;
      s.haptics = false;

      s.defaultHighlight = 2;
      await s.persist();
      final restored = BibleStore();
      await restored.load();
      expect(restored.nextPlanDay(p), 1);
      expect(restored.highlightColors['PSA.23.2'], 4);
      expect(restored.noteRanges['PSA.23.1'], ['PSA.23.1', 'PSA.23.2']);
      expect(restored.autoHide, false);
      expect(restored.keepAwake, true);
      expect(restored.blurStrength, 18);
      restored.colorVerses(['PSA.23.1'], null);
      expect(restored.highlights.contains('PSA.23.1'), false);
      expect(
        passageLabel([
          s.byId['PSA.23.1']!,
          s.byId['PSA.23.2']!,
          s.byId['PSA.23.4']!,
        ]),
        'Psalms 23:1–2, 4',
      );
    },
  );
  testWidgets(
    'Multiple verses select before actions, batch color, bookmark and range note',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      s.haptics = false;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(s.theme),
            home: Reader(store: s),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> selectTwo() async {
        for (final v in s.current.take(2)) {
          await tester.tap(find.textContaining(v.text).first);
          await tester.pumpAndSettle();
        }
      }

      await selectTwo();
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('Clear color'), findsNothing);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/multi-selection.png'),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/selection-actions.png'),
      );
      await tester.tap(find.byTooltip('Pink highlight'));
      await tester.pumpAndSettle();
      expect(s.highlightColors['PSA.23.1'], 4);
      expect(s.highlightColors['PSA.23.2'], 4);
      await selectTwo();
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bookmark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save bookmark'));
      await tester.pumpAndSettle();
      expect(s.bookmarks, containsAll(['PSA.23.1', 'PSA.23.2']));
      await selectTwo();
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<TextField>(find.byType(TextField)).decoration!.border!
                as OutlineInputBorder)
            .borderRadius,
        BorderRadius.circular(20),
      );
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/note-editor.png'),
      );
      await tester.enterText(find.byType(TextField), 'Together');
      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(s.notes['PSA.23.1'], 'Together');
      expect(s.noteRanges['PSA.23.1'], ['PSA.23.1', 'PSA.23.2']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Real settings and reading plan start and completion update the hub',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(s.theme),
            home: Home(store: s),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue reading'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Text & layout'), findsOneWidget);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/settings.png'),
      );
      await tester.tap(find.text('Hide controls on scroll'));
      await tester.pumpAndSettle();
      expect(s.autoHide, false);
      expect(jsonDecode(state)['autoHide'], false);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The Gospels'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start plan'));
      await tester.pumpAndSettle();
      expect(s.activePlan, 'gospels30');
      expect(find.text('Matthew 1'), findsOneWidget);
      await tester.tap(find.text('Mark day complete'));
      await tester.pumpAndSettle();
      expect(s.nextPlanDay(readingPlans.first), 1);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Day 2 of 30'), findsOneWidget);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/active-plan.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Hidden bars leave no blur strip and screen-awake setting reaches Android channel',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      s.keepAwake = true;
      s.haptics = false;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(s.theme),
            home: Reader(store: s),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(awakeCalls, contains(true));
      await tester.drag(
        find.byKey(const ValueKey('readerScroll')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerEdgeBlur')),
            )
            .opacity,
        0,
      );
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerBottomControls')),
            )
            .opacity,
        0,
      );
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/reader-hidden.png'),
      );
      s.keepAwake = false;
      s.changed();
      await tester.pumpAndSettle();
      expect(awakeCalls.last, false);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'Custom plans validate, partition chapters, reload progress and preserve defaults',
    () async {
      final s = BibleStore();
      await s.load();
      final p = s.createPlan('John and James', 7, ['JOH', 'JAM']);
      expect(p.custom, true);
      expect(s.allPlans.length, 5);
      final flat = [for (int d = 0; d < p.days; d++) ...s.planChapters(p, d)];
      expect(flat.length, 26);
      expect(flat.toSet().length, 26);
      expect(flat.first, 'JOH.1');
      expect(flat.last, 'JAM.5');
      s.activePlan = p.id;
      s.completePlanDay(p, 0, true);
      s.theme = 2;
      s.changed();
      await s.persist();
      expect(jsonDecode(state).containsKey('blurStrength'), false);
      final restored = BibleStore();
      await restored.load();
      expect(restored.plan!.title, 'John and James');
      expect(restored.nextPlanDay(restored.plan!), 1);
      expect(restored.themeChanges.value, 2);
      expect(restored.blurStrength, 18);
      expect(() => s.createPlan('', 1, ['JOH']), throwsArgumentError);
      expect(() => s.createPlan('Invalid', 30, ['JOH']), throwsArgumentError);
      expect(() => s.createPlan('Empty', 1, []), throwsArgumentError);
      restored.deletePlan(p.id);
      expect(restored.customPlans, isEmpty);
      expect(restored.activePlan, '');
      expect(restored.allPlans.length, 4);
      state = jsonEncode({'blurStrength': 0});
      final legacy = BibleStore();
      await legacy.load();
      expect(legacy.blurStrength, 18);
    },
  );
  testWidgets(
    'Theme applies to the hub, settings, search, saved and passage sheets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: WordApp(store: s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Edge blur'), findsNothing);
      expect(find.byKey(const ValueKey('blurSetting')), findsNothing);
      await tester.tap(find.text('Text & layout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness,
        Brightness.dark,
      );
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/dark-appearance.png'),
      );
      await dismissSheet(tester);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.dark,
      );
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/dark-settings.png'),
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/dark-hub.png'),
      );
      await tester.tap(find.text('Search').first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/dark-search.png'),
      );
      await tester.tap(find.text('Saved').last);
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/dark-saved.png'),
      );
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Go to passage'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(PassageSheet))).brightness,
        Brightness.dark,
      );
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/dark-passage.png'),
      );
      await dismissSheet(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paper').last);
      await tester.pumpAndSettle();
      await dismissSheet(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close reader'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .surface,
        const Color(0xfff4eddf),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Create a custom plan through the UI while retaining the included plans',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(0),
            home: PlanCatalog(store: s),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Create plan'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('custom-title')),
        'My John plan',
      );
      await tester.enterText(find.byKey(const ValueKey('custom-days')), '7');
      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byType(PlanBooksSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'John');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'John'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/custom-plan.png'),
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(s.customPlans.single.books, ['JOH']);
      expect(s.customPlans.single.days, 7);
      expect(readingPlans.length, 4);
      await tester.tap(find.text('Start plan'));
      await tester.pumpAndSettle();
      expect(find.text('John 1'), findsOneWidget);
      await tester.tap(find.text('Mark day complete'));
      await tester.pumpAndSettle();
      expect(s.nextPlanDay(s.customPlans.single), 1);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Your plans'), findsOneWidget);
      expect(find.text('Included'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Directional scroll reveals controls and markings follow lines without boxes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      s.haptics = false;
      s.colorVerses(['PSA.23.1', 'PSA.23.2'], 2);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(0),
            home: Reader(store: s),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is ScriptureMarkPainter,
        ),
        findsNWidgets(2),
      );
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('screens/marker-highlights.png'),
      );
      await tester.drag(
        find.byKey(const ValueKey('readerScroll')),
        const Offset(0, -210),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerBottomControls')),
            )
            .opacity,
        0,
      );
      await tester.drag(
        find.byKey(const ValueKey('readerScroll')),
        const Offset(0, 70),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerBottomControls')),
            )
            .opacity,
        1,
      );
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('readerTopControls')),
            )
            .opacity,
        1,
      );
      expect(find.byType(ImageFiltered), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('Passage picker opens near the current long chapter and verse', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = BibleStore();
    await tester.runAsync(s.load);
    s.go('PSA', 119, '176');
    s.haptics = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Reader(store: s),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Go to passage'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chapter-119')), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('chapter-119')))
          .overlaps(tester.getRect(find.byType(PassageNumberGrid))),
      true,
    );
    await tester.tap(find.byKey(const ValueKey('stage-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('verse-176')), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('verse-176')))
          .overlaps(tester.getRect(find.byType(PassageNumberGrid))),
      true,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Large custom-plan day uses a bounded lazy chapter list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = BibleStore();
    await tester.runAsync(s.load);
    final plan = s.createPlan('All chapters', 1, bookNames.keys);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: PlanDetail(store: s, plan: plan),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start plan'));
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('plan-day-chapters')),
    );
    expect(
      (list.childrenDelegate as SliverChildBuilderDelegate).estimatedChildCount,
      1189,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('plan-day-chapters'))).height,
      lessThan(600),
    );
    expect(find.text('Mark day complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Short pages stay still when dragged', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const ContentScrollBehavior(),
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: const [SizedBox(height: 100, child: Text('Short page'))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.position.maxScrollExtent, 0);
    await tester.drag(find.byType(ListView), const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.offset, 0);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('Selecting verses preserves line wrapping and passage geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Reader(store: s),
      ),
    );
    await tester.pumpAndSettle();
    final first = find.textContaining(s.current.first.text).first;
    final next = find.textContaining(s.current[1].text).first;
    final size = tester.getSize(first);
    final nextTop = tester.getTopLeft(next);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(tester.getSize(first), size);
    expect(tester.getTopLeft(next), nextTop);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(next), nextTop);
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Cached hub updates when the reading location changes', (
    tester,
  ) async {
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Home(store: s),
      ),
    );
    await tester.pumpAndSettle();
    s.go('JOH', 3, '16');
    await tester.pumpAndSettle();
    expect(find.text('John 3:16'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Reader search replaces the automatic bookmark shortcut', (
    tester,
  ) async {
    final s = BibleStore();
    await tester.runAsync(s.load);
    s.go('JOH', 3, '16');
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Reader(store: s),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bookmark current verse'), findsNothing);
    expect(find.byTooltip('Search Bible'), findsOneWidget);
    expect(find.byKey(const ValueKey('verse-number-JOH.3.16')), findsOneWidget);
    await tester.tap(find.byTooltip('Search Bible'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsOneWidget);
    expect(s.bookmarks, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Passage handle expands the sheet without a cross button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Reader(store: s),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Go to passage'));
    await tester.pumpAndSettle();
    final sheet = find.byType(GlassPanel).last;
    final before = tester.getSize(sheet).height;
    expect(find.byTooltip('Close'), findsNothing);
    await tester.drag(find.text('Passage'), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(before, 1));
    await expectLater(
      find.byType(PassageSheet),
      matchesGoldenFile('screens/passage-expanded.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Highlight selection ring uses its own pigment color', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = BibleStore();
    await tester.runAsync(s.load);
    s.defaultHighlight = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: SettingsPage(store: s),
      ),
    );
    await tester.pumpAndSettle();
    final ring = tester.widget<Container>(
      find.byKey(const ValueKey('color-ring-1')),
    );
    final decoration = ring.decoration! as BoxDecoration;
    expect((decoration.border! as Border).top.color, highlightPalette[1]);
    await tester.scrollUntilVisible(
      find.text('About Bible'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Bible'));
    await tester.pumpAndSettle();
    expect(find.text('Version 2.3.0'), findsOneWidget);
    expect(find.text('Edition & licenses'), findsOneWidget);
    await expectLater(
      find.byType(SheetShell),
      matchesGoldenFile('screens/about.png'),
    );
    await tester.tap(find.text('Edition & licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  test(
    'Marker pigment covers the line behind the glyphs above the baseline',
    () async {
      const text = 'The Lord is my shepherd.';
      const style = TextStyle(fontFamily: 'Inter', fontSize: 20, height: 1.6);
      final painter = ScriptureMarkPainter(
        text: text,
        style: style,
        color: highlightPalette[0],
        selected: false,
        scaler: TextScaler.noScaling,
        direction: TextDirection.ltr,
      );
      final layout = TextPainter(
        text: const TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 300);
      final box = layout
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          .first;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      painter.paint(canvas, const Size(300, 100));
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 100);
      final bytes = (await image.toByteData())!;
      final y = (box.top + (box.bottom - box.top) * .35).round();
      int pigmented = 0;
      for (int x = 2; x < box.right.floor() - 2; x++) {
        if (bytes.getUint8((y * 300 + x) * 4 + 3) > 10) pigmented++;
      }
      expect(pigmented, greaterThan(80));
      image.dispose();
      picture.dispose();
      layout.dispose();
    },
  );
  testWidgets(
    'Passage picker remains usable with the keyboard on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(0),
          home: Reader(store: s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Go to passage'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'John 3:16');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'John 3:16'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Testament switching resets a scrolled list and removes picker arrow',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(2),
          home: Reader(store: s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Go to passage'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      await tester.tap(find.byKey(const ValueKey('stage-0')));
      await tester.pumpAndSettle();
      final list = find
          .descendant(
            of: find.byType(PassageSheet),
            matching: find.byType(ListView),
          )
          .last;
      await tester.drag(list, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Testament'));
      await tester.pumpAndSettle();
      expect(find.text('Matthew'), findsOneWidget);
      await tester.tap(find.text('Old Testament'));
      await tester.pumpAndSettle();
      expect(find.text('Genesis'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('One pill slides continuously between fixed testament segments', (
    tester,
  ) async {
    bool selected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, set) => PillSegments<bool>(
                  items: const {false: 'Old Testament', true: 'New Testament'},
                  selected: selected,
                  onChanged: (v) => set(() => selected = v),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pill = find.descendant(
      of: find.byKey(const ValueKey('segment-indicator')),
      matching: find.byType(DecoratedBox),
    );
    expect(pill, findsOneWidget);
    final start = tester.getCenter(pill).dx;
    final size = tester.getSize(pill);
    await tester.tap(find.text('New Testament'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    final middle = tester.getCenter(pill).dx;
    expect(middle, greaterThan(start));
    await tester.pumpAndSettle();
    expect(tester.getCenter(pill).dx, greaterThan(middle));
    expect(tester.getSize(pill), size);
    await tester.tap(find.text('Old Testament'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    final interrupted = tester.getCenter(pill).dx;
    await tester.tap(find.text('New Testament'));
    await tester.pump();
    expect(tester.getCenter(pill).dx, closeTo(interrupted, .01));
    await tester.pumpAndSettle();
    expect(tester.getSize(pill), size);
    expect(tester.takeException(), isNull);
    expect(
      HSVColor.fromColor(appTheme(0).colorScheme.primary).hue,
      closeTo(HSVColor.fromColor(appTheme(2).colorScheme.primary).hue, 2),
    );
    expect(
      appTheme(1).colorScheme.primary,
      isNot(appTheme(0).colorScheme.primary),
    );
  });
  test(
    'Bookmark tags normalize, persist and retain a reusable suggestion history',
    () async {
      final s = BibleStore();
      await s.load();
      s.tagBookmarks(['PSA.23.1'], [' Faith ', 'faith', 'Hope']);
      expect(s.bookmarkTags['PSA.23.1'], ['Faith', 'Hope']);
      final malayalam = List.filled(4, 'വിശ്വാസം').join(' ');
      s.tagBookmarks(['PSA.23.2'], [malayalam]);
      await s.persist();
      final loaded = BibleStore();
      await loaded.load();
      expect(loaded.bookmarkTags['PSA.23.2'], [malayalam]);
      loaded.bookmarkVerses(['PSA.23.1'], false);
      expect(loaded.bookmarkTags.containsKey('PSA.23.1'), false);
      expect(loaded.knownTags, containsAll(['Faith', 'Hope']));
    },
  );
  testWidgets('Tag editor suggests reusable tags and Saved filters bookmarks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = BibleStore();
    await tester.runAsync(s.load);
    s.tagBookmarks(['PSA.23.1'], ['Faith']);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => editBookmarkTags(context, s, ['PSA.23.2']),
              child: const Text('Tag bookmark'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tag bookmark'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Faith'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('tag-input')), 'Hope');
    await tester.tap(find.byTooltip('Add tag'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BookmarkTagsSheet),
      matchesGoldenFile('screens/bookmark-tags.png'),
    );
    await tester.tap(find.text('Save bookmark'));
    await tester.pumpAndSettle();
    expect(s.bookmarkTags['PSA.23.2'], ['Hope']);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Scaffold(
          body: SafeArea(child: SavedPage(store: s)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Faith'));
    await tester.pumpAndSettle();
    expect(find.text('Psalms 23:1'), findsOneWidget);
    expect(find.text('Psalms 23:2'), findsNothing);
    expect(find.byType(PillSegments<int>), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('screens/tag-filter.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  test(
    'Copied passages contain verses and reference without publishing metadata',
    () {
      final verses = [const Verse('PSA', 23, '1', 'യഹോവ എന്റെ ഇടയനാകുന്നു;')];
      final result = copyPassage(verses);
      expect(result, '1 യഹോവ എന്റെ ഇടയനാകുന്നു;\nPsalms 23:1');
      expect(result.contains('https'), false);
      expect(result.contains('Foundation'), false);
    },
  );
  testWidgets('Reader floating controls enable actual backdrop blur', (
    tester,
  ) async {
    final s = BibleStore();
    await tester.runAsync(s.load);
    s.theme = 2;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(2),
        home: Reader(store: s),
      ),
    );
    await tester.pumpAndSettle();
    final filters = tester
        .widgetList<BackdropFilter>(find.byType(BackdropFilter))
        .where((w) => w.enabled);
    expect(filters.length, 4);
    final dock = tester.widget<FloatingGlass>(
      find.byKey(const ValueKey('reader-bottom-glass')),
    );
    expect(dock.blur, isTrue);
    expect(dock.radius, 28);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'Appearance preview stays fixed while controls scroll and updates live',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final s = BibleStore();
      await tester.runAsync(s.load);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(0),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => appearance(context, s),
                child: const Text('Open appearance'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open appearance'));
      await tester.pumpAndSettle();
      final backdrop = tester.widget<BackdropFilter>(
        find.byKey(const ValueKey('appearance-backdrop')),
      );
      expect(backdrop.enabled, isTrue);
      final preview = find.byKey(const ValueKey('typeface-preview'));
      final initial = tester.getRect(preview);
      final oldSize = s.fontSize;
      await tester.tap(find.byTooltip('Increase text size'));
      await tester.pumpAndSettle();
      expect(s.fontSize, oldSize + 1);
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('live-preview-text')),
      );
      expect(text.style!.fontSize, s.fontSize);
      expect(jsonDecode(state)['fontSize'], s.fontSize);
      await tester.drag(
        find.byKey(const ValueKey('appearance-controls')),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(preview), initial);
      await expectLater(
        find.byType(ReadingAppearance),
        matchesGoldenFile('screens/appearance-compact.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Scroll edges stretch without moving beyond bounds, swipe speed controls distance',
    (tester) async {
      Future<ScrollController> page(double height) async {
        final controller = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            scrollBehavior: const ContentScrollBehavior(),
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: SizedBox(height: height, width: 200),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return controller;
      }

      final short = await page(50);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 120),
      );
      expect(short.offset, 0);
      final long = await page(6000);
      final gesture = await tester.startGesture(const Offset(100, 150));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      expect(long.offset, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(long.offset, closeTo(0, .1));
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
        500,
      );
      await tester.pumpAndSettle();
      final slow = long.offset;
      long.jumpTo(0);
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
        1800,
      );
      await tester.pumpAndSettle();
      expect(long.offset, greaterThan(slow));
      long.jumpTo(long.position.maxScrollExtent);
      final end = long.offset;
      for (int i = 0; i < 3; i++) {
        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, -350),
          2200,
        );
        await tester.pumpAndSettle();
        expect(long.offset, end);
        expect(long.position.outOfRange, false);
      }
      final pull = await tester.startGesture(const Offset(100, 450));
      await pull.moveBy(const Offset(0, -200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(long.offset, end);
      final strengths = tester.widgetList<StretchEffect>(
        find.byType(StretchEffect),
      );
      expect(strengths.any((w) => w.stretchStrength != 0), true);
      expect(strengths.every((w) => w.stretchStrength.abs() < .04), true);
      await pull.up();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      short.dispose();
      long.dispose();
    },
  );
  testWidgets('Dashboard title and settings scroll naturally with the page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('home-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(0),
          scrollBehavior: const ContentScrollBehavior(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 720),
              padding: EdgeInsets.only(top: 30),
            ),
            child: Home(store: s),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.getRect(find.text('Bible'));
    final settings = tester.getRect(find.byTooltip('Settings'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Bible')).top, lessThan(title.top));
    expect(
      tester.getRect(find.byTooltip('Settings')).top,
      lessThan(settings.top),
    );
    expect(title.top, greaterThan(30));
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(find.text('Bible').hitTestable(), findsNothing);
    expect(find.byTooltip('Settings').hitTestable(), findsNothing);
    await expectLater(
      find.byKey(const ValueKey('home-capture')),
      matchesGoldenFile('screens/home-scrolled-glass.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'Startup opens as soon as data is ready without branding or delay',
    (tester) async {
      final s = PausedBibleStore();
      await tester.pumpWidget(WordApp(store: s));
      await tester.pump();
      expect(find.byType(Home), findsNothing);
      expect(find.byType(BibleMark), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.runAsync(s.prepare);
      s.gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(Home), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Dashboard action labels have no decorative link arrows', (
    tester,
  ) async {
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Home(store: s),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Read day 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(FilledButton, 'Read day 1'),
        matching: find.byType(AppIcon),
      ),
      findsNothing,
    );
    expect(find.textContaining('↗'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Status filter mixes a gentle blur linearly back to exact source',
    (tester) async {
      final results = await tester.runAsync(() async {
        final program = await ui.FragmentProgram.fromAsset(
          'shaders/status_veil.frag',
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        for (var x = 0; x < 200; x += 2) {
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), 0, 2, 120),
            Paint()..color = x % 4 == 0 ? Colors.black : Colors.white,
          );
        }
        final picture = recorder.endRecording();
        final input = await picture.toImage(200, 120);
        picture.dispose();
        final shader = program.fragmentShader()
          ..setFloat(0, 200)
          ..setFloat(1, 120)
          ..setFloat(2, 42)
          ..setFloat(3, .75)
          ..setImageSampler(0, input);
        final outputRecorder = ui.PictureRecorder();
        Canvas(outputRecorder).drawRect(
          const Rect.fromLTWH(0, 0, 200, 120),
          Paint()..shader = shader,
        );
        final outputPicture = outputRecorder.endRecording();
        final output = await outputPicture.toImage(200, 120);
        final bytes = await output.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        output.dispose();
        outputPicture.dispose();
        shader.dispose();
        input.dispose();
        return bytes!;
      });
      int red(int x, int y) => results!.getUint8((y * 200 + x) * 4);
      int contrast(int y) => (red(102, y) - red(100, y)).abs();
      expect(contrast(2), lessThan(220));
      expect(contrast(22), greaterThan(contrast(2)));
      expect(contrast(41), greaterThan(contrast(22)));
      expect(contrast(42), 255);
      expect((red(102, 41) - red(102, 42)).abs(), lessThan(5));
      expect((red(100, 41) - red(100, 42)).abs(), lessThan(5));
      // Source is preserved exactly everywhere below the status-bar feather.
      for (var y = 42; y < 120; y++) {
        expect(red(100, y), 0);
        expect(red(102, y), 255);
      }
    },
  );

  testWidgets('Status veil is confined to the system inset and ignores input', (
    tester,
  ) async {
    for (final inset in [0.0, 30.0, 44.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(top: inset)),
            child: const Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, child: StatusBarVeil()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(find.byType(StatusBarVeil)).height,
        inset == 0 ? 0 : inset + 12,
      );
      expect(
        find.byType(BackdropFilter),
        findsNothing,
      ); // Skia fallback never clips a blur.
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Reader chrome motion preserves the scripture widget subtree', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Reader(store: s),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.widget(find.byType(MarkedScripture).first);
    await tester.drag(
      find.byKey(const ValueKey('readerScroll')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(tester.widget(find.byType(MarkedScripture).first), same(before));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('readerTopControls')),
          )
          .opacity,
      0,
    );
    await tester.drag(
      find.byKey(const ValueKey('readerScroll')),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(tester.widget(find.byType(MarkedScripture).first), same(before));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('readerTopControls')),
          )
          .opacity,
      1,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Home loads tabs lazily and preserves search when switching', (
    tester,
  ) async {
    final s = BibleStore();
    await tester.runAsync(s.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(0),
        home: Home(store: s),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage, skipOffstage: false), findsNothing);
    expect(find.byType(SavedPage, skipOffstage: false), findsNothing);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'John 3:16');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'John 3:16',
    );
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Search scripture'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reduced motion disables pill animation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Material(
            child: PillSegments<int>(
              items: const {0: 'One', 1: 'Two'},
              selected: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
      Duration.zero,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cover press releases on cancel and respects reduced motion', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(
              body: Center(
                child: PressScale(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: ColoredBox(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final target = find.byType(PressScale);
      final before = tester.getRect(target);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pumpAndSettle();
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, reduced ? 1 : .975);
      expect(tester.getRect(target), before);
      if (reduced) expect(scale.duration, Duration.zero);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Main screens fit a compact phone with larger system text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = BibleStore();
    await tester.runAsync(s.load);
    for (final mode in [0, 1, 2]) {
      s.theme = mode;
      for (final page in <Widget>[
        Home(store: s),
        SettingsPage(store: s),
        PlanCatalog(store: s),
        SavedPage(store: s),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(mode),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.35),
              ),
              child: Material(child: page),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> dismissSheet(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

class PausedBibleStore extends BibleStore {
  final gate = Completer<void>();
  @override
  Future<void> load() => gate.future;
  Future<void> prepare() => super.load();
}
