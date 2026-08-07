# CleanFotos 1.2 — Release Notes

Version: `1.2.0+16`

## "What's New" (App Store / Play Store — paste this)

```
NEW: Video Group — the group cleanup you know from photos, now for videos. Hold any video to play it right in the grid.

• NEW: Video Group — videos taken moments apart, side by side
• Hold a video to play it instantly, with sound
• Picture Group is faster: no more Next button — just pull past the top or bottom to move between groups
• Marked photos are now removed in one go when you finish, instead of asking every time
• Helpful arrows appear if you're unsure what to do
• Fresh colours so each cleanup mode is easy to tell apart
```

## Promotional text (170 chars)

```
Video Group is here: your look-alike clips side by side, hold any tile to play it. Plus a faster Picture Group — pull between groups, delete everything in one go.
```

## What actually changed

### New — Video Group
- Videos grouped by capture time, exactly like Picture Group.
- Each tile shows a thumbnail, a play badge and the clip length.
- **Hold a tile to play it inline**, with sound, looping. Release to stop.
  Only one player exists at a time, built on press and disposed on release.
- Blue accent, distinct from Video Swipe's teal.

### Picture Group — reworked
- **The "Next" button is gone.** Pull past the bottom of the grid for the next
  group, past the top for the previous one. Normal scrolling inside a group is
  untouched (it's an *overscroll* gesture, so the two never conflict).
- **Deletions are batched.** Marked items queue as you move between groups and
  are deleted in ONE system prompt when you leave — previously every group
  change could trigger its own OS dialog.
- Idle coach: after ~4s of no interaction, bouncing arrows explain the gesture.
  Any touch dismisses it.
- Accent recoloured to rose so it matches Picture Swipe.

### Home
- Mode order is now Video Group → Video Swipe → Picture Group → Picture Swipe.
- Colour families: blues for video, pinks/reds for photos.

### Fixes
- iOS video playback: `contentUri` is Android-only; iOS now uses the file API,
  so playback works on iPhone in both video modes.

## Release checklist

- [ ] `flutter analyze` (expect info/warnings only, no errors)
- [ ] `flutter run` — verify on device:
      - [ ] Video Group: hold a tile → plays inline with sound
      - [ ] Overscroll moves between groups in both group modes
      - [ ] Marked items deleted in ONE prompt on exit
      - [ ] Idle arrows appear after ~4s, vanish on touch
      - [ ] Four mode cards, four distinct colours, new order
- [ ] Commit + push
- [ ] Codemagic `ios-testflight` → confirm log says `Building 1.2.0 (…)`
- [ ] App Store Connect → new version **1.2** → attach build → paste What's New
- [ ] Android: `flutter build appbundle --release` → upload to Play Console
