# Blasterball 0.3.1 — build 7

2026-10-26. Layout and background correction using original BB2 assets.

- Scenery now scales uniformly and crops to fill the screen instead of stretching.
- Original frame corners and hinges preserve their proportions; straight rails extend independently.
- Arena and HUD remain centered with asymmetric safe-area insets and refresh after transitions.
- Existing gameplay, saves, audio and edition selection retained.

Validation: 49 deterministic checks per edition on iPhone and iPad simulators, including asymmetric safe-area centering, scenery coverage and frame dimensions. All three editions also decoded 13 audio events and two music tracks. Simulator screenshots inspected. Xcode Release build and developer signature verification passed.

Installed on Duo over Wi-Fi without launching. Read-only process query confirmed the app was not running afterward. Physical layout feedback remains pending.

Scope remains first 12 stages for each BB2 edition. BB3, full campaigns, additional original mechanics and editor remain unfinished. See RELEASE-0.3.0.md for prior feature details.
