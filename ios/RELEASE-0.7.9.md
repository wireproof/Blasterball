# Blasterball 0.7.9 (build 27)

Duo cover gameplay and the laptop control deck now use the full window width. Gameplay owns the window directly, with paddle steering aligned to the visible playfield. Portrait uses the lower control deck, and Pause remains accessible.

Since 0.6.4, this release also includes the laptop presentation, restored BB2 sidebar artwork, bounded enemy spawn waits, and revised enemy contact, movement and destruction effects with their game assets. BB3 remains a reconstruction with incomplete original-game fidelity.

Validation: 106 simulator checks passed for each BB2 edition and 381 for BB3, plus audio inventory checks. Duo simulator measured matching window, game and deck widths, and verified Pause hit-testing and menu presentation. The signed build was installed on Duo without an automated launch; the owner subsequently confirmed the cover-screen correction works. This does not establish complete gameplay parity or exhaustive fold/rotation coverage.

The release IPA is the build-27 device artifact with its signature and provisioning profile removed. Sign with your own Apple development setup before installation. Original game assets retain their respective owners' rights; this release does not grant a license to those assets.
