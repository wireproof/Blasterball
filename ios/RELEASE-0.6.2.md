# 0.6.2 build 15

Cover sidebar uses muted labels, white monospaced values, grouped spacing, and localized numbers without leading zero padding. Empty POWER row is omitted; multiplier tokens remain beneath stats. Same layout for BB2/BB3.

BB3 collision ceiling now matches the 18-unit top bar rather than inheriting the 35-unit BB2/adaptive inset. Vertical rails terminate beneath the top bar, which spans both rails; removes protruding seams. Paddle height unchanged.

BB2 lost-life mapping changes from die.wav to original pdestroy.wav per edition. BB3 previously mapped ordinary life loss and game over to identical Level_Fail.wav. The source sound.txt names that cue GameLost; it is now reserved for final loss, with original PaddleForm (paddle_form.wav, source volume 127/255) used for replacement paddle. Exact native loss-animation and sound sequencing remains unverified. Final-life BB2 destruction plays before gameover; BB3 avoids reformation sound when no life remains.

All four editions passed gameplay/audio simulator checks; new BB3 ceiling alignment and actual rebound assertions passed. Final typography and frame styling visually checked on Duo simulator. Physical installation is without launch, so speaker and device visual verification remain user-side.
