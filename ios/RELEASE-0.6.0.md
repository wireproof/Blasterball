# Blasterball 0.6.0 — build 13

## Duo presentation

The right-side status list now starts lower and measures accessible native button/control bounds, with periodic refresh for Live Activity layout changes. It is independently scrollable. Gameplay artwork and rails continue behind the transparent thumb-steering region to the bottom of the view. Logical arena extension preserves the paddle's prior screen height. Landscape uses the original side panels; numeric labels track the extended panel art.

## Doors and enemies

BB2 uses original eight-frame doors and masked critters with verified initial motion and spawn rules. BB3 now has two sliding-panel trapdoors, original layered enemy sprites, configured per-level pools, generation intervals and caps. Eleven nonboss enemy templates are included. Original multiply-blended enemy shadows are converted to equivalent black-plus-alpha sprites; 40 alpha regression checks pass. Specialized native enemy AI remains a mobile approximation.

## BB3 campaign and gameplay

Expanded from nine layouts to 100 regular source templates, including ten boss arenas, plus ten hidden-stage templates: 7,290 bricks. Added source-configured bosses with health saves, clear gating, shield/fuse interactions and attacks. Added special-brick effects, gravity, timed powers, laser, zap, attach/release, catcher, twin/phantom paddles, hover, inertia, replication and night/vision effects. Secret-stage routing saves the return stage. Original pickup sounds and boss music are included; regular music cycles through the three recovered tracks.

This is a substantial playable reconstruction, **not a finished faithful port**. The dark campaign is absent. Native campaign order, exact hidden-stage selection, boss/enemy AI, model animation and several special-effect semantics remain unverified or adapted. Boss1 uses flattened original model textures. See `research/BB3-CAMPAIGN-IMPLEMENTATION.md`, `research/bb3-boss-implementation.md` and `research/BB3-PORTS-ENEMIES.md` for evidence and limits.

## Validation and delivery

Integrated engine checks passed on Duo iOS27.1 and iPad iOS18.4 simulators: 74 per BB2 edition, 367 for BB3. BB3 audio validation decodes 34 event mappings and four music tracks. Asset alpha validation passes 40 checks. Simulator visual inspection covers cover-screen status, bottom extension, port enemies and a boss encounter. Final signature/install evidence is recorded in `build/delivery.json`. Physical folding transitions/gameplay remain unverified; user requested installation without launch.
