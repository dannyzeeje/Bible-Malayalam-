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
