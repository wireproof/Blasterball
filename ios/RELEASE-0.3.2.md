# Blasterball 0.3.2 — build 8

2026-10-26. Fullscreen arena and original sprite animation pass.

The arena walls now stay at the window edges independently of horizontal safe-area insets; the HUD retains safe-area protection. Original chrome corner crops are masked to remove their baked-in scenery, straight top-rail cropping is tightened and hinges draw above the rail. The scenery crop excludes the original border shadow and keeps uniform aspect-fill scaling.

Original atlas frames now animate brick highlights (17 frames), the paddle (8 frames) and falling powerups (16 frames). Retained REA atlas evidence: ../research/asset-analysis/atlas-mapping.json. Paddle interval is 0.1 seconds; brick/drop cadence is an adaptation, not verified original runtime timing. Shadows use original sprite silhouettes. A denser fading cyan trail and procedural impact sparks improve motion cues; these effects are adaptations, not extracted original effects.

Validation: 51 engine/asset/layout checks per edition on iPhone and iPad simulators, plus decode checks for 13 audio events and 2 music tracks per edition. Screenshot review covers frame composition and sprite appearance. These checks do not prove device rotation behavior or complete original-game fidelity.

Playable scope remains first 12 layouts per BB2 edition. BB3, full campaigns, remaining special mechanics and level editor remain pending. Installation details are recorded in build/delivery.json.
