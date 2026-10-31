# Blasterball 0.4.0 — build 9

2026-10-26. Original PC composition and Duo cover presentation.

The floating top HUD is removed. The open/PC layout uses the complete original 640×480 backdrop, including both side panels, logos and continuous chrome. The arena returns to original x125…515 bounds. Stage, lives, score and a locally retained high score appear beside the playfield. Dynamic text is a native condensed font, not the original bitmap font. The 4:3 image fits uniformly; other screen proportions can have black margins, especially portrait.

Closed Duo uses a compact arena with a right-side status panel. UIKit UIHingeInteraction observes closed/open state on iOS 27.1+. Updates settle for 0.25 seconds. If closed Duo retains inner-sized window bounds, gameplay occupies the right half of the usable window. Native narrow cover windows, including rotated ones, are not halved again. Actual hinge delivery and cover bounds still require physical-device confirmation. Pause → Display layout offers Automatic, Original PC fullscreen and Closed Duo · right screen overrides. UIKit system menus retain their normal modal presentation.

The compact sidebar and dynamic labels adapt to portrait/landscape. The PC layout preserves the original art without the earlier independently assembled rail seams. Original paddle/powerup animations remain. The universal brick idle-frame loop is disabled because it exposed damage/crack frames on intact bricks; comprehensive original idle animation mapping is pending.

Verification: 55 deterministic engine, asset and layout checks per edition on iPhone and iPad simulators, plus 13 sound-event and 2 music-track decode checks per edition. Tests include open 4:3 fitting, right-half selection for a retained inner window, no double-split of a native cover in either orientation, grid bounds and live-run preservation. PC landscape and forced right-screen screenshots were reviewed. Xcode signature and installation results are in build/delivery.json. No physical app launch is authorized after installation.

Playable scope remains the first 12 original layouts per BB2 edition. BB3, full campaigns, further original mechanics and editor remain pending.
