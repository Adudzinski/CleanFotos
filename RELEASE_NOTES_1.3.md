# CleanFotos 1.3 "Noir" — Release Notes

Version: `1.3.0+19` · branch `noir-1.3`

A brand-new look and a calmer, more honest cleanup flow. Built from
`REDESIGN_1.3_PLAN.md`.

---

## What's New (both stores — Play max 500 chars)

**Recommended — 330 chars.** Accurate on both platforms: iOS 1.3 counts freed
space from per-photo estimates, not measured files (see "Known limits").

```
A brand-new CleanFotos.
• New look: calm, dark, and all about your photos.
• Your newest photos now show up instantly — no more Refresh.
• Clear buttons for every step, plus Undo.
• Gentle sounds and haptics (switch them off in Settings).
• Milestones that count only space you really freed — nothing is counted until you confirm.
```

**As written in the plan — 318 chars.** Only fully true on Android.

```
A brand-new CleanFotos.
• New look: calm, dark, and all about your photos.
• Your newest photos now show up instantly — no more Refresh.
• Clear buttons for every step, plus Undo.
• Gentle sounds and haptics (switch them off in Settings).
• Milestones that count only real space freed, measured from your actual files.
```

---

## What actually changed

### Newest photos appear by themselves (was the #1 complaint)
- The library is re-scanned in the background when it changes (photo_manager
  change notifications, debounced 1.5 s) and on resume after 60 s. No
  spinner, no Refresh button; pull down on Home as a hidden fallback.
- Automatic re-scans first compare a cheap fingerprint (photo count + newest
  photo) so iCloud sync churn doesn't trigger full scans.
- Re-scans wait while a cleanup mode is open or a deletion runs.
- iOS "Selected photos": the banner opens the picker; Android opens Settings.

### Noir design
- Dark-only theme, Geist font (bundled), new tokens and shared widgets.
- New Home: freshness line, Photos/Videos tabs with counts, two mode cards
  ("Similar shots/clips", "One by one"), next-milestone card.
- No confetti, no coachmark tour, no idle hints.

### Modes
- **Swipe** (photos and videos): Delete / Keep buttons, swipe still
  works, **Undo** (up to 50 steps), "3 marked · ~11 MB" pill, one-time swipe
  hint, hold-to-play for videos.
- **Similar shots / clips**: tap what you don't want, then "Delete n · Next"
  or "Keep all · Next", with a Previous button — or pull past the bottom/top
  of the grid for the next/previous group, as in 1.2. Going back shows
  what's already marked.

### Honest results
- **Finished** screen after the system prompt: real freed size, wording that
  matches what the OS did (Recently Deleted on iOS; trash or deleted on
  Android), "Keep going" resumes where you stopped.
- Declining the prompt shows "Nothing was deleted" and counts nothing.
- **Milestones** 100 MB → 50 GB, each celebrated once; upgraders are
  migrated silently (no retro celebration).
- Interstitial / review prompt / notification request only after you're back
  on Home, never over the celebration, never mid "Keep going".

### Sounds and haptics
- Soft UI sounds (iOS ambient session: silent switch respected, music keeps
  playing) and haptics. Settings → Feedback toggles both.

### Fixes along the way
- Changing the language no longer pops the notification-permission dialog.
- The photo count no longer drops when videos are deleted.
- Swipe-card DELETE/KEEP labels and "Hold to play" are now translated.

---

## Known limits in 1.3
- **iOS freed sizes are estimates** (~3.5 MB per photo, ~30 MB per video).
  photo_manager can only hand out an original on iOS by copying it into the
  app's cache, which for a batch of videos means gigabytes of writes before
  the delete prompt. Android measures real file sizes.
- The AdMob consent form still says "CleanPics" — rename the app in the
  AdMob console (not in the code).

---

## Release checklist
- [ ] QA on real devices (plan §7 list) — iPhone and Android 13+.
- [ ] New store screenshots (Noir): Home, One by one, Similar shots,
      Finished with a milestone, Milestones.
- [ ] iOS: push `noir-1.3` (or merge to `main`) → Codemagic `ios-testflight`
      → check the log shows `1.3.0 (19)` or higher.
- [ ] App Store Connect: set the **Marketing URL** to `https://crocodata.net`.
- [ ] Android: `flutter build appbundle --release` → Play Console
      (`build/app/outputs/bundle/release/app-release.aab`).
- [ ] Play: rename the listing to "CleanFotos".
- [ ] AdMob: rename the app from "CleanPics" (consent form title).
