# Blasterball 0.4.2 — build 11

2026-10-26. Correct native readout placement and clean landscape presentation.

Device screenshots showed that native navigation buttons adapted to the right edge but the custom toolbar readout remained at the bottom. The toolbar is now always hidden and empty. The readout is a navigation bar item alongside Pause and game selection, containing stage, score, high score, lives, multiplier and active powerups. Native-side placement still requires physical verification because installed simulators run iOS18.4.

Powerup status reflects current ball count, paddle width and speed rather than a stale last-pickup label. High scores persist in all display modes. The multiplier displays the current flat ×1 scoring honestly; original multiplier progression has not yet been implemented.

Landscape automatically selects original PC presentation and hides the native navigation group. PC override does likewise in portrait. The bottom thumb steering strip remains functional but its hint text is removed. No bottom toolbar is created. Powerup popup labels are suppressed when the native sidebar is active.

Validation: 59 checks per edition passed on both simulators, including active-power state and high-score/multiplier readout content, plus 13-event and 2-track audio decode checks per edition. Landscape screenshot inspected. Xcode Release build and signature verification succeeded. Installed on Duo without launch; process result recorded in build/delivery.json.

Remaining scope: original multiplier rules, complete BB2 mechanics/campaigns, BB3 gameplay and editor are pending.
