# Bible — Malayalam Bible

A Flutter Android app with English controls, Malayalam scripture, a minimal reading hub, and a full-screen reader. Version 2.3.0, application ID `com.zeeje.word`.

## Version 2.3 — UI and motion refinement

- Shared blue hue with readable tonal contrast in light/dark modes; warm paper accent retained. Removed off-brand seeded control colors and heavy default dividers. Opaque cards use one consistent fill; floating reader surfaces retain real blur.
- Unified button targets, page margins, typography and segmented controls. Bottom dock and pills adapt to larger system text. Plans have a simpler animated progress track, clearer active-day labels, and quieter title weight. Saved tags and edit actions are contained inside each verse card.
- Reader chrome has its own notifier and a stable scripture child: scroll direction no longer rebuilds the chapter. A 14px directional threshold avoids rapid show/hide flicker. TextPainter resources used for marker line boxes are disposed after measuring.
- Home tabs mount on demand, retain search state, disable hidden tab tickers, and use a short eased fade. Status blur sits outside the fade layer to preserve backdrop sampling. Repeated Read taps cannot open duplicate reader routes.
- Saved items use ID lookups and cached canonical/ranked order rather than scanning the whole Bible and repeatedly calling indexOf during sorting. Lowercase search text and chapter counts are indexed once at load. Search clearing is immediate.
- Reduced-motion preference disables custom pill, chrome, tab and progress animations. Existing clamped stretch scrolling, highest-supported refresh request, padded monochrome icon, and no branded loading screen remain.
- 40 automated tests pass including compact 320x640 layouts with 1.35x system text in all themes, stable reader subtree during scroll, lazy tabs/search retention, and reduced-motion pill behavior.

No physical-device frame timing, GPU profile or FPS benchmark was collected. Automated tests validate behavior and layout, not a universal smoothness guarantee.

## Version 2.2

- Approved minimal open-Bible/cross concept rebuilt as symmetrical black-and-white vector geometry. Generous adaptive-icon padding, matching monochrome and legacy launchers.
- Removed the branded loading page and 1.5-second startup delay. Native launch window is a plain theme background; dashboard opens immediately after data is ready.
- Removed the fixed dashboard header. Title and settings scroll in the page without covering cards.
- Status inset only: tiny contiguous 5x5 Gaussian kernel, mixed 55% maximum with the sharp original and linearly reduced to zero over the inset plus 12dp. No wide sparse samples, opacity-mask layers or high-opacity panel. Below the feather the shader returns the original pixels unchanged. Older non-Impeller renderers use a 6% fading tint instead of a clipped blur.
- Shader pixel tests validate softening, decreasing effect and exact source preservation below the feather; layout and startup tests cover the removed header and delay. Physical Android GPU testing is still needed.

## Version 2.1

- Replaced the reference-traced identity with an original monochrome vector book, with separate rounded pages, page strokes and a ribbon. Launcher, native splash and Flutter loading mark use this new geometry.
- Cold startup remains visible for at least 1.5 seconds and waits longer when loading requires it. Preloaded-store test/navigation cases skip the cold-start delay.
- Dashboard title and settings now stay in a fixed foreground header, with engine-native blur applied only to content behind it. The title cannot straddle a clipped blur boundary. Removed all custom status-area fragment shaders and opacity filter composition.
- All 35 automated tests pass. Header tests verify unchanged title/settings coordinates after scrolling; startup tests verify it remains visible before the minimum duration and opens the dashboard afterward.

## Version 2.0.1

- Removed the sparse multi-tap blur shader responsible for repeated text edges. The engine now performs Gaussian blur; a one-sample opacity filter supplies the continuous linear fade on Impeller. Other renderers use the native Gaussian fallback. No opacity save-layer wraps the status filter.
- Rebuilt the reference book silhouette as editable SVG, native Android vector resources and a Flutter CustomPainter. Launcher icons use the white vector on gold; the loading screen draws only the gold book on its page background.
- Removed the generated bitmap logo, old blur shader and their asset declarations. Legacy launcher PNG sizes are deterministic exports of the vector master.
- All 35 tests pass, including loading without an Image widget, native blur configuration, fade shader compilation and existing scroll/reader checks. Device GPU output remains to be confirmed on hardware.

## Version 2.0

- Text actions use plain labels; removed decorative arrows from Read day, Browse, plan chapters and passage search results. Directional navigation controls remain.
- Replaced six status-area blur bands with a continuous linear-radius GPU blur (two separable five-tap passes). Renderers without shader-filter support use a single Gaussian compatibility filter, without discrete bands.
- Scroll position is clamped to its content bounds. Android-style stretch supplies a small elastic edge response without pulling the page through empty space; pages that fit do not overscroll.
- A centered branded loading screen stays visible until the Bible is ready. Native Android launch resources use the matching new gold-and-white open-book identity.
- Bible parsing and indexing run together on a worker isolate. The navigation indicator now moves without relaying out its buttons, and theme changes use a short eased transition.
- New logo generated with the built-in image tool using the supplied references; actual asset and prompt provenance are in assets/branding.
- All 35 automated tests pass, including repeated end-boundary swipes, bounded stretch strength, loading readiness, arrow-free action labels and shader compilation. Dart analysis reports no issues.
- Same application ID and signing certificate; install over v1.9 to retain local data.

## Version 1.9

- Home content now scrolls behind a tapered frosted status-area overlay rather than clipping at a safe-area edge.
- Native momentum follows swipe velocity, with elastic edges for scrollable content and no bounce on pages that fit.
- Appearance has a stationary live Malayalam preview above a separate compact, scrolling control panel.
- Text size supports one-point +/- buttons and a full-width 16–34 pt slider. Theme, typeface, spacing and verse-number changes preview immediately.
- All 32 automated tests pass. New interaction tests verify fixed preview position, live size changes and persistence, edge rebound, velocity response and the scrolling home status treatment.
- Same application ID, signing certificate, scripture and local-data format as v1.8.

## Version 1.8

- Rebuilt dashboard with compact Continue Reading, a book-cover plan card, progress and today's chapter actions.
- Frosted backdrop blur is enabled on the reader's floating controls, with translucent surfaces that reveal the blur.
- Bookmark saving opens a tag editor with existing-tag suggestions. Saved supports tag filters, Bible/recent/tag sorting and editing tags.
- Copy includes verse text and passage reference only; edition attribution remains available inside the app.
- Rounded note input, a single moving Saved-tab pill and stronger plan typography.
- All 29 automated tests pass, covering tags, copy output and enabled reader blur. Dart analysis reports no issues. Physical-device frame-rate testing remains pending.
- Same application ID and signing certificate; install over the previous release to retain local data.

## Version 1.7

- A single sliding segment indicator replaces independent animated backgrounds. Labels keep fixed typography; tests verify intermediate positions and constant dimensions.
- Light and Dark share a balanced slate-blue accent. Paper uses a subdued warm-brown accent.
- Continue Reading, plan cards, spacing and primary buttons are more compact. Minimum touch targets remain supported by Material button padding.
- Check, close and copy actions use consistent custom outline strokes. Other action icons retain the Cupertino outline family.
- Launcher icon is a flat, horizontally symmetrical white book-and-cross mark with editable SVG, adaptive and monochrome versions.
- All 25 automated tests pass, including the pill-motion and accent-consistency check. Device FPS is not benchmarked.

## Version 1.6

- High-contrast near-black dark theme, flat charcoal cards, white text and vivid green accents.
- Visual Light/Paper/Dark theme tiles in Settings and Reader appearance.
- Removed the passage picker's upward arrow; its grab handle still expands the sheet.
- Testament switching resets scroll position; segment typography keeps fixed metrics.
- Removed whole-page tab translation and live backdrop filters from floating controls to reduce compositing during transitions.
- Android preference writes are asynchronous. Existing highest-supported-refresh-rate requests remain; no fixed FPS cap exists.
- All 24 automated tests and signature checks pass. Device FPS remains unbenchmarked.

## Version 1.5

- Warm neutral surfaces, quieter content cards, restrained reader colors and consistent outline controls.
- Original layered isometric Bible logo inspired by the supplied reference, with editable SVG and adaptive Android variants.
- Reader header search replaces the automatic current-verse bookmark shortcut. Batch bookmarking from selected verses remains available.
- Verse numbers occupy a fixed neutral left gutter. Selection and annotations preserve text wrapping.
- Highlights use translucent, irregular marker pigment behind each wrapped line, with subtle crayon texture instead of underlines or paragraph fills.
- Highlight-selection rings match the chosen pigment color.
- Passage picker pulls up to expand, sharing its scroll controller with book lists and number grids. It opens with the selected number fully visible and expands when search receives focus.
- Pull-up menus use grab handles instead of cross buttons. The reader retains a back control and selection cancellation.
- Settings groups Appearance, Reader, Highlight color and General controls. About is brief, with full edition attribution and licenses available in a nested page.
- All 23 automated tests pass, including new search-shortcut, sheet expansion, marker-coverage, color-ring and small-screen keyboard checks.
- Same app identity, update signature, Bible text, local-data schema and bundled fonts as v1.4.

## Version 1.4

- Matching blue-and-white launcher icon, vivid blue Continue Reading card, coral and emerald plan cards, clear typography and refined white, paper and dark surfaces.
- Floating frosted circles and pills are reserved for navigation. Content cards and modal sheets are opaque, avoiding overlapping live blur filters and sharp text showing through sheets.
- Malayalam chapter titles and smaller inline verse numbers, with a compact page-like reading layout. Scripture content is unchanged.
- Typeface cards display Malayalam samples in their actual font. A live Malayalam passage previews text size and spacing. The settings header stays visible while the options scroll.
- Selection indicators stay outside the text column, preserving line wrapping and position. Action sheets include a bounded Malayalam passage preview and vivid highlight colors.
- Content-sized scrolling uses clamping physics. Short pages remain stationary instead of forcing bounce gestures.
- Tab pages are cached behind repaint boundaries and use short vsync-driven transitions. Reader text painting is isolated from control animations; reading-location persistence no longer rebuilds the full reader.
- App-wide themes, default and custom plans, search, notes, bookmarks, fixed blur and directional reader controls are preserved.
- Eighteen automated tests pass, including short-page scrolling and selection geometry. No device FPS benchmark is claimed.

## Version 1.3

- Appearance applies across the whole application: Library, Settings, Search, Saved, plans, reader and all sheets. Light, Paper and Dark remain available and persist across restarts.
- Popup layout was rebuilt with compact headings, consistent spacing and smaller typeface controls. Passage navigation uses Book / Chapter / Verse steps and lazy number grids, opening near the current chapter or verse.
- Highlights use softly rounded marker underlines following each wrapped line of Malayalam text. Selection uses thin underlines and gutter checkmarks; paragraphs are not filled with boxes.
- Daily chapter lists are bounded and lazy, including very large custom-plan days.
- Custom reading plans have a name, selected books and duration. Duration is validated against the number of chapters to prevent empty days. Custom plans and progress are saved alongside all four included plans. Custom plans can be deleted with confirmation.
- Blur is fixed at 18/20. The old stored blur value is ignored and the settings slider is removed.
- Scrolling toward later verses hides reader controls; returning toward earlier verses reveals them. Selection keeps its action bar visible.
- The full-page filtered text duplicate is removed. A lightweight edge fade and localized frosted controls reduce scrolling work.
- Tabs retain state and use a short vsync-driven transition with an animated selection pill. Switching away from Search dismisses the keyboard.
- Android requests the highest supported display refresh rate at the current resolution. There is no fixed 60 FPS app timer or cap. The OS can still adjust the effective refresh rate for power, thermal or manufacturer policy.
- Existing text, notes, bookmarks, highlights, default-plan progress, app ID and signing key are preserved.

## Version 1.2

- Library is now a reading hub, with Continue Reading, reading plans, saved progress and quick access to saved verses. The book-cover landing page and book loading indicator have been removed.
- Four complete offline plans: Gospels (30 days), New Testament (90), Psalms (30), and Bible in a year (365). Each plan partitions its intended chapters exactly once. Completion is explicitly marked by the reader and can be undone.
- A real Settings page controls reading appearance, verse numbers, auto-hiding controls, continuous edge blur strength, reading screen-awake behavior, selection haptics and default highlight color. About and edition details are a separate nested entry.
- Tap verses to build a multi-selection. Long-press another verse to extend a range, or use the range button and tap the final verse. Open Actions when the selection is ready.
- Compact batch actions: highlight with the default color, choose one of six colors, bookmark/unbookmark, copy all selected verses, create a shared range note, or clear highlights.
- The reader uses a continuous linear alpha fade over a blurred, scroll-synchronized copy of the chapter. This replaces the clipped backdrop strips. Both the controls and edge effect disappear fully while hidden. No platform-specific shader API or screen capture is used.
- Frosted surfaces, circular 44-point controls, full pill ends, Cupertino switches and consistent spacing are used across the hub, settings, reader and action sheets.
- Screen-awake behavior uses Android window flags only while the reader is active; it requests no extra permission.
- The note editor owns and disposes its text controller with its actual widget lifetime.
- Existing annotations, location, fonts, app ID and update-signing key are preserved.

## Version 1.1

- Renamed the app to **Bible**, with a new editable open-book/cross logo, adaptive launcher icon and Android themed icon.
- Reduced Library to the Bible cover/title and a compact Continue row. Publisher and edition details remain in About.
- Slimmer reading bars overlay the page. User scrolling hides both bars; tapping the page restores them without resizing or shifting the reading viewport.
- Progressive backdrop blur keeps text beneath the top selection bar and bottom toolbar unobtrusive.
- Added four offline Malayalam typefaces, with saved typeface preference and live preview.
- Replaced the large chapter/verse grids with a compact three-column Book / Chapter / Verse wheel picker and direct reference lookup.
- Precise verse navigation now lays out chapter text before restoring the selected verse, including verses initially outside the viewport.
- Kept the previous package ID, storage format and signing certificate for in-place updates.

## Included

- Complete offline Bible: 66 books, 1,189 chapters, 31,098 publisher verse records. The publisher's verse numbering is retained.
- English book/chapter/verse picker and reference search, e.g. `John 3:16`.
- Offline Malayalam word and phrase search.
- Verse bookmarks, highlights and notes; long-press a result or saved verse for actions.
- Persistent reading location and Light / Paper / Dark reading themes.
- Adjustable text size, line spacing and verse numbers.
- Four offline Malayalam reading fonts: Noto Serif, Noto Sans, Manjari and Gayathri, plus Inter and Lora for the interface.
- Chapter navigation buttons and left/right chapter swipes.
- Local storage via a small Android MethodChannel using private SharedPreferences. No account, server, network access or storage permission is needed. Reading-plan progress and highlight colors are also stored locally.

The reader uses vertical scrolling. Scroll toward later verses to hide controls and toward earlier verses to reveal them. Tap verses to select them, then use Actions for batch annotations. The full Bible is already included; there is no first-run text download. This release does not include audio, cloud sync or commentary.

## Bible edition and license

Malayalam Bible 1910 edition, digitized, revised and published by volunteers of The Free Bible Foundation in the contemporary orthography.

Copyright © 2015 The Free Bible Foundation. Edition identifier `mal2015` / `MALFBF`.

Scripture text is distributed under **CC BY-SA 4.0**. See `assets/ATTRIBUTION.txt` and `assets/source_about.html`. Conversion to JSON retains the wording of the publisher's verse-per-line export; that export omits original formatting, section titles and notes. The app is not endorsed by the publisher.

Source: https://ebible.org/mal2015/

Publisher export: https://ebible.org/Scriptures/mal2015_vpl.zip

Regenerate the offline corpus using Python 3:

```sh
python3 tools/import_bible.py /path/to/mal2015_vpl.zip
```

The fonts are distributed under SIL OFL 1.1; their individual licenses are in `assets/fonts/` and in the app's open-source licenses screen.

## Build

Built with Flutter 3.38.3 / Dart 3.10.1, JDK 17, Android SDK 36, Build Tools 35.0.0 NDK 28.2.13676358 and CMake 3.22.1. Minimum supported Android version: Android 7.0 (API 24). The supplied APK targets ARM64 phones.

Install Flutter stable and the Android SDK, accept the Android SDK licenses, then:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

For a universal APK instead:

```sh
flutter build apk --release
```

The build output is `build/app/outputs/flutter-apk/app-release.apk`. `local.properties` and machine-specific SDK paths are deliberately omitted from the source archive and are regenerated by Flutter.

## Signing and future updates

This private source archive includes `android/app/word-release.jks` and `android/key.properties` so future builds can update the installed app without changing its signature. Keep the archive private and preserve these two files. They are excluded by `.gitignore`; do not add them to a public repository. Increase `version: 1.7.0+8` before publishing an update.

## Validation

Twenty-three tests exercise corpus/search/navigation, legacy migration, global themes, marker underlines, custom-plan creation/validation/persistence, complete plan coverage, multi-verse actions and range notes, directional controls, native awake channel calls and passage navigation including long chapters. Rendered screens are manually reviewed after intentional visual changes. Rendered phone-size screens are in `test/screens/`. Golden images can be regenerated with `flutter test --update-goldens` when an intentional visual change is made.

Device storage is local. Android app removal or clearing app data removes personal annotations. No physical-device test is claimed by this project; see the delivered validation report for the build/signature checks that were actually run.
