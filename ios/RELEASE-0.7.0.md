# 0.7.0 — Duo laptop mode

Upper half renders the classic landscape composition for Blasterball 2 and 3; lower half is a dedicated neon-grid paddle control deck. Touch position maps across the full playable paddle range, and release launches. The hinge gap separates the two surfaces. Original game assets and audio are unchanged.

Pause menu includes Display: Laptop mode / Automatic. Automatic mode enters laptop layout for a partially open hinge in portrait, using the installed UIKit hinge API. Physical posture detection and thumb ergonomics require user review; install does not launch the game.

Validation and delivery results are recorded separately in build artifacts.

Build 18 compiled for simulator and physical iOS; deep/strict code signature verification passed. All four editions passed the simulator regression suite. After the final 4:3 fit adjustment, BB3 smoke checks passed again and the laptop preview was visually inspected. Pause hit-testing/menu presentation passed in laptop mode. Physical hinge switching and touch ergonomics are not yet verified.
