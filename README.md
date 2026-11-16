# Blasterball for iOS

An experimental UIKit and SpriteKit reconstruction of Blasterball for iPhone and iPad, including adaptive iPhone Duo layouts. It includes Blasterball 2 Revolution, Remix and Holidays, plus an evolving Blasterball 3 implementation, with game artwork, sprites, animations and audio.

## Current release

**0.8.0, build 38** adds an in-app BB2 level editor with custom-level save/import/export/play, restores missing BB2 power-ups and special-brick behaviors, corrects several BB3 enemy/brick effects, and adds faithful cached 2× Revolution texture enhancement. It also reduces repeated save, HUD, trail, and overlay work. Open the launcher Settings gear → Level Editor / Custom Levels. See [custom-level documentation](docs/CUSTOM-LEVELS.md).

This is a prerelease reconstruction. Exact native AI, some BB3 abilities/effect timing, and the reported crescent-marked group-switch mechanic remain unverified. The first editor authors BB2 grids, not BB3 polygon/boss levels or original Windows world files. Simulator gameplay/editor checks passed. Version 0.8.0 (38) was installed on both iPhone Duo and iPad Pro, with preferences and Documents verified unchanged by before/after readback. Neither physical app was launched; physical runtime, performance, and visual testing were not performed.

Changing from the previous `com.wireproof.blasterball.prototype` identifier creates a separate app container. The public IPA does not automatically transfer previous saves. Keep the old app and back up its data before migrating.

## Build

Open [`ios/Blasterball.xcodeproj`](ios/Blasterball.xcodeproj) in Xcode, select your signing team, and build for iPhone or iPad. The standalone source has no dependency on the development workspace's shared-source symlinks. `ios/build.sh simulator` builds the simulator app; `ios/build-xcode.sh` wraps the Xcode build.

The release IPA is **unsigned** and must be signed for your device. It corresponds to build38, with development signing and the embedded device provisioning profile removed. See [release notes](ios/RELEASE-0.8.0.md).

## Assets

All current project assets are included: game resources and level data in `ios/Resources`, audio, BB2 and BB3 sprites, menu backgrounds, icon assets in `ios/Assets.xcassets`, and design artwork in `ios/Artwork`. [`ASSET-MANIFEST.json`](ASSET-MANIFEST.json) records their file hashes. Player saves, credentials and signing profiles are not included.

## Credits

This is an independent reconstruction, not an official WildTangent release. Original Blasterball names, artwork and audio are credited to their respective creators.
