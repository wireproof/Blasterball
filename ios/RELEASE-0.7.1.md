# 0.7.1 build 19

Laptop steering input and visible deck now share the projected arena wall coordinates, excluding side panels. Finger x maps directly to paddle x, clamped by paddle width at the walls. Original inertial-paddle powerup behavior remains intentional.

BB2 retains its native random spawn chance with a 12-second maximum wait while the enemy pool has space. This bound is an iOS adaptation. BB3 retains source-defined generation intervals. Automatic scheduler tests now verify enemies spawn and enter the arena within 15 seconds on the opening stage, in addition to both door animation tests.

All four editions passed simulator regression checks. Laptop deck alignment and BB2 enemy entrance were visually inspected. Signed device build passed deep/strict signature verification. Physical gameplay is not tested because delivery is install-only.
