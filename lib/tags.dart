part of 'main.dart';

Future<bool> editBookmarkTags(
  BuildContext context,
  BibleStore s,
  List<String> ids,
) async {
  final tags = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BookmarkTagsSheet(store: s, ids: ids),
  );
  if (tags == null) return false;
  s.tagBookmarks(ids, tags);
  if (context.mounted) await save(context, s);
  return true;
}

class BookmarkTagsSheet extends StatefulWidget {
  final BibleStore store;
  final List<String> ids;
  const BookmarkTagsSheet({super.key, required this.store, required this.ids});
  @override
  State<BookmarkTagsSheet> createState() => _BookmarkTagsSheetState();
}

class _BookmarkTagsSheetState extends State<BookmarkTagsSheet> {
  final input = TextEditingController();
  late final Set<String> selected = {
    for (final id in widget.ids) ...?widget.store.bookmarkTags[id],
  };
  String query = '';
  void add(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty || t.characters.length > 32) return;
    final canonical =
        widget.store.knownTags
            .where((v) => v.toLowerCase() == t.toLowerCase())
            .firstOrNull ??
        t;
    setState(() => selected.add(canonical));
    input.clear();
    setState(() => query = '');
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height * .85 -
            MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SheetShell(
        title: 'Bookmark tags',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final t in selected)
                  InputChip(
                    label: Text(t),
                    onDeleted: () => setState(() => selected.remove(t)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('tag-input'),
              controller: input,
              maxLength: 32,
              textInputAction: TextInputAction.done,
              onChanged: (v) => setState(() => query = v),
              onSubmitted: add,
              decoration: InputDecoration(
                hintText: 'Add a tag',
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: 'Add tag',
                  onPressed: () => add(input.text),
                  icon: const AppIcon(CupertinoIcons.plus, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.store.knownTags.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in widget.store.knownTags.where(
                      (v) =>
                          !selected.contains(v) &&
                          v.toLowerCase().contains(query.toLowerCase()),
                    ))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(t),
                          onPressed: () => add(t),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: primaryPill('Save bookmark', () {
                add(input.text);
                Navigator.pop(context, selected.toList());
              }),
            ),
          ],
        ),
      ),
    ),
  );
}
