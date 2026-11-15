# 0.7.2 build 20

- Portrait now always uses the upper classic game and lower aligned laptop control deck, independent of hinge status.
- BB2 classic side panels cover the entire side column with opaque backing, removing exposed strips and footer seams from the underlying composite background.
- Enemy ball collisions and Zap destruction use a dedicated explosion instead of brick spark effects. BB2 uses the recovered explode.png atlas; BB3 uses recovered fxs_spacexplosion01 artwork. Both have radial fragments and timed cleanup. Choreography is an adaptation, not verified frame-for-frame native parity. Existing hit and death audio remain unchanged.
- All four editions passed simulator regressions, including visible explosion-node checks and automatic enemy entrances. Xcode device build and deep/strict signature verification passed. Physical gameplay remains untested under install-only delivery.
