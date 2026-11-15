# 0.7.7 build 25

Corrected BB2 enemy destruction visuals: ordinary enemies use the original16-frame burst at0.02seconds per frame, original cell size, and no added cyan rays. Exploders use original green spark frames and ring-pattern particles with one-second lifetime, randomized rotation/velocity, and gravity. Removed the orange outline. Breaker fragments and damage semantics are preserved. BB3 is included without changing its effect rendering. Saves are not reset.

Validation: Revolution102, Remix102, Holidays102, BB3381 simulator checks passed; all four audio inventories decoded. Xcode Release build and deep/strict code-sign verification passed. Duo and iPad Pro install/version readback both confirmed0.7.7/build25. Neither physical app was launched.

Evidence and rendering adaptations: research/explosion-visuals-build25/FINDINGS.md. Exact Windows pixel parity and effect2 launch/burst sound parity are not claimed.
