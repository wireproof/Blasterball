# Blasterball 0.7.18 (build 36)

Fixes iPad trackpad and mouse steering requiring a pressed button. Hover movement now controls the paddle on iPadOS as well as Mac Catalyst, over both the game view and lower steering area. Horizontal cursor position maps to the playfield; cursor height does not move the paddle vertically. The laptop deck indicator follows the paddle. Existing touch and click-to-launch behavior is retained.

iOS Release compilation, deep strict signing verification, both device provisioning checks, and a Mac Catalyst compile check passed. Installed on iPhone Duo and iPad Pro; preferences and documents matched their pre-install backups byte for byte. Neither physical app was launched, so Magic Keyboard behavior, runtime gameplay and visual confirmation remain untested. No iPad mini installation or hardware test was performed.

The public IPA is unsigned and requires signing for the intended device. The reconstruction remains experimental; all current project assets are included in source. The bundle ID remains com.wireproof.blasterball and the approved icon is unchanged.
