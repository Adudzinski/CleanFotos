# CleanFotos 1.4 "Noir" — Release Notes

Version: `1.4.0+21` (versionCode 21). App Store version name: **1.4**
(the redesign was planned as "1.3"; App Store Connect already had a 1.3
version, so it ships as 1.4).

A brand-new look and a calmer, more honest cleanup flow. Built from
`REDESIGN_1.3_PLAN.md`.

---

## App Store

**All 7 languages** (name, subtitle, promotional text, description, What's
New, keywords): see `APPSTORE_LISTING_1.4.md`, generated and length-checked
by `tool/appstore_listing.py`. The English texts below are the same.

### What's New in This Version — 749 / 4000 chars

```
A brand-new CleanFotos.

• A calm new design, built around your photos.
• Your newest photos show up by themselves — and a Refresh button is there whenever you want to look again.
• Pick up where you left off: each mode remembers your place, even after you close the app. Or start with the newest — your old place stays saved.
• Swipe to keep or delete, with Undo.
• Similar shots: tap the retakes you don't want, then move on with one tap — or pull past the end of the grid to the next group.
• See the space you really freed, and reach milestones from 100 MB to 50 GB. Nothing is counted until you confirm.
• Easier to read: text now follows your iPhone's text size, up to twice as large.
• Gentle sounds and haptics — switch them off in Settings.
```

### Promotional text — max 170 chars (editable any time, no review)

**Option A — 157 chars** (recommended: names what people asked for)

```
New look, same quick cleanup: your newest photos appear by themselves, Undo while you swipe, and CleanFotos remembers where you left off — even back in 2019.
```

**Option B — 142 chars**

```
Clean up your library, calmly: swipe with Undo, tidy bursts side by side, pick up where you left off, and celebrate the space you really free.
```

Both are accurate on iOS too: freed space there is estimated per photo, so the
copy says "space you really free" (only confirmed deletions count), never
"measured".

### Screenshots

Six per iPhone display class, in `assets/store/1.4/`, in upload order:

| App Store Connect slot | Folder | Size |
|---|---|---|
| 6.9" | `appstore_6.9/` | 1320 × 2868 |
| 6.5" | `appstore_6.5/` | 1284 × 2778 |
| 6.3" | `appstore_6.3/` | 1206 × 2622 |
| 6.1" | `appstore_6.1/` | 1179 × 2556 |

Uploading the 6.9" set is normally enough (smaller iPhones get scaled
copies); use the others when a slot asks for its own size.

1. Swipe to keep or delete
2. Bursts and retakes, side by side
3. See the space you really freed
4. Clean up your library, calmly
5. Pick up where you left off
6. Milestones that keep you going

Built by `tool/store_screenshots.py` from emulator captures of the real app
(demo photos are generated, not stock). The Android status bar and gesture
bar are cropped off, as Apple rejects other-platform chrome.

---

## Google Play

### Release notes (en-US) — 411 / 500 chars

```
<en-US>
A brand-new CleanFotos.
• Calm new design, built around your photos.
• Newest photos show up by themselves, plus a Refresh button.
• Each mode remembers where you left off.
• Swipe to keep or delete, with Undo.
• Similar shots: tap, then Next — or pull to the next group.
• Milestones for space you really freed.
• Text grows with your phone's text size, up to 2x.
• Gentle sounds and haptics (off in Settings).
</en-US>
```

### Graphics

- Phone screenshots: `assets/store/1.4/play_phone/` (1080 × 1920, 9:16 —
  Play caps the long side at 2× the short side), same six as above.
- Feature graphic: `assets/store/1.4/play_feature_graphic.png` (1024 × 500).
- App icon unchanged (`assets/store/play_icon_512.png`).

---

## What actually changed

### Pick up where you left off
- Each mode remembers your position, even after closing the app. The card
  says "Left off at Sep 27, 2019"; tapping it asks: continue there, or start
  with the newest ("New since last time: 12 photos"). Looking at new photos
  never loses your old position. (1.x had the code for this, but it was
  never connected — every session started at the top.)

### Bigger text for people who need it
- Text now grows up to 2x with the phone's text-size setting (was capped at
  1.4x); every screen was checked at 2x.

### Newest photos appear by themselves (was the #1 complaint)
- The library is re-scanned in the background when it changes (photo_manager
  change notifications, debounced 1.5 s) and on resume after 60 s. No
  spinner. A **Refresh** button next to "Up to date" (and pull-down) is
  there for when you want to look again yourself.
- Automatic re-scans first compare a cheap fingerprint (photo count + newest
  photo) so iCloud sync churn doesn't trigger full scans.
- Re-scans wait while a cleanup mode is open or a deletion runs.
- iOS "Selected photos": the banner opens the picker; Android opens Settings.

### Noir design
- Dark-only theme, Geist font (bundled), new tokens and shared widgets.
- New Home: freshness line, Photos/Videos tabs with counts, two mode cards
  ("Similar shots/clips", "Swipe"), next-milestone card.
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

## Known limits in 1.4
- **iOS freed sizes are estimates** (~3.5 MB per photo, ~30 MB per video).
  photo_manager can only hand out an original on iOS by copying it into the
  app's cache, which for a batch of videos means gigabytes of writes before
  the delete prompt. Android measures real file sizes.
- The AdMob consent form still says "CleanPics" — rename the app in the
  AdMob console (not in the code).

---

## Play upload package (prepared 2026-10-08)

- **Bundle:** `build/app/outputs/bundle/release/app-release.aab` (61 MB)
  - versionName `1.4.0`, versionCode `21`, package `com.crocodata.cleanpics`
  - Signed with the upload key: `CN=Crocodata, O=Crocodata, C=PL`,
    SHA-256 `B2:B9:3C:73:67:F7:48:EE:D2:07:84:BC:BB:A6:8A:55:BC:01:40:6E:23:47:B0:87:9B:8C:D3:11:C0:14:3C:69`
  - Rebuild after any change: `flutter build appbundle --release`
    (the `.aab` is not in git).
- **Play Console → Production → Create new release:** upload the `.aab`,
  paste the release notes above, review, roll out.
- **App content checks for this release:**
  - *Photo and video permissions:* the manifest now also declares
    `READ_MEDIA_VISUAL_USER_SELECTED` (Android 14+ "Select photos"). The
    existing declaration (core purpose: photo cleanup) still applies; if Play
    asks, the use is the same.
  - *Data safety:* unchanged — no new data leaves the device (sounds,
    milestones and saved positions are stored locally).
- **Store listing (Main store listing):** replace the screenshots with
  `assets/store/1.4/play_phone/` and the feature graphic, and rename the
  listing title to "CleanFotos" (still an open item).
- Play may warn about missing native debug symbols / deobfuscation file —
  harmless (no R8 minification; Flutter's native libs ship stripped).

## Release checklist
- [ ] QA on real devices (plan §7 list) — iPhone and Android 13+.
- [x] New store screenshots (Noir) and feature graphic — `assets/store/1.4/`.
- [ ] iOS: run Codemagic `ios-testflight` on `main` → check the log shows
      `1.4.0` with a build number above the last TestFlight build.
- [ ] App Store Connect: What's New + promotional text (above), the 6.9" and
      6.5" screenshots, and the **Marketing URL** `https://crocodata.net`.
- [x] Android: release `.aab` built and verified (see Play upload package).
- [ ] Play Console: upload, release notes, screenshots, feature graphic,
      rename the listing to "CleanFotos".
- [ ] AdMob: rename the app from "CleanPics" (consent form title).
