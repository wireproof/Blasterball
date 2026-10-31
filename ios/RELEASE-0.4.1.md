# Blasterball 0.4.1 — build 10

2026-10-26. Incorporates the clarified right-side controls request and thumb clearance feedback.

The game never selects only half the window. On Duo, UIKit verticalBarEdge selects native navigation and toolbar controls: Pause, game selection, and a stage/score/lives readout. A UINavigationController supplies the system-adaptive bars; the status bar is visible with the native rail. When that rail is active the scene uses a 420-unit arena without the redundant 110-unit in-game sidebar. Platforms without the native rail retain the compact sidebar fallback. Original PC side panels remain in open mode.

PC presentation now stretches to fill the available gameplay rectangle, as requested, rather than letterboxing at 4:3. A 64–96 point steering strip beneath the game provides thumb clearance. Sliding there maps to the same paddle positions as the playfield; releasing launches. Touch cancellation does not launch. The existing playfield steering remains available.

57 deterministic checks per edition passed on both iPhone and iPad simulators. Checks cover full-width layout, a separate thumb strip below the playfield, native-rail geometry without a duplicate sidebar, rotation, gameplay preservation and original assets. Audio decode checks passed for 13 events and two tracks per edition. A stretched landscape screenshot was visually inspected. Xcode signing and device installation succeeded; app intentionally not launched.

Limit: installed simulator runtimes are iOS18.4. Native iOS27.1 vertical-bar integration compiled against Apple SDK headers but its actual Duo arrangement and custom readout placement require on-device visual testing. Thumb ergonomics also remain user-tested. Original assets, saves and gameplay scope are preserved; BB3, full campaigns, remaining mechanics and editor are still pending.
