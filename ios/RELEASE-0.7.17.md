# Blasterball 0.7.17 (build 35)

Experimental UIKit/SpriteKit reconstruction for iPhone and iPad. Includes artwork game and edition launchers, rounded hover/touch halos including Settings, Duo laptop controls, BB2 editions, and the current BB3 reconstruction.

The iOS bundle ID changes to `com.wireproof.blasterball`. The name and approved icon are unchanged. This creates a separate app container from the previous prototype ID. Existing saves are not automatically migrated by this public IPA. Back up prior saves before switching identities.

Build35 repackages the completed build34 executable and resources with new bundle metadata. Its development-signed counterpart was installed on both authorized physical devices, with each device's preferences and documents copied and verified by readback. Neither app was launched; runtime loading and visual behavior were not tested in this delivery.

The public IPA has its development signature and embedded provisioning profile removed and must be signed for your device. Source includes all current project game resources, audio, menu artwork and icon assets. No player saves or device provisioning profiles are included. Gameplay reconstruction and visual fidelity remain incomplete; this is a prerelease.
