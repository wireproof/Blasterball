# Twin correction

The screenshot's T is Twin. The port used two 36%-width normal images and inherited prior Mini/Grow width. Original BB2 help says Twin divides the paddle with a middle gap.

Static original executable evidence (same SHA-256 as release39): native 0x41f760 case4 draws variant0 twice with no horizontal image scaling. Assembly at 0x41f882 and 0x41f8b7 offsets centers by native half-span minus40. Initial half-span 0x42100000 =36; 0x41f9b0 adds1.5 at each of30 transition steps, ending81, so final centers are +/-41. Constant0x5203d8=40, 0x520760=1.5; transition threshold0x5203f8 is double0.01. Original mode4 remains until replacement; no15-second expiry in the recovered mode code. Evidence is static original-code/asset analysis, not original Windows runtime testing.

Correction: two normal65-unit paddle images with original texture aspect ratio, centers+/-41, full147-unit movement footprint, collision/aim against each actual paddle, visible middle gap, power-up and enemy contact aligned with both paddles. Twin normalizes prior Mini/Grow and remains until replaced/life/stage. BB3 behavior unchanged. Split/merge transition animation is not reproduced by this fix.
