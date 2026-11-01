# 2.3.5 history and dock polish

- History uses compact references and local visit times; removed long preview text,
  repeated dividers, chevrons and explanatory copy.
- Dock highlight follows the existing tab controller. On interrupted transitions,
  the next tween starts from its rendered position. Removed the content opacity
  layer sampled by the dock blur; tab state/lazy mounting are retained.
- All 46 tests pass with ordinary visual comparisons; analysis is clean.
  Regressions cover Saved → Search → Saved interruptions, fixed dock bounds,
  day grouping and compact history presentation.

# 2.3.4 fonts and reading history

- Selected Malayalam font is propagated through the UI theme fallback and local
  Appearance theme, preserving Inter for English controls. Theme updates listen
  only to appearance changes rather than rebuilding on reading-position updates.
- Added official Google Fonts Chilanka and Baloo Chettan 2 assets and SIL OFL files.
- History records opened/stable reading positions, deduplicates each verse per
  local calendar day, expires records before today minus four days, and persists
  across restarts. Day-boundary, expiry, persistence and navigation tests pass.
- History is available from the home clock and Settings → Saved data. History
  stays local; annotation restore remains limited to annotations.
- All 44 tests pass, including UI font propagation and visual snapshots.

# 2.3.3 reader and saved-data improvements

- Passage selection opens at full height and navigates on verse selection.
- Annotation backup tests cover merge/round-trip, malformed input rejection, tags,
  highlight colours and note ranges. Bilingual search and label persistence verified.
- Backups restore annotations by merging; matching entries take the backup value.
  Settings and reading plans are exported for reference but are not overwritten on restore.
- Android file-picker and signed APK compilation are verified by the release workflow;
  physical-device file-provider interaction and GPU profiling require device testing.

# 2.3.2 reference and Sthuthi styling

- Appearance follows the supplied layout with a fixed, scrollable two-verse preview,
  divided sections, size badge, theme circles and illustrated spacing controls.
- Sthuthi-1.0.0-Flutter-Source.zip was inspected for shared design conventions:
  warm white/charcoal neutrals, Inter headings, accent eyebrows, tinted feature
  cards and rounded glass navigation. Bible accent values are retained.
- Existing lazy tabs, inactive ticker suppression, reduced motion and paint-only
  transitions remain in place. No physical-device frame-time profiling performed.
- Analysis clean; 41 tests pass including visual comparisons, settings persistence,
  compact layouts and motion regressions. Light/dark home previews reviewed.
- Version 2.3.2+18. Changes must remain unmerged pending user confirmation.

# 2.3.1 appearance and reader polish

- Reviewed updated Light/Dark Appearance and dark home screenshots.
- Appearance backdrop and reader dock blur have explicit regression assertions.
- Existing 41 tests cover preview updates, saved settings, scrolling controls,
  navigation, reduced motion, compact screens and visual snapshots.
- Release version incremented to 2.3.1+16; existing signing configuration retained.

# Apple Music-inspired interface refresh

- Existing theme accent values are unchanged. Featured reading cover, square plan
  artwork, larger headings and a blurred floating tab bar refresh the interface.
- Tab content uses paint-only fade/slide transitions; existing lazy tab loading,
  retained search state and inactive ticker suppression are preserved.
- Cover press feedback restores on pointer cancellation and honors reduced motion.
- Flutter 3.47.7 is pinned in both workflows; dependency lock and visual snapshots
  were refreshed for that SDK. Card content has its own transparent Material so
  ListTile feedback paints above the card fill.
- Static analysis passes. All 41 tests pass, including ordinary golden comparisons,
  press cancellation, reduced motion, compact layouts and navigation regressions.
- Light/dark dashboard and settings snapshots were visually reviewed. No physical
  device frame-time profiling was performed; 60/120 fps is not yet measured.

## Previous release validation (before this refresh)

# Bible 2.3.0 validation

- Signed ARM64 release built successfully: com.zeeje.word, 2.3.0+15, minimum SDK 24, target SDK 36.
- Dart analysis: no issues. All 40 automated tests pass including normal golden-image comparisons after visual review.
- Reader chrome changes preserve the existing scripture widget subtree while scrolling. Directional threshold prevents rapid show/hide changes. Marker measurement TextPainters are disposed after line boxes are cached.
- Home tabs mount on demand; inactive tab tickers are disabled and search state survives switching. Status blur is outside the tab fade layer. Duplicate Read taps are guarded.
- Saved verses use indexed lookup and rank maps. Search text and chapter counts are indexed once during loading. Existing corpus/search/persistence regression tests pass.
- Light, paper and dark main screens fit 320x640 with 1.35x system text; responsive dock and pill controls have no tested overflows.
- Custom pill, reader chrome, tab and progress animation durations honor reduced-motion preferences. Native highest-supported refresh request is retained without a hardcoded frame-rate cap.
- UI: consistent fills, spacing and controls, readable theme colors, integrated bookmark tags, animated plan progress and active-day labels.
- APK includes only current status_veil.frag plus Flutter built-in shaders. Obsolete blur_fade.frag and progressive_blur.frag are absent.
- Scripture, attribution and all six fonts match source byte-for-byte. Approved padded monochrome icon and no branded startup screen retained.
- Signature matches the installed-version certificate: 9a9f7d8dc6cab9f65ae0510d286bd083265fb1ee6e8ab48930676f5de8f89a89. 16KB alignment passes.
- APK bytes: 19880377; SHA256: 685c2c8e7f1211f4891d8f1051314fa81b9f2d510e324083322d3bc0e714b8c9.

No physical-phone GPU profiling or FPS measurement was performed. Tests establish correctness and remove identified rebuild/layout work; they do not guarantee 60/120 fps on every phone. Install over the existing app to keep its local data. The private source archive includes signing material and must be kept private.
