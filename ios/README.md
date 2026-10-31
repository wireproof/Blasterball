Current delivery: **0.6.0 build 13**, installed on Duo without launch. [Release notes](RELEASE-0.6.0.md) describe the layout fixes, working ports and expanded BB3 reconstruction, including remaining unfinished features.

Current delivery: **0.5.0 build 12**. See [release notes](RELEASE-0.5.0.md) for the Duo layout fixes, native BB2 ports/multipliers and nine-layout BB3 preview, including remaining limitations.

# Blasterball iOS 0.4.2 — build 11

2026-10-26. Native UIKit/SpriteKit prototype using original BB2 assets.

Open/fullscreen mode uses the original PC composition stretched to fill the gameplay area. A separate 64–96 point steering strip below keeps your thumb away from the paddle. Closed Duo uses native adaptive navigation controls when UIKit exposes verticalBarEdge; the scene then removes its duplicate sidebar. Other devices retain the compact sidebar fallback. The game never occupies only half the window. Native Duo rail appearance needs physical verification.

Readouts now share the navigation group with Pause and game selection; the bottom toolbar is removed. Landscape automatically uses PC presentation. The thumb strip has no hint text. The right readout includes high score and active powers; multiplier progression is pending and currently reads ×1.

Drag in the playfield to steer; release to launch. Pause opens restart, stage selection, game selection, Sound and Display layout controls. Revolution, Remix and Holidays each contain the first 12 original layouts and separate saves; BB3 remains in development. Audio uses original recordings. Paddle and powerup animation remain; the incorrect universal brick damage-frame loop is disabled pending better animation mapping.

Build11 passed 59 deterministic checks per edition on iPhone and iPad simulators, plus decode checks for 13 sound events and 2 music tracks per edition. Stretched PC landscape previews were visually inspected. Xcode Release signing and physical installation succeeded; the app was not launched. See build/delivery.json for the process-check result and RELEASE-0.4.2.md for details and limitations.

Signed IPA: build/Blasterball-0.4.2-build11-Developer.ipa. Use Blasterball.xcodeproj for developer signing; build.sh simulator and scripts/verify_simulator.py support simulator validation.
