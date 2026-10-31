# 0.6.4 build 17

Pause control is raised above the transparent steering overlay. Native rail sheets use only the native bar-button anchor instead of also anchoring to a hidden UIKit button. Simulator verification performs window hit testing, dispatches the control action and checks paused state plus actual menu presentation.

BB2 wall/enemy events now map to bbreak.wav and critter.wav, respectively, based on native collision evidence in research/impact-audio-build17/FINDINGS.md. Ball/critter contact now requests the enemy sound in both games. Existing BB3 impact samples verified against originals. Working death mappings untouched.

Round ball, powerup, enemy and HUD-token sprites compensate for nonuniform arena scaling. Sprite artwork keeps its native proportions while the arena still fills the display. Original art can include perspective/glow; no asset redrawing. BB3 instrument panels narrowed to clear arena chrome. BB2 desktop stats use grouped, centered white labels with constrained widths over dark panels, retaining lower original logos.

All runtime/visual tests use simulators. Physical delivery is install-only, without launch. Speaker output and physical touch behavior remain user-verified.
