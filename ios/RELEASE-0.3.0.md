# Blasterball 0.3.0 — build 6

2026-10-26. This build introduces a game library, playable Blasterball 2 editions, fullscreen adaptive gameplay and original audio. Blasterball 3 is visibly marked in development and is not playable yet.

## Library and progress

Choose Blasterball 2, then Revolution, Remix or Holidays. Each includes its first 12 original normal-campaign layouts, with its own artwork and independent saved progress. Existing Revolution progress uses the original save key. The pause menu holds restart, stage selection, changing games, and the Sound toggle.

## Fullscreen gameplay

The SpriteKit view fills the window. A compact HUD respects safe areas; there is no separate steering panel or permanent title. Drag on the arena to steer, release to launch. The board adapts to viewport shape and safe areas, keeping game sprites proportional. This changes travel distances compared with the desktop original; it is a mobile adaptation, not verified original physics parity.

## Sound

Original effects are bundled unchanged where iOS supports their encoding; MP3-in-WAV life-loss and game-over recordings are decoded to PCM WAV. REA static dispatch evidence determines normal launch/paddle, brick damage/destruction, life loss, stage start, game over, and six supported powerup cues. Original normal-stage tracks 1 and 2 alternate by stage. Ogg sources are preserved in research; AAC copies are provided for iOS playback. Sound can be toggled in the pause menu and pauses when gameplay pauses or the app loses focus. The Sound toggle controls playback even with the phone's silent switch on; device media volume still applies.

Wall and stage-clear cues remain silent because their original event mapping has not been established. Menu music, complete special mechanics, animation timing, bosses, full campaigns, BB3 gameplay and the editor remain pending. Audio decode/preparation is testable in the simulator; actual speaker output must be checked on the device.

## Validation and delivery

Run `python3 scripts/verify_simulator.py SIMULATOR_UUID` after a simulator build. This script targets only simulators, covers all three editions, and saves screenshots plus engine/asset/audio reports. Xcode signs the physical-device build with the existing developer team. Per the user's instruction, install on Duo without launching it; do not claim physical-device runtime tests for this build.

## Evidence

- `Resources/Editions/*/provenance.json`: original artwork provenance and conversions.
- `Resources/Campaigns/*.json`: first 12 original levels per edition.
- `Resources/Audio/provenance.json`: source/output digests and audio conversion details.
- `../research/asset-analysis/atlas-mapping.json`: sprite atlas/mask mapping.
- `../research/asset-analysis/audio-mapping.json`: original event mapping with limits.
