import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const readingFonts = <String, String>{
  'Malayalam': 'Noto Serif',
  'MalayalamSans': 'Noto Sans',
  'Manjari': 'Manjari',
  'Gayathri': 'Gayathri',
  'Chilanka': 'Chilanka',
  'BalooChettan2': 'Baloo Chettan 2',
};

const bookNames = <String, String>{
  'GEN': 'Genesis',
  'EXO': 'Exodus',
  'LEV': 'Leviticus',
  'NUM': 'Numbers',
  'DEU': 'Deuteronomy',
  'JOS': 'Joshua',
  'JDG': 'Judges',
  'RUT': 'Ruth',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Kings',
  '2KI': '2 Kings',
  '1CH': '1 Chronicles',
  '2CH': '2 Chronicles',
  'EZR': 'Ezra',
  'NEH': 'Nehemiah',
  'EST': 'Esther',
  'JOB': 'Job',
  'PSA': 'Psalms',
  'PRO': 'Proverbs',
  'ECC': 'Ecclesiastes',
  'SOL': 'Song of Solomon',
  'ISA': 'Isaiah',
  'JER': 'Jeremiah',
  'LAM': 'Lamentations',
  'EZE': 'Ezekiel',
  'DAN': 'Daniel',
  'HOS': 'Hosea',
  'JOE': 'Joel',
  'AMO': 'Amos',
  'OBA': 'Obadiah',
  'JON': 'Jonah',
  'MIC': 'Micah',
  'NAH': 'Nahum',
  'HAB': 'Habakkuk',
  'ZEP': 'Zephaniah',
  'HAG': 'Haggai',
  'ZEC': 'Zechariah',
  'MAL': 'Malachi',
  'MAT': 'Matthew',
  'MAR': 'Mark',
  'LUK': 'Luke',
  'JOH': 'John',
  'ACT': 'Acts',
  'ROM': 'Romans',
  '1CO': '1 Corinthians',
  '2CO': '2 Corinthians',
  'GAL': 'Galatians',
  'EPH': 'Ephesians',
  'PHI': 'Philippians',
  'COL': 'Colossians',
  '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians',
  '1TI': '1 Timothy',
  '2TI': '2 Timothy',
  'TIT': 'Titus',
  'PHM': 'Philemon',
  'HEB': 'Hebrews',
  'JAM': 'James',
  '1PE': '1 Peter',
  '2PE': '2 Peter',
  '1JO': '1 John',
  '2JO': '2 John',
  '3JO': '3 John',
  'JUD': 'Jude',
  'REV': 'Revelation',
};

const malayalamBooks = <String, String>{
  'GEN': 'ഉല്പത്തി',
  'EXO': 'പുറപ്പാട്',
  'LEV': 'ലേവ്യപുസ്തകം',
  'NUM': 'സംഖ്യാപുസ്തകം',
  'DEU': 'ആവർത്തനപുസ്തകം',
  'JOS': 'യോശുവ',
  'JDG': 'ന്യായാധിപന്മാർ',
  'RUT': 'രൂത്ത്',
  '1SA': '1 ശമൂവേൽ',
  '2SA': '2 ശമൂവേൽ',
  '1KI': '1 രാജാക്കന്മാർ',
  '2KI': '2 രാജാക്കന്മാർ',
  '1CH': '1 ദിനവൃത്താന്തം',
  '2CH': '2 ദിനവൃത്താന്തം',
  'EZR': 'എസ്രാ',
  'NEH': 'നെഹെമ്യാവ്',
  'EST': 'എസ്ഥേർ',
  'JOB': 'ഇയ്യോബ്',
  'PSA': 'സങ്കീർത്തനങ്ങൾ',
  'PRO': 'സദൃശ്യവാക്യങ്ങൾ',
  'ECC': 'സഭാപ്രസംഗി',
  'SOL': 'ഉത്തമഗീതം',
  'ISA': 'യെശയ്യാവ്',
  'JER': 'യിരെമ്യാവ്',
  'LAM': 'വിലാപങ്ങൾ',
  'EZE': 'യെഹെസ്കേൽ',
  'DAN': 'ദാനീയേൽ',
  'HOS': 'ഹോശേയ',
  'JOE': 'യോവേൽ',
  'AMO': 'ആമോസ്',
  'OBA': 'ഓബദ്യാവ്',
  'JON': 'യോനാ',
  'MIC': 'മീഖാ',
  'NAH': 'നഹൂം',
  'HAB': 'ഹബക്കൂക്ക്',
  'ZEP': 'സെഫന്യാവ്',
  'HAG': 'ഹഗ്ഗായി',
  'ZEC': 'സെഖര്യാവ്',
  'MAL': 'മലാഖി',
  'MAT': 'മത്തായി',
  'MAR': 'മർക്കൊസ്',
  'LUK': 'ലൂക്കൊസ്',
  'JOH': 'യോഹന്നാൻ',
  'ACT': 'അപ്പൊസ്തലപ്രവൃത്തികൾ',
  'ROM': 'റോമർ',
  '1CO': '1 കൊരിന്ത്യർ',
  '2CO': '2 കൊരിന്ത്യർ',
  'GAL': 'ഗലാത്യർ',
  'EPH': 'എഫെസ്യർ',
  'PHI': 'ഫിലിപ്പിയർ',
  'COL': 'കൊലൊസ്സ്യർ',
  '1TH': '1 തെസ്സലൊനീക്യർ',
  '2TH': '2 തെസ്സലൊനീക്യർ',
  '1TI': '1 തിമൊഥെയൊസ്',
  '2TI': '2 തിമൊഥെയൊസ്',
  'TIT': 'തീത്തൊസ്',
  'PHM': 'ഫിലേമോൻ',
  'HEB': 'എബ്രായർ',
  'JAM': 'യാക്കോബ്',
  '1PE': '1 പത്രൊസ്',
  '2PE': '2 പത്രൊസ്',
  '1JO': '1 യോഹന്നാൻ',
  '2JO': '2 യോഹന്നാൻ',
  '3JO': '3 യോഹന്നാൻ',
  'JUD': 'യൂദാ',
  'REV': 'വെളിപ്പാട്',
};

class Verse {
  final String book, number, text;
  final int chapter;
  const Verse(this.book, this.chapter, this.number, this.text);
  String get id => '$book.$chapter.$number';
  String get reference => '${bookNames[book]} $chapter:$number';
}

List<Verse> parseBible(String raw) {
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final b in data.entries)
      for (final c in (b.value as Map<String, dynamic>).entries)
        for (final v in c.value as List)
          Verse(b.key, int.parse(c.key), v['v'] as String, v['t'] as String),
  ];
}

class _BibleCorpus {
  final List<Verse> all;
  final Map<String, List<Verse>> chapters;
  final Map<String, Verse> byId;
  final List<String> searchTexts;
  _BibleCorpus(this.all, this.chapters, this.byId, this.searchTexts);
}

_BibleCorpus _parseAndIndexBible(String raw) {
  final all = parseBible(raw);
  final chapters = <String, List<Verse>>{};
  final byId = <String, Verse>{};
  for (final v in all) {
    chapters.putIfAbsent('${v.book}.${v.chapter}', () => []).add(v);
    byId[v.id] = v;
  }
  return _BibleCorpus(
    all,
    chapters,
    byId,
    all.map((v) => v.text.toLowerCase()).toList(),
  );
}

class VerseVisit {
  final String verseId;
  final DateTime visitedAt;
  const VerseVisit(this.verseId, this.visitedAt);
}

class BibleStore extends ChangeNotifier {
  final DateTime Function() clock;
  BibleStore({DateTime Function()? clock}) : clock = clock ?? DateTime.now;
  final List<VerseVisit> _history = [];
  DateTime _day(DateTime date) =>
      DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day);
  List<VerseVisit> get recentHistory {
    final now = clock();
    final today = _day(now);
    final cutoff = DateTime(today.year, today.month, today.day - 4);
    _history.removeWhere(
      (v) =>
          v.visitedAt.isBefore(cutoff) ||
          v.visitedAt.isAfter(now) ||
          !byId.containsKey(v.verseId),
    );
    return List.unmodifiable(_history.reversed);
  }

  void recordVisit() {
    final id = '$book.$chapter.$verse';
    if (!byId.containsKey(id)) return;
    final now = clock();
    recentHistory;
    _history.removeWhere(
      (v) => v.verseId == id && _day(v.visitedAt) == _day(now),
    );
    _history.add(VerseVisit(id, now));
  }

  static const storage = MethodChannel('word.bible/storage');
  List<Verse> all = [];
  List<String> _searchTexts = [];
  final Map<String, int> _chapterCounts = {};
  final Map<String, List<Verse>> chapters = {};
  final Map<String, Verse> byId = {};
  final Map<String, int> verseOrder = {};
  Set<String> bookmarks = {}, highlights = {};
  Map<String, String> notes = {};
  Map<String, List<String>> bookmarkTags = {};
  Set<String> tagLibrary = {};
  List<String> get knownTags =>
      ({...tagLibrary, ...bookmarkTags.values.expand((v) => v)}.toList()
        ..sort());
  void tagBookmarks(Iterable<String> ids, Iterable<String> tags) {
    final cleaned = <String>[];
    for (final raw in tags) {
      final t = raw.trim().replaceAll(RegExp(r"\s+"), " ");
      if (t.isNotEmpty &&
          t.characters.length <= 32 &&
          !cleaned.any((v) => v.toLowerCase() == t.toLowerCase())) {
        cleaned.add(
          knownTags
                  .where((v) => v.toLowerCase() == t.toLowerCase())
                  .firstOrNull ??
              t,
        );
      }
    }
    for (final id in ids.where(byId.containsKey)) {
      bookmarks.add(id);
      bookmarkTags[id] = List.of(cleaned);
    }
    tagLibrary.addAll(cleaned);
    changed();
  }

  Map<String, int> highlightColors = {};
  Map<String, List<String>> noteRanges = {};
  Map<String, Set<int>> planCompleted = {};
  String activePlan = '';
  bool autoHide = true, haptics = true, keepAwake = false;
  static const double fixedBlur = 18;
  double get blurStrength => fixedBlur;
  final themeChanges = ValueNotifier<int>(0);
  final appearanceChanges = ValueNotifier<(int, String)>((0, 'Malayalam'));
  final List<ReadingPlan> customPlans = [];
  List<ReadingPlan> get allPlans => [...readingPlans, ...customPlans];
  int defaultHighlight = 0;
  String book = 'PSA', verse = '1';
  String fontFamily = 'Malayalam';
  int chapter = 23, theme = 0;
  double fontSize = 20, lineHeight = 1.9;
  bool numbers = true;
  bool malayalamNames = false;
  String verseLabel(Verse verse) =>
      '${bookLabel(verse.book)} ${verse.chapter}:${verse.number}';
  String bookLabel(String code) =>
      malayalamNames ? malayalamBooks[code]! : bookNames[code]!;
  Future<void> load() async {
    final prefs =
        jsonDecode(await storage.invokeMethod<String>('read') ?? '{}')
            as Map<String, dynamic>;
    theme = ((prefs['theme'] as num?)?.toInt() ?? 0).clamp(0, 2);
    themeChanges.value = theme;
    // Apply saved appearance before corpus parsing so dark-mode startup stays dark.
    if (readingFonts.containsKey(prefs['fontFamily'])) {
      fontFamily = prefs['fontFamily'] as String;
    }
    appearanceChanges.value = (theme, fontFamily);
    final corpus = await compute(
      _parseAndIndexBible,
      await rootBundle.loadString('assets/bible.json'),
    );
    all = corpus.all;
    _searchTexts = corpus.searchTexts;
    for (final key in corpus.chapters.keys) {
      final code = key.split('.').first;
      _chapterCounts.update(code, (n) => n + 1, ifAbsent: () => 1);
    }
    chapters.addAll(corpus.chapters);
    byId.addAll(corpus.byId);
    verseOrder.addEntries(
      all.asMap().entries.map((e) => MapEntry(e.value.id, e.key)),
    );
    for (final entry
        in prefs['history'] is List ? prefs['history'] as List : const []) {
      if (entry is! Map ||
          entry['verse'] is! String ||
          entry['at'] is! String) {
        continue;
      }
      final date = DateTime.tryParse(entry['at']);
      if (date != null && byId.containsKey(entry['verse'])) {
        _history.add(VerseVisit(entry['verse'], date.toLocal()));
      }
    }
    _history.sort((a, b) => a.visitedAt.compareTo(b.visitedAt));
    recentHistory;
    bookmarks = (prefs['bookmarks'] ?? [])
        .cast<String>()
        .where(byId.containsKey)
        .toSet();
    final rawTags = prefs['bookmarkTags'];
    if (rawTags is Map) {
      for (final e in rawTags.entries) {
        if (bookmarks.contains(e.key) && e.value is List) {
          bookmarkTags[e.key.toString()] = (e.value as List)
              .whereType<String>()
              .toList();
        }
      }
    }
    tagLibrary = (prefs['tagLibrary'] as List? ?? [])
        .whereType<String>()
        .toSet();
    highlights = (prefs['highlights'] ?? [])
        .cast<String>()
        .where(byId.containsKey)
        .toSet();
    final rawNotes = jsonDecode(prefs['notes'] ?? '{}') as Map<String, dynamic>;
    notes = rawNotes.map((k, v) => MapEntry(k, v.toString()));
    final b = prefs['book'] ?? book;
    final c = prefs['chapter'] ?? chapter;
    if (chapters.containsKey('$b.$c')) {
      book = b;
      chapter = c;
    }
    verse = prefs['verse'] ?? '1';
    theme = ((prefs['theme'] as num?)?.toInt() ?? 0).clamp(0, 2);
    fontSize = ((prefs['fontSize'] as num?)?.toDouble() ?? 20).clamp(16, 34);
    lineHeight = ((prefs['lineHeight'] as num?)?.toDouble() ?? 1.9).clamp(
      1.5,
      2.3,
    );
    numbers = prefs['numbers'] ?? true;
    malayalamNames = prefs['malayalamNames'] == true;
    final savedFont = prefs['fontFamily'];
    if (readingFonts.containsKey(savedFont)) fontFamily = savedFont;
    appearanceChanges.value = (theme, fontFamily);
    final colors = prefs['highlightColors'] as Map<String, dynamic>? ?? {};
    highlightColors = {
      for (final id in highlights)
        id: ((colors[id] as num?)?.toInt() ?? 3).clamp(0, 5),
    };
    final ranges = prefs['noteRanges'] as Map<String, dynamic>? ?? {};
    noteRanges = {
      for (final e in ranges.entries)
        if (notes.containsKey(e.key))
          e.key: (e.value as List)
              .cast<String>()
              .where(byId.containsKey)
              .toList(),
    };
    for (final item in prefs['customPlans'] as List? ?? []) {
      if (item is! Map) continue;
      final id = item['id'], title = item['title'], days = item['days'];
      final books = (item['books'] as List? ?? [])
          .whereType<String>()
          .where(bookNames.containsKey)
          .toSet();
      final chapterCount = chapters.keys
          .where((k) => books.contains(k.split('.').first))
          .length;
      if (id is String &&
          id.startsWith('custom_') &&
          title is String &&
          title.trim().isNotEmpty &&
          days is int &&
          days > 0 &&
          days <= chapterCount &&
          !customPlans.any((p) => p.id == id)) {
        customPlans.add(
          ReadingPlan(
            id,
            title.trim(),
            '',
            days,
            bookNames.keys.where(books.contains).toList(),
            custom: true,
          ),
        );
      }
    }
    final progress = prefs['planCompleted'] as Map<String, dynamic>? ?? {};
    planCompleted = {
      for (final e in progress.entries)
        if (allPlans.any((p) => p.id == e.key))
          e.key: (e.value as List)
              .cast<int>()
              .where(
                (d) =>
                    d >= 0 &&
                    d < allPlans.firstWhere((p) => p.id == e.key).days,
              )
              .toSet(),
    };
    activePlan = prefs['activePlan'] as String? ?? '';
    if (!allPlans.any((p) => p.id == activePlan)) activePlan = '';
    autoHide = prefs['autoHide'] as bool? ?? true;
    haptics = prefs['haptics'] as bool? ?? true;
    keepAwake = prefs['keepAwake'] as bool? ?? false;
    defaultHighlight = ((prefs['defaultHighlight'] as num?)?.toInt() ?? 0)
        .clamp(0, 5);
  }

  List<Verse> get current => chapters['$book.$chapter']!;
  String get location => '${bookLabel(book)} $chapter';
  int count(String b) => _chapterCounts[b] ?? 0;
  Map<String, dynamic> get stateData => {
    'history': [
      for (final visit in recentHistory.reversed)
        {
          'verse': visit.verseId,
          'at': visit.visitedAt.toUtc().toIso8601String(),
        },
    ],
    'bookmarks': bookmarks.toList(),
    'bookmarkTags': bookmarkTags,
    'tagLibrary': tagLibrary.toList(),
    'highlights': highlights.toList(),
    'notes': jsonEncode(notes),
    'book': book,
    'chapter': chapter,
    'verse': verse,
    'theme': theme,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'numbers': numbers,
    'malayalamNames': malayalamNames,
    'fontFamily': fontFamily,
    'highlightColors': highlightColors,
    'noteRanges': noteRanges,
    'activePlan': activePlan,
    'planCompleted': planCompleted.map((k, v) => MapEntry(k, v.toList())),
    'autoHide': autoHide,
    'haptics': haptics,
    'keepAwake': keepAwake,
    'customPlans': [
      for (final p in customPlans)
        {'id': p.id, 'title': p.title, 'days': p.days, 'books': p.books},
    ],
    'defaultHighlight': defaultHighlight,
  };
  Future<void> persist() async {
    final ok = await storage.invokeMethod<bool>('write', jsonEncode(stateData));
    if (ok != true) throw StateError('Could not save changes on this device.');
  }

  String exportBackup() => jsonEncode({
    'format': 'word-bible-backup',
    'version': 1,
    'data': stateData,
  });

  Future<void> restoreBackup(String source) async {
    final envelope = jsonDecode(source);
    if (envelope is! Map ||
        envelope['format'] != 'word-bible-backup' ||
        envelope['version'] != 1 ||
        envelope['data'] is! Map) {
      {
        throw const FormatException('Choose a Bible backup file (version 1).');
      }
    }
    final data = envelope['data'] as Map;
    Set<String> ids(String key) {
      final list = data[key];
      if (list is! List ||
          list.any((v) => v is! String || !byId.containsKey(v))) {
        throw FormatException('Invalid $key in backup.');
      }
      return list.cast<String>().toSet();
    }

    final importedBookmarks = ids('bookmarks'),
        importedHighlights = ids('highlights');
    final importedNotes = jsonDecode(data['notes'] as String);
    if (importedNotes is! Map ||
        importedNotes.entries.any(
          (e) => !byId.containsKey(e.key) || e.value is! String,
        )) {
      throw const FormatException('Invalid notes.');
    }
    final tags = data['bookmarkTags'];
    final library = data['tagLibrary'];
    final colors = data['highlightColors'];
    final ranges = data['noteRanges'];
    if (tags is! Map ||
        library is! List ||
        colors is! Map ||
        ranges is! Map ||
        library.any((t) => t is! String || t.length > 128) ||
        tags.entries.any(
          (e) =>
              !byId.containsKey(e.key) ||
              e.value is! List ||
              (e.value as List).any((t) => t is! String || t.length > 128),
        ) ||
        colors.entries.any(
          (e) =>
              !byId.containsKey(e.key) ||
              e.value is! int ||
              e.value < 0 ||
              e.value > 5,
        ) ||
        ranges.entries.any(
          (e) =>
              !byId.containsKey(e.key) ||
              e.value is! List ||
              (e.value as List).any(
                (v) => v is! String || !byId.containsKey(v),
              ),
        )) {
      throw const FormatException('Invalid annotations.');
    }
    final oldBookmarks = bookmarks,
        oldHighlights = highlights,
        oldNotes = notes,
        oldTags = bookmarkTags,
        oldLibrary = tagLibrary,
        oldColors = highlightColors,
        oldRanges = noteRanges;
    bookmarks = {...bookmarks, ...importedBookmarks};
    highlights = {...highlights, ...importedHighlights};
    notes = {...notes, ...importedNotes.cast<String, String>()};
    bookmarkTags = {
      ...bookmarkTags,
      for (final e in tags.entries)
        e.key as String: (e.value as List).cast<String>(),
    };
    tagLibrary = {...tagLibrary, ...library.cast<String>()};
    highlightColors = {...highlightColors, ...colors.cast<String, int>()};
    noteRanges = {
      ...noteRanges,
      for (final e in ranges.entries)
        e.key as String: (e.value as List).cast<String>(),
    };
    try {
      await persist();
    } catch (_) {
      bookmarks = oldBookmarks;
      highlights = oldHighlights;
      notes = oldNotes;
      bookmarkTags = oldTags;
      tagLibrary = oldLibrary;
      highlightColors = oldColors;
      noteRanges = oldRanges;
      rethrow;
    }
    changed();
  }

  void renameTag(String old, String replacement) {
    final name = replacement.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty || name.characters.length > 32) {
      throw const FormatException('Use 1–32 characters.');
    }
    final canonical =
        knownTags
            .where((t) => t.toLowerCase() == name.toLowerCase() && t != old)
            .firstOrNull ??
        name;
    bookmarkTags = {
      for (final e in bookmarkTags.entries)
        e.key: e.value.map((t) => t == old ? canonical : t).toSet().toList(),
    };
    tagLibrary
      ..remove(old)
      ..add(canonical);
    changed();
  }

  void deleteTag(String tag) {
    tagLibrary.remove(tag);
    for (final tags in bookmarkTags.values) {
      tags.remove(tag);
    }
    changed();
  }

  void changed() {
    appearanceChanges.value = (theme, fontFamily);
    if (themeChanges.value != theme) themeChanges.value = theme;
    notifyListeners();
  }

  ReadingPlan createPlan(
    String title,
    int days,
    Iterable<String> selectedBooks,
  ) {
    final books = bookNames.keys.where(selectedBooks.toSet().contains).toList();
    final count = chapters.keys
        .where((k) => books.contains(k.split('.').first))
        .length;
    if (title.trim().isEmpty || title.trim().length > 80) {
      throw ArgumentError('Enter a name (up to 80 characters).');
    }
    if (books.isEmpty) throw ArgumentError('Choose at least one book.');
    if (days < 1 || days > count) {
      throw ArgumentError('Choose between 1 and $count days.');
    }
    final p = ReadingPlan(
      'custom_${DateTime.now().microsecondsSinceEpoch}',
      title.trim(),
      '',
      days,
      books,
      custom: true,
    );
    customPlans.add(p);
    notifyListeners();
    return p;
  }

  void deletePlan(String id) {
    if (!customPlans.any((p) => p.id == id)) return;
    customPlans.removeWhere((p) => p.id == id);
    planCompleted.remove(id);
    if (activePlan == id) activePlan = '';
    notifyListeners();
  }

  void colorVerses(Iterable<String> ids, int? color) {
    for (final id in ids.where(byId.containsKey)) {
      if (color == null) {
        highlights.remove(id);
        highlightColors.remove(id);
      } else {
        highlights.add(id);
        highlightColors[id] = color.clamp(0, 5);
      }
    }
    notifyListeners();
  }

  void bookmarkVerses(Iterable<String> ids, bool add) {
    for (final id in ids.where(byId.containsKey)) {
      if (add) {
        bookmarks.add(id);
      } else {
        bookmarks.remove(id);
        bookmarkTags.remove(id);
      }
    }
    notifyListeners();
  }

  ReadingPlan? get plan =>
      allPlans.where((p) => p.id == activePlan).firstOrNull;
  int nextPlanDay(ReadingPlan p) {
    final done = planCompleted[p.id] ?? <int>{};
    for (int i = 0; i < p.days; i++) {
      if (!done.contains(i)) return i;
    }
    return p.days;
  }

  List<String> planChapters(ReadingPlan p, int day) {
    final list = chapters.keys
        .where((k) => p.books.isEmpty || p.books.contains(k.split('.').first))
        .toList();
    if (day < 0 || day >= p.days) return [];
    return list.sublist(
      day * list.length ~/ p.days,
      (day + 1) * list.length ~/ p.days,
    );
  }

  void completePlanDay(ReadingPlan p, int day, bool completed) {
    if (day < 0 || day >= p.days) return;
    final done = planCompleted.putIfAbsent(p.id, () => {});
    if (completed) {
      done.add(day);
    } else {
      done.remove(day);
    }
    notifyListeners();
  }

  void go(String b, int c, [String v = '1']) {
    book = b;
    chapter = c;
    verse = v;
    recordVisit();
    notifyListeners();
  }

  bool adjacent(int delta) {
    final keys = chapters.keys.toList();
    final i = keys.indexOf('$book.$chapter') + delta;
    if (i < 0 || i >= keys.length) return false;
    final parts = keys[i].split('.');
    go(parts[0], int.parse(parts[1]));
    return true;
  }

  List<Verse> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final ref = RegExp(r'^(.+?)\s+(\d+)(?::(\d+))?$').firstMatch(q);
    if (ref != null) {
      final name = ref[1]!;
      final c = int.tryParse(ref[2]!);
      final v = ref[3];
      final matches = bookNames.entries
          .where(
            (e) =>
                e.value.toLowerCase().startsWith(name) ||
                e.key.toLowerCase() == name ||
                malayalamBooks[e.key]!.startsWith(name),
          )
          .toList();
      if (matches.length == 1) {
        return (chapters['${matches.first.key}.$c'] ?? [])
            .where(
              (x) =>
                  v == null || x.number == v || x.number.split('-').contains(v),
            )
            .toList();
      }
    }
    final namedBooks = bookNames.entries
        .where(
          (e) =>
              e.value.toLowerCase().startsWith(q) ||
              malayalamBooks[e.key]!.startsWith(q),
        )
        .map((e) => e.key)
        .toSet();
    if (q.length >= 2 && namedBooks.isNotEmpty) {
      return all.where((v) => namedBooks.contains(v.book)).toList();
    }
    return [
      for (int i = 0; i < all.length; i++)
        if (_searchTexts[i].contains(q)) all[i],
    ];
  }
}

class ReadingPlan {
  final String id, title, subtitle;
  final int days;
  final List<String> books;
  final bool custom;
  const ReadingPlan(
    this.id,
    this.title,
    this.subtitle,
    this.days,
    this.books, {
    this.custom = false,
  });
}

const readingPlans = [
  ReadingPlan(
    'gospels30',
    'The Gospels',
    'Walk through the life of Jesus',
    30,
    ['MAT', 'MAR', 'LUK', 'JOH'],
  ),
  ReadingPlan('nt90', 'New Testament', 'A chapter at a time, every day', 90, [
    'MAT',
    'MAR',
    'LUK',
    'JOH',
    'ACT',
    'ROM',
    '1CO',
    '2CO',
    'GAL',
    'EPH',
    'PHI',
    'COL',
    '1TH',
    '2TH',
    '1TI',
    '2TI',
    'TIT',
    'PHM',
    'HEB',
    'JAM',
    '1PE',
    '2PE',
    '1JO',
    '2JO',
    '3JO',
    'JUD',
    'REV',
  ]),
  ReadingPlan(
    'psalms30',
    'A month in Psalms',
    'Thirty days of prayer and poetry',
    30,
    ['PSA'],
  ),
  ReadingPlan(
    'bible365',
    'Bible in a year',
    'Read the complete Bible',
    365,
    [],
  ),
];

String chapterLabel(String key) {
  final parts = key.split('.');
  return '${bookNames[parts[0]]} ${parts[1]}';
}

String passageLabel(List<Verse> verses) {
  if (verses.isEmpty) return '';
  if (verses.length == 1) return verses.first.reference;
  final same = verses.every(
    (v) => v.book == verses.first.book && v.chapter == verses.first.chapter,
  );
  if (!same) return '${verses.first.reference} – ${verses.last.reference}';
  final numbers = verses.map((v) => int.tryParse(v.number)).toList();
  if (numbers.any((n) => n == null)) {
    return '${bookNames[verses.first.book]} ${verses.first.chapter}:${verses.map((v) => v.number).join(', ')}';
  }
  final sorted = numbers.cast<int>()..sort();
  final ranges = <String>[];
  int start = sorted.first, end = start;
  for (final n in sorted.skip(1)) {
    if (n == end + 1) {
      end = n;
    } else {
      ranges.add(start == end ? '$start' : '$start–$end');
      start = end = n;
    }
  }
  ranges.add(start == end ? '$start' : '$start–$end');
  return '${bookNames[verses.first.book]} ${verses.first.chapter}:${ranges.join(', ')}';
}
