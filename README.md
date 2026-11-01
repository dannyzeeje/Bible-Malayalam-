# Bible — Malayalam Bible

An offline Malayalam Bible reader for Android with a simple interface and English controls. Supports Android 7.0 and later.

## Features

- Complete Bible with 66 books and 1,189 chapters, available offline.
- Malayalam word and phrase search, plus passage lookup such as `John 3:16`.
- Bookmarks, highlights, notes and saved reading position.
- Built-in and custom reading plans with progress tracking.
- Light, Paper and Dark themes, four Malayalam fonts, and adjustable text size and spacing.

No account or internet connection is required. Notes, bookmarks and reading progress stay on your device; clearing app data or uninstalling removes them.

## Scripture and credits

Malayalam Bible 1910 edition, digitized and revised by The Free Bible Foundation. Copyright © 2015 The Free Bible Foundation. Scripture is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

[Scripture source](https://ebible.org/mal2015/) · [Full attribution](assets/ATTRIBUTION.txt)

Bundled fonts are licensed under SIL OFL 1.1; licenses are included in [assets/fonts](assets/fonts/). The app is not endorsed by the scripture publisher.

## Android builds

GitHub Actions runs static analysis and widget/visual tests on pull requests,
main-branch pushes, and manual runs of **Build Android APK**. Download
`Malayalam-Bible-debug-APK` from the successful run's Artifacts section.
Flutter is pinned to 3.47.7 to keep visual snapshots consistent.

**Build Universal Release APK** builds a signed release on `v*` tags or manual
runs. It requires the existing `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, and `ANDROID_KEY_ALIAS`
repository secrets.

The interface uses the existing Light, Paper and Dark accents with a featured
reading card, square plan covers, larger headings and a translucent tab bar.
Tab transitions and cover press feedback respect the system reduced-motion setting.
