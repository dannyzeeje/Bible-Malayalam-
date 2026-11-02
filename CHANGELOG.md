## 2.3.6

- Reader-specific friction and spring scrolling without stretching scripture.
- Isolated verse repainting and cached highlight geometry/texture; existing UI, settings and verse restoration retained.
- Softer reading contrast and balanced Malayalam leading without changing saved font size or line spacing.
- Removed the duplicate pressed ink highlight from the moving dock selection pill.
- Straight rounded chalk-marker highlights; overlapping shaped-text boxes are merged before painting, with light/dark pigment tuning.

## 2.3.5

- Decluttered reading history to a compact, day-grouped list of references and visit times.
- Removed the fading content layer beneath the glass dock. Dock movement now shares the tab transition timeline and reverses from its current position during rapid tab switches.

## 2.3.4

- Malayalam interface labels follow the selected Malayalam reading font.
- Added Chilanka and Baloo Chettan 2 Unicode fonts, bundled for offline use under SIL OFL.
- Added device-local, date-grouped reading history for today and the previous four days. Repeated visits to the same verse are combined per day; tap a history entry to revisit it.

## 2.3.3

- Passage picker opens fully expanded; choose a book, chapter and verse to navigate immediately.
- Optional Malayalam book labels retain English and Malayalam search matching.
- Fixed Appearance transition blur composition and highlight geometry; added wax-grain texture.
- Rounded saved-verse sorting menu and settings for renaming/deleting tags.
- Export/import annotation backups through Android's document picker, with validation and merge semantics.

## 2.3.2

- Reworked Appearance around the supplied reference: two-verse preview, flat divided sections, text-size badge, circular theme swatches and illustrated spacing options.
- Preserved live preview updates, font selection, persistent settings and reduced-motion support.
- Adapted Sthuthi source styling: warm light/charcoal backgrounds, bold headings, accent eyebrows, tinted feature surfaces and rounded cards. Existing Bible accent colours retained.

## 2.3.1

- Restyled Appearance with grouped controls, a fixed live preview and a blurred, tap-to-dismiss backdrop.
- Replaced the pale dark-mode Continue reading card with a subtle blue-charcoal surface and light text.
- Matched the reader dock shape to the main navigation and reduced the bottom edge wash so backdrop blur remains visible.
- Retained existing accent colours and reduced-motion support.

# 2.3.0+15

Consistent surfaces, blue theme colors, readable controls, responsive dock, integrated saved tags and simpler plan progress. Reader chrome repaint isolation, lazy tab mounting, indexed saved/search operations, reduced-motion support and 40 passing tests.

# Bible 1.3.0 (build 4)

- Refined popup hierarchy and compact stepped passage navigation.
- Marker-style line underlines and lightweight multi-verse selection.
- Custom plans with selected books, validated duration and saved progress; included plans retained.
- Themes apply across every screen and popup.
- Blur fixed at 18/20; slider removed.
- Directional reader controls and smoother state-preserving tab transitions.
- Removed duplicated full-page blur rendering.
- Native highest-supported-refresh-rate request at the current display resolution; no app-imposed 60 FPS cap.
- Existing data and update-signing identity retained.

# Bible 1.2.0 (build 3)

- Functional Library reading hub with four offline reading plans and persisted daily completion.
- Real app settings; About moved into its own entry.
- Multi-verse selection before opening compact batch actions.
- Six highlight colors, remembered default color, batch bookmarking/copy and shared range notes.
- Continuous linear blur fade; hidden reading bars leave no strips on the page.
- Consistent frosted surfaces, circular controls, pill buttons and Cupertino toggles.
- Native keep-screen-awake support while reading.
- Safe note editor controller lifecycle.
- Existing data, app ID and signing key preserved.

# Bible 1.1.0 (build 2)

- Bible name and new open-book/cross icon, including adaptive and themed Android icons.
- Minimal Library, smaller cover, simplified Continue row and slimmer controls.
- Four offline Malayalam fonts: Noto Serif, Noto Sans, Manjari and Gayathri.
- Saved font choices with live preview.
- Reading bars hide on user scrolling and return on tap without changing the reading viewport.
- Text blurs progressively beneath the top and bottom control areas.
- Compact Book / Chapter / Verse wheels with direct reference lookup.
- Precise verse restoration beyond the first screen of a chapter.
- Version 1 notes, bookmarks, settings and location remain compatible; app ID and signing key are unchanged.
