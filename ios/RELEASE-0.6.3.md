# 0.6.3 build 16

## Original death audio

BB2 native life-loss function 0x421020 dispatches event 0xD, mapped to die.wav. Restored this recording for all BB2 editions; decoded PCM is identical to the original. Build 15's pdestroy.wav was incorrectly selected and belongs to projectile destruction. BB3 native death function 0x414de0 calls destruction FX and then dispatches EnemyDestruction, which maps to hitSounds/destroy_enemy.wav at source volume127 and rate1.0. Replaced the incorrect paddle-reformation cue; death is played for the last life as well. GameLost remains a separate final-loss event. PaddleForm is now a distinct unused respawn event pending faithful activation sequencing. See research/death-audio-build16 for static evidence and remaining timing limits. No claim of exact audiovisual parity or physical speaker review.

## BB3 large-screen layout

Cropped original instrument panels without white atlas padding or duplicate arena rails. Score and best sit above the panels; level, lives, and multiplier are centered within bounded columns. Long values scale to fit. Multiplier tokens use the left instrument panel, leaving Pause clear on the right. Pause placement refreshes after switching games. Non-native portrait sidebar uses a dark background with consistently spaced white readouts instead of cyan text floating on gameplay scenery.

## Verification

Simulator regression checks cover all editions; BB3 includes text-column containment and visible-top collision checks. Large-screen screenshot inspected for panel and Pause placement. Installation/signature/version/non-running evidence is recorded under ios/build. Physical app must remain unlaunched per user instruction.
