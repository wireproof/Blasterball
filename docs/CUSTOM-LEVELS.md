# Custom level editor

Open the game launcher's Settings gear, then **Level Editor / Custom Levels**.

The first editor targets the Blasterball 2 grid. Choose a brick and an optional power-up, then tap cells to paint. Choose Erase to remove cells. Pinch to zoom and use Undo to reverse painting. Select one of the packaged Revolution backgrounds. Use **Files** to save, open, import, or export a level; **Play** saves and starts the edited layout from the beginning.

Levels are portable JSON files, maximum 256 KB, with formatVersion 1, UUID id, name, background, and cells. Each cell has row (0–19), column (0–12), type (1–12), property 0, powerup (0–16), critter 0. At least one breakable brick is required. Duplicate positions, resource paths, unknown format versions, and unsupported metadata are rejected. Background IDs are 1, 2, 4, 5, 6, 7, 9. Imported levels receive fresh IDs; imports cannot replace existing saved custom levels. Original campaigns, save keys, and high scores are separate.

This is not an importer for the original Windows game's binary world format and does not yet author BB3 polygon/boss stages. No separate Windows application is included. The shared UIKit editor compiles for Mac Catalyst, subject to platform build verification.
