# Blasterball 0.7.19 (build 37)

Fixes the Pause control appearing alone over the black startup screen. Both custom and native Pause controls remain hidden/disabled until the scene completes its first update. Switching editions resets this visibility; stale callbacks from a previous load are ignored. Game selection remains available during loading and recovery.

iOS Release, simulator and Mac Catalyst compilation passed. Physical installation on iPhone Duo and iPad Pro was verified with unchanged preferences and documents; neither physical app was launched. Startup and post-load Pause checks are recorded separately in the release validation.

The public IPA is unsigned and requires signing for the intended device. This remains an experimental reconstruction. All current project assets are included; bundle identity and icon are unchanged.

Simulator validation: BB2 and BB3 reported Pause hidden before loading and before the first frame, then hittable with the pause menu presented. BB3's initial fixed one-second tap missed; the repeat passed. A simulator screenshot also confirmed Pause visible alongside the loaded BB3 game. Physical startup visuals remain untested.
