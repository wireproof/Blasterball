# Blasterball 0.5.0 — build 12

October 30, 2026. Developer-signed Xcode update installed on Duo without launching.

Cover-screen status now uses its own scrollable view below the native Pause/game buttons, avoiding the clipped UIBarButtonItem capsule. Portrait always uses the adaptive arena and aspect-filled original scenery. Landscape clears obsolete side safe-area insets and fills the width, retaining a blank thumb steering strip. Removed conflicting manual portrait PC-stretch override.

BB2 original door sheets animate at the two top ports. Original critter sheets emerge through them with recovered initial velocity, looping frames, side bounces and ball-hit scoring. Native spawn probability is normalized to elapsed time. Advanced per-type behavior (darter surges, breaker fragments, layer brick placement) remains incomplete. Native BB2 multiplier tokens now add, cap at five, and expire after 20 seconds; damage/destruction scoring follows recovered ordinary brick rules. Saves remain compatible.

Blasterball 3 is selectable and playable with nine recovered normal layouts (538 bricks), original textures, audio, paddle and pickup artwork. Triangle empty regions and slope reflection use polygon collision. This is a preview, not a complete BB3 campaign: numbered template order is not proven campaign order; boss, gravity, secret and Blasterball special actions remain incomplete. Extra BB3 powers are mobile adaptations; Flash clears one brick and explosive hits nearby bricks. Full native effect behavior is not established.

Validation: all three BB2 editions pass 65 deterministic checks each; BB3 passes 27, on both iPad 18.4 and Duo 27.1 simulators. Original audio decoding passes 13 events and two tracks per edition. Duo cover screenshots show complete side readouts; iPad landscape screenshot shows edge-to-edge composition. Physical Duo folding transitions and gameplay are not tested because the app was not launched. Xcode Release build, signature and device provisioning verified.
