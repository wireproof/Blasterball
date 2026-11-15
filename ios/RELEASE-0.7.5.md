# 0.7.5 build 23

Ordinary enemy/paddle contact now emits the destruction effect and enemy sound before removing the enemy. BB2 ordinary contact preserves lives and does not award points, matching retained native evidence. BB3 uses its existing enemy score value; paddle-specific scoring is an adaptation not separately traced.

BB2 evidence: research/asset-analysis/critter-motion-native-0x412d00.json, ev_99328a219d3f85a5ce2486c11bad1fdd7334865cc357082ec4bc4a56f683c881. Paddle branch dispatches sound 0, effect type 3, removal flag. Shipped help at research/bb2-revolution/app/help/en/gettingstarted.htm:460 and research/bb3/help/gettingstarted.htm:885 corroborates ordinary paddle destruction. Special hazard-flag paddle destruction remains separate and is not implemented here.

Door backing now extends the immediately adjacent original artwork edge into the aperture, rather than shifting a 23-pixel background tile into it. Hidden original pixels are not recoverable from the composite backdrop; this is a continuity repair, not original pixel recovery.
