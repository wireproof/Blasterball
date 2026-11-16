# BB2 original power-up comparison

Original executable SHA-256: ef95e5aef3c9e493bc22542de012ece573d2bd40462c05e0a75cd336ad332b08. Original files remained unchanged; analysis used an identity-verified extracted copy.

REA launcher failed during Java ownership preparation. The installed Ghidra 12.1.4 engine ran directly, offline. Whole-program analysis reached its 240-second limit, so selected function entries were explicitly disassembled/decompiled afterward. Findings below are static code/asset evidence, not an observation of the running Windows game. Decompiler output retains warnings and incomplete type recovery.

- Laser spawn: native 0x420490 and its input caller. Fire interval is the double at 0x520778 = 0.25 seconds. Shot positions use x +/-14 (0x520770) and y-24 (0x52042c). Caller checks held-input flags 0x49/0x4a and paddle mode 3. Touch hold/drag fires continuously; a release/tap can request one shot in this mobile adaptation.
- Laser velocity: native 0x4233a0 initializes player-shot Y velocity to -360 (0xc3b40000); update 0x423430 integrates it. World-to-SpriteKit changes the Y sign.
- Laser appearance: original laser.png contains four 32x32 additive frames; native 0x42362f advances frame every 0.1 seconds. Native 0x41f760 draws paddle variant 3 in laser mode. 0x41f2a0 and 0x41fdf0 enter it through variant 6, frames 7 down to 0 at 0.05 seconds/frame; 0x41fe60 reverses it when leaving.
- Attach: 0x41f0e0 enables sticky flag 0x15, with original sound event 0x15. 0x41f760 draws a 64x32 slice from sticky.png, cycling four rows. 0x41f110 removes it and releases attached balls. 0x41ffe0 removes sticky when selecting a different paddle mode. Laser/Attach are paddle states, not the port's previous 15-second timers.
- Catcher: retained native 0x4080c0 draws two additive 390x50 barrier.png windows scrolling at +200/-150 pixels/sec, top-left (125,430). Original help says it saves one ball. The implementation retains it until one downward ball is saved; it no longer expires after 30 seconds. Its visible field and bounce height now coincide.
- Original laser.wav contains MPEG audio in a WAV container and failed AVAudioPlayer preparation. laser-pcm.wav is a PCM decode of the same recording; original remains included. See audio-provenance.json.

Boundaries: mobile input, adaptive geometry, effect mixing, and simulation integration are adaptations. Full original-game parity is not claimed. Phantom power and phantom-brick behavior are unchanged by this follow-up.
