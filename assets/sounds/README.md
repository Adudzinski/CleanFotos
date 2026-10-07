# CleanFotos sounds

One sound family (soft sine bells, C major), 44.1 kHz mono 16-bit WAV, ~360 KB total.
Spec and playable previews: the "Noir · feel & rewards" page of the CleanFotos Redesign canvas.

| File | Length | Event | Haptic |
|---|---|---|---|
| mark.wav | 80 ms | tap a photo to mark it | selectionClick |
| unmark.wav | 80 ms | tap again to unmark | selectionClick |
| — | — | swipe drag crosses the decide line | selectionClick |
| delete.wav | 220 ms | delete (swipe left / button) | mediumImpact |
| keep.wav | 200 ms | keep (swipe right / button), group "Keep all · Next" | lightImpact |
| undo.wav | 240 ms | undo | lightImpact |
| group_done.wav | 500 ms | group "Delete n · Next" | mediumImpact |
| success.wav | 1.1 s | system delete prompt confirmed | success notification |
| milestone.wav | 1.7 s | lifetime milestone crossed (play 0.9 s after success) | success + heavyImpact |
| — | — | system delete prompt declined | warning notification |

Playback rules
- iOS audio session category **ambient** (obeys the silent switch, mixes with music, never pauses it).
- Android: low-latency player mode; preload all files at startup.
- Volume ~0.5. Drop a sound if another one started less than 50 ms ago.
- Settings toggles: Sounds (default on), Haptics (default on), persisted in SharedPreferences.
- Reduce Motion: skip animations, keep haptics and sounds.
