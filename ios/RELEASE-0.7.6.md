# 0.7.6 build 24

BB2 enemy behaviors now separate ball and paddle contact: Breaker ball hits create four original-art fragments with radius6 and speed180; fragments bounce off arena walls and apply one normal brick hit before disappearing. They do not act as player balls or collide with player balls. Exploder ball hits damage bricks within64 logical units, respecting brick durability. Ordinary paddle contact uses the common destruction path.

Darter/Breaker/Exploder use distinct movement and pause phases. Bricklayer moves on cardinal axes and can create a real type5 brick after sufficient direction cycles on an empty grid center; added bricks are saved with the run. Darter angular acceleration and exact native effect2/effect3 textures remain adaptations, not parity claims.

Original door atlas frames restored without sampled or stretched background fill. Fresh native REA trace confirms opaque source-pixel copying, including the black tunnel aperture. See research/critter-effects-build24/FINDINGS.md and supporting retained evidence.

Validation and delivery (2026-11-09): simulator engine checks passed for Revolution98, Remix98, Holidays98, BB3381, plus all four audio inventories. Signed Release build passed deep/strict code signature verification. Duo and iPad Pro installation and version readback confirmed0.7.6/build24; neither physical app was launched. Simulator screenshot shows both emerged enemies and closed ports; it is not evidence of every opening frame.

Overnight checkpoint: no build/install remains pending. Source and versioned builds retained; no physical save reset. Internal free space about30GiB and external137GiB at delivery; staging copy37MiB. No further packaging/storage need for this update. Next safe step is user gameplay feedback when awake, especially exact effect appearance and door-opening frames. No install blocker. Exact effect2/effect3 visual parity and Darter angular acceleration remain incomplete adaptations.
