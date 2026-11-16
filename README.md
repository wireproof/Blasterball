# Blasterball for iOS

An experimental UIKit and SpriteKit reconstruction of Blasterball for iPhone and iPad, including adaptive iPhone Duo layouts. It includes Blasterball 2 Revolution, Remix and Holidays, plus an evolving Blasterball 3 implementation, with game artwork, sprites, animations and audio.

## Current release

**0.7.19, build 37** keeps Pause hidden until game content is ready, eliminating the lone button on the black startup screen. It retains iPad trackpad steering: the paddle follows horizontal pointer movement without holding a click, over the game or lower control area. It also includes illustrated game and edition selection screens, rounded border-only hover and touch highlights (including Settings), and a laptop paddle-control deck aligned with the playfield. The iOS app identifier is now `com.wireproof.blasterball`; its name and icon are unchanged.

This is a prerelease reconstruction. Gameplay mechanics and visual fidelity remain incomplete. The development-signed build37 was installed on iPhone Duo and iPad Pro with saved preferences and documents migrated and verified by file readback. Neither app was launched during delivery, so runtime save loading and current physical-device visuals remain unverified. Historical simulator checks are not a substitute for testing this release on a device.

Changing from the previous `com.wireproof.blasterball.prototype` identifier creates a separate app container. The public IPA does not automatically transfer previous saves. Keep the old app and back up its data before migrating.

## Build

Open [`ios/Blasterball.xcodeproj`](ios/Blasterball.xcodeproj) in Xcode, select your signing team, and build for iPhone or iPad. The standalone source has no dependency on the development workspace's shared-source symlinks. `ios/build.sh simulator` builds the simulator app; `ios/build-xcode.sh` wraps the Xcode build.

The release IPA is **unsigned** and must be signed for your device. It corresponds to build37, with development signing and the embedded device provisioning profile removed. See [release notes](ios/RELEASE-0.7.19.md).

## Assets

All current project assets are included: game resources and level data in `ios/Resources`, audio, BB2 and BB3 sprites, menu backgrounds, icon assets in `ios/Assets.xcassets`, and design artwork in `ios/Artwork`. [`ASSET-MANIFEST.json`](ASSET-MANIFEST.json) records their file hashes. Player saves, credentials and signing profiles are not included.

## Credits

This is an independent reconstruction, not an official WildTangent release. Original Blasterball names, artwork and audio are credited to their respective creators.
