# Original Blasterball artwork

The current Revolution campaign uses assets extracted from the supplied Blasterball 2 Revolution installer. Resources/Original/provenance.json records each source, packaged path and SHA-256. Files are bundled byte-for-byte, with original palette and dimensions. The generated Backdrop.png from build4 is retained in the workspace as historical artwork but is no longer a project resource.

REA findings and native decompiler evidence are in ../../research/asset-analysis/. Original atlas cells and embedded grayscale transparency masks are decoded at runtime. The arena portion of each original background is cropped to fit the existing mobile playfield; baked desktop side labels are omitted in favor of the native mobile HUD. Native touch buttons remain adaptations.

Scaling uses SpriteKit linear texture filtering at display resolution, rather than inventing detail through generative upscaling. Original files remain available for future higher-resolution restoration comparisons. The generated app icon remains the separately requested reference-inspired icon.

This artwork pass does not establish original runtime physics, animation timing, or complete special-brick behavior. BB3 assets remain extracted for a future BB3 campaign.
