part of 'main.dart';

final highlightPalette = <Color>[
  Color(0xffffd60a),
  Color(0xff30d158),
  Color(0xff32ade6),
  Color(0xffbf5af2),
  Color(0xffff375f),
  Color(0xffff9f0a),
];
final highlightNames = ['Yellow', 'Green', 'Blue', 'Purple', 'Pink', 'Peach'];
Widget colorChoice(int index, bool selected, VoidCallback action) => Builder(
  builder: (context) {
    final color = highlightPalette[index];
    return SizedBox.square(
      dimension: 44,
      child: Semantics(
        label: '${highlightNames[index]} highlight',
        selected: selected,
        button: true,
        child: Tooltip(
          message: '${highlightNames[index]} highlight',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: action,
            child: Center(
              child: Container(
                key: ValueKey('color-ring-$index'),
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? color : Colors.transparent,
                    width: 1.8,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: selected
                      ? AppIcon(
                          CupertinoIcons.checkmark,
                          size: 13,
                          color: color.computeLuminance() > .5
                              ? const Color(0xff202020)
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  },
);

Future<void> verseActions(BuildContext context, BibleStore s, Verse v) =>
    selectionActions(context, s, [v]);

Future<void> selectionActions(
  BuildContext context,
  BibleStore s,
  List<Verse> verses, {
  VoidCallback? onApplied,
}) async {
  if (verses.isEmpty) return;
  final ids = verses.map((v) => v.id).toList();
  final allSaved = ids.every(s.bookmarks.contains);
  bool applied = false;
  final noteRequested = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => GlassPanel(
      radius: 32,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(sheet).bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sheetGrip(sheet),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  passageLabel(verses),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: uiFill(sheet),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              verses.map((v) => v.text).join(' '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16,
                height: 1.7,
                color: uiInk(sheet),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < highlightPalette.length; i++)
                colorChoice(i, i == s.defaultHighlight, () {
                  s.colorVerses(ids, i);
                  s.defaultHighlight = i;
                  save(context, s);
                  applied = true;
                  Navigator.pop(sheet, false);
                }),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              actionItem(CupertinoIcons.pencil, 'Highlight', () {
                s.colorVerses(ids, s.defaultHighlight);
                save(context, s);
                applied = true;
                Navigator.pop(sheet, false);
              }),
              actionItem(
                CupertinoIcons.bookmark,
                allSaved ? 'Unsave' : 'Bookmark',
                () {
                  if (allSaved) {
                    s.bookmarkVerses(ids, false);
                    save(context, s);
                    applied = true;
                    Navigator.pop(sheet, false);
                  } else {
                    Navigator.pop(sheet, false);
                    editBookmarkTags(context, s, ids).then((saved) {
                      if (saved) onApplied?.call();
                    });
                  }
                },
              ),
              actionItem(CupertinoIcons.doc_on_doc, 'Copy', () async {
                await Clipboard.setData(
                  ClipboardData(text: copyPassage(verses)),
                );
                applied = true;
                if (sheet.mounted) Navigator.pop(sheet, false);
              }),
              actionItem(
                CupertinoIcons.square_pencil,
                'Note',
                () => Navigator.pop(sheet, true),
              ),
              actionItem(CupertinoIcons.pencil_slash, 'Clear color', () {
                s.colorVerses(ids, null);
                save(context, s);
                applied = true;
                Navigator.pop(sheet, false);
              }),
            ],
          ),
        ],
      ),
    ),
  );
  if (noteRequested == true && context.mounted) {
    if (verses.length == 1 && s.noteRanges.containsKey(verses.first.id)) {
      await editNote(context, s, verses.first);
    } else {
      await editSelectionNote(context, s, verses);
    }
    applied = true;
  }
  if (applied) onApplied?.call();
}

Widget actionItem(IconData icon, String label, VoidCallback action) => Expanded(
  child: Builder(
    builder: (context) => TextButton(
      onPressed: action,
      style: TextButton.styleFrom(
        foregroundColor: uiInk(context),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  ),
);

Future<void> editNote(BuildContext context, BibleStore s, Verse v) {
  final ids = s.noteRanges[v.id] ?? [v.id];
  return editSelectionNote(context, s, [
    for (final id in ids)
      if (s.byId.containsKey(id)) s.byId[id]!,
  ]);
}

Future<void> editSelectionNote(
  BuildContext context,
  BibleStore s,
  List<Verse> verses,
) async {
  if (verses.isEmpty) return;
  final anchor = verses.first.id;
  final value = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NoteComposer(
      title: passageLabel(verses),
      initial: s.notes[anchor] ?? '',
      existing: s.notes.containsKey(anchor),
    ),
  );
  if (value != null) {
    if (value.trim().isEmpty) {
      s.notes.remove(anchor);
      s.noteRanges.remove(anchor);
    } else {
      s.notes[anchor] = value.trim();
      s.noteRanges[anchor] = verses.map((v) => v.id).toList();
    }
    s.changed();
    if (context.mounted) await save(context, s);
  }
}

class NoteComposer extends StatefulWidget {
  final String title, initial;
  final bool existing;
  const NoteComposer({
    super.key,
    required this.title,
    required this.initial,
    required this.existing,
  });
  @override
  State<NoteComposer> createState() => _NoteComposerState();
}

class _NoteComposerState extends State<NoteComposer> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: GlassPanel(
      radius: 32,
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sheetGrip(context),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 7,
              maxLength: 20000,
              decoration: InputDecoration(
                hintText: 'Add a note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: uiAccent(context), width: 1),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                if (widget.existing)
                  TextButton(
                    onPressed: () => Navigator.pop(context, ''),
                    child: Text('Delete'),
                  ),
                Spacer(),
                primaryPill(
                  'Save',
                  () => Navigator.pop(context, controller.text),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String copyPassage(List<Verse> verses) =>
    '${verses.map((v) => '${v.number} ${v.text}').join('\n')}\n${passageLabel(verses)}';
