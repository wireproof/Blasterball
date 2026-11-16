# Blasterball for iOS

An experimental UIKit and SpriteKit reconstruction of Blasterball for iPhone and iPad, including adaptive iPhone Duo layouts. It includes Blasterball 2 Revolution, Remix and Holidays, plus an evolving Blasterball 3 implementation, with game artwork, sprites, animations and audio.

## Current release

**0.8.1, build 39** corrects the BB2 Laser, Attach and Catcher using original game code and artwork. Laser now fires paired travelling shots with the red paddle transformation; Attach shows its animated shield and retains the ball's contact position; Catcher remains until it saves one ball. Original power-up sounds are connected, including a PCM decode of the original laser recording for Apple playback. See [original-game evidence](docs/ORIGINAL-POWERUPS.md).

The in-app BB2 level editor, custom-level import/export/play, cached 2× Revolution texture enhancement, and earlier gameplay improvements remain included. Open the launcher Settings gear → Level Editor / Custom Levels. See [custom-level documentation](docs/CUSTOM-LEVELS.md).

This is a prerelease reconstruction. Exact native AI, some BB3 abilities/effect timing, and the reported crescent-marked group-switch mechanic remain unverified. The editor authors BB2 grids, not BB3 polygon/boss levels or original Windows world files. All 817 engine checks and all four edition audio checks passed in the simulator; the three corrected power-up visuals were inspected there. iOS Release and Mac Catalyst compilation passed. Version 0.8.1 (39) was installed on both iPhone Duo and iPad Pro, with preferences and Documents verified unchanged by before/after readback. Neither physical app was launched; physical runtime, performance, and visual testing were not performed.

Changing from the previous `com.wireproof.blasterball.prototype` identifier creates a separate app container. The public IPA does not automatically transfer previous saves. Keep the old app and back up its data before migrating.

## Build

Open [`ios/Blasterball.xcodeproj`](ios/Blasterball.xcodeproj) in Xcode, select your signing team, and build for iPhone or iPad. The standalone source has no dependency on the development workspace's shared-source symlinks. `ios/build.sh simulator` builds the simulator app; `ios/build-xcode.sh` wraps the Xcode build.

The release IPA is **unsigned** and must be signed for your device. It corresponds to build39, with development signing and the embedded device provisioning profile removed. See [release notes](ios/RELEASE-0.8.1.md).

## Assets

All current project assets are included: game resources and level data in `ios/Resources`, audio, BB2 and BB3 sprites, menu backgrounds, icon assets in `ios/Assets.xcassets`, and design artwork in `ios/Artwork`. [`ASSET-MANIFEST.json`](ASSET-MANIFEST.json) records their file hashes. Player saves, credentials and signing profiles are not included.

## Credits

This is an independent reconstruction, not an official WildTangent release. Original Blasterball names, artwork and audio are credited to their respective creators.
