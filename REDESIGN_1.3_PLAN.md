# CleanFotos 1.3 "Noir" — Implementation Plan

Handoff for Claude Code. Goal: ship the redesign **fast** without breaking the
deletion model. Read `PROJECT_NOTES.md` first. Its platform lessons still apply.

- Version: `1.3.0+19`
- Branch: `noir-1.3`
- Design source: the "CleanFotos Redesign" canvas, page "Noir · feel & rewards" (owner: Alexandra).
  Every value you need is copied into this file, so you don't need the canvas.
- Sounds: `assets/sounds/*.wav` + `assets/sounds/README.md` (already in the repo).

---

## 0. Ground rules (read before touching code)

**Never change:**
- Bundle/package id `com.crocodata.cleanpics`, IAP id `cleanpics_pro`, AdMob unit ids.
- `PhotoManager.setIgnorePermissionCheck(false)` in `main.dart`.
- The deletion model in `AppProvider`: persisted `pending_delete_ids`, the `_isFlushing`
  guard, de-duplication, clearing only after `deleteAssets()` returns, and
  "declining is final". This plan changes what `deleteAssets` **returns**, not how it deletes.
- The consent order (ATT → UMP → AdMob) and the rule of max one interstitial per 4 min.

**Work rules:**
- Work in the phases below, in order. Commit after each phase, and `flutter analyze` with zero **errors** each time.
- Phase 1 alone is a shippable hotfix (`1.2.2`) if the redesign slips.
- Every new user-facing string goes into `AppStrings` (base) **and** all 6 overrides (es, de, fr, pt, it, pl).
- Don't import `intl` (it's not a direct dependency). Use the small number formatter in §2.4.

**Decisions already made (ask Alexandra before deviating):**
1. **Dark-only.** Noir is the only theme. Remove the Theme setting, set `themeMode: ThemeMode.dark`
   and keep the `AppTheme` getters returning the Noir values, so old call sites still compile.
2. **No confetti.** Remove every `CelebrationOverlay` use. The celebration moves to the
   Finished screen, **after** the OS confirms the deletion.
3. **No overscroll navigation and no idle hints** in group modes. Use explicit buttons instead.
   Delete the `IdleGestureHint` usage.
4. **No coachmark tour on Home.** The new Home explains itself. Keep a one-time hint on the
   first swipe card only (§5.3).
5. **No streaks and no daily goals.** Milestones only (§4).

---

## Phase 0 — Prep (15 min)

- [ ] `git status`: commit the pending `video_group_review_screen.dart` / `idle_gesture_hint.dart`
      changes on `main` as "1.2.1 idle-hint fix" (or stash them if 1.2.1 is already live without them).
- [ ] Confirm with Alexandra whether 1.2.1+18 shipped. If not, 1.3 replaces it.
- [ ] `git checkout -b noir-1.3`, then bump `pubspec.yaml` to `version: 1.3.0+19`.
- [ ] Add to `pubspec.yaml`:
  ```yaml
  dependencies:
    audioplayers: ^6.1.0        # SFX; check it resolves with the current Flutter SDK
  flutter:
    assets:
      - assets/sounds/
    fonts:
      - family: Geist
        fonts:
          - asset: assets/fonts/Geist-Regular.ttf
          - asset: assets/fonts/Geist-Medium.ttf
            weight: 500
          - asset: assets/fonts/Geist-SemiBold.ttf
            weight: 600
          - asset: assets/fonts/Geist-Bold.ttf
            weight: 700
  ```
  Get the Geist TTFs (SIL OFL) from https://github.com/vercel/geist-font/releases into `assets/fonts/`.
  Bundle them; don't use `google_fonts`, because the app must work offline.
- [ ] `flutter pub get` and `flutter analyze`.

---

## Phase 1 — Fix: newest photos don't appear (ship first)

**Root cause.** `AppProvider` loads the library once (`prepare()` → `_warmUp()` → `ensurePhotos()`)
and caches `allPhotos` / `groups` for the whole process lifetime. `ensurePhotos()` returns the cache
whenever `photosLoaded`. Nothing listens for library changes. `didChangeAppLifecycleState` only
re-runs `prepare()` when permission was denied. iOS keeps the app alive in the background for days,
so photos taken since the first launch never show up until the user finds and taps **Refresh**.

**Fix (in `lib/providers/app_provider.dart` + `lib/services/photo_service.dart`):**
- [ ] Add `DateTime? lastScanAt` and `bool _libraryStale = false`.
- [ ] In `prepare()` after permission is granted, register a change listener once:
  ```dart
  PhotoManager.addChangeCallback(_onLibraryChanged);
  PhotoManager.startChangeNotify();
  ```
  `_onLibraryChanged` sets `_libraryStale = true` and debounces (1.5 s) a call to `reloadLibrary()`.
- [ ] New `Future<void> reloadLibrary({bool silent = true})`:
  - Skip it while a cleanup screen is open (track `bool inCleanupSession`, which every mode
    sets on enter and exit). It runs when the user is back on Home instead.
  - `PhotoManager.releaseCache()`, then reload assets, regroup, update stats, set
    `lastScanAt = now`, `_libraryStale = false`, `groupsLoaded = photosLoaded = true`.
    Also reset `videoGroupsLoaded = false` so video groups rebuild lazily.
  - `silent: true` never sets `state = AppState.loading` (no spinner, Home stays usable).
    Expose `bool isRescanning` for the freshness line.
- [ ] On app resume (`HomeScreen.didChangeAppLifecycleState` → `resumed`): call
      `reloadLibrary()` if `_libraryStale` or `lastScanAt` is older than 60 s.
- [ ] `ensurePhotos()` / `ensureGroups()`: if `_libraryStale`, reload before returning the cache.
- [ ] `PhotoService.totalCount()`: use `PhotoManager.getAssetCount(type: RequestType.image, filterOption: _newestFirstFilter)`
      instead of loading every asset. Keep `loadAllAssets()`'s album merge as is (OEM safety).
- [ ] Do the same for videos in `VideoService.totalCount()` (`RequestType.video`).
- [ ] Remove the **Refresh** button from Home and add a `RefreshIndicator` (pull-to-refresh) on
      Home that calls `reloadLibrary(silent: false)` as a hidden fallback. Keep `refresh()` for
      that, but stop clearing resume cursors there.
- [ ] iOS limited access: the limited-access banner action calls `PhotoManager.presentLimited()`
      on iOS ("Select more photos") and `PhotoManager.openSetting()` on Android.
- [ ] Dispose: `PhotoManager.removeChangeCallback` / `stopChangeNotify` aren't needed at app
      level, but guard against registering twice.

**Done when:** with the app open, you take a photo in the Camera app, switch back, and the photo
count goes up and the new photo is the first card in One by one, all within ~2 s, with no spinner
and no Refresh tap. This works on both iOS and Android.

---

## Phase 2 — Noir foundation

### 2.1 Tokens — new `lib/theme/noir.dart`
```dart
class Noir {
  // colours
  static const bg       = Color(0xFF0A0A0C);
  static const surface  = Color(0xFF17171B);
  static const surface2 = Color(0xFF232329);
  static const text     = Color(0xFFF4F4F5);
  static const muted    = Color(0xFFA1A1AA);   // 7.7:1 on bg
  static const faint    = Color(0xFF71717A);   // locked/disabled only, never body text
  static const line     = Color(0x14FFFFFF);   // 8% white hairline
  static const accent   = Color(0xFFFFFFFF);   // primary buttons, selected tab, progress
  static const onAccent = Color(0xFF0A0A0C);
  static const danger   = Color(0xFFD63A2C);   // delete only; white text = 4.7:1
  static const reward   = Color(0xFFF5C451);   // milestones only, nowhere else
  static const onReward = Color(0xFF1A1405);
  // radii
  static const rCard = 24.0, rPhoto = 28.0, rThumb = 14.0, rPill = 999.0;
  // spacing
  static const pad = 20.0, gap = 16.0, gapS = 12.0, gapXS = 8.0;
  // sizes
  static const iconButton = 44.0, button = 60.0, bigButton = 64.0;
}
```
Typography (family `Geist`, letterSpacing as a multiple of the font size):

| Role | Size / weight | Letter spacing | Colour |
|---|---|---|---|
| display (Finished number) | 46 / 600 | -0.03em | text |
| h1 (Home title, Milestones total) | 36 / 600 | -0.03em | text |
| h2 (card titles) | 22 / 600 | -0.03em | text |
| bar title (screen header) | 18 / 600 | -0.03em | text |
| body | 16 / 400–500 | 0 | text or muted |
| secondary | 15 / 400 | 0 | muted |
| caption / meta / counters | 13–14 / 600–700 | 0 | muted |
| button | 17 / 700 | 0 | per button |

The existing "16pt minimum" rule applies to body copy. Captions/counters at 13–14 are intentional.
Keep the 1.0–1.4 text scaler clamp. Layouts must not overflow at 1.4 (use `Flexible`/`FittedBox` on buttons).

### 2.2 Theme
- [ ] `AppTheme`: make `background/surface/textPrimary/textSecondary/divider` return the Noir values.
      `lightTheme` and `darkTheme` both build the Noir dark `ThemeData` (fontFamily `Geist`,
      `scaffoldBackgroundColor: Noir.bg`, `ColorScheme.dark(primary: Noir.accent, error: Noir.danger, surface: Noir.surface)`).
- [ ] `main.dart`: `themeMode: ThemeMode.dark`, status bar icons light. Remove the `themePref` usage
      (keep the pref key unused; there's no migration needed).
- [ ] Dialogs (`AlertDialog`), `SnackBar` and bottom sheets styled with Noir colours in the theme.
- [ ] Splash / launcher background: change `flutter_native_splash` colours to `#0A0A0C` in both
      light and dark, then run `dart run flutter_native_splash:create`. The icon stays as it is.

### 2.3 Shared widgets — new `lib/widgets/noir/`
| Widget | Spec |
|---|---|
| `NoirIconButton` | 44×44 circle, `surface` fill, 1 px `line` border, 20 px icon in `text`, required `semanticLabel`. |
| `NoirButton` | height 60 (or 64 via `big:`), pill radius, 17/700 label, optional leading icon 22. Variants: `primary` (white/black), `danger` (`danger`/white), `secondary` (`surface2`/text + `line` border), `ghost` (transparent/muted). Has a disabled state. |
| `NoirCard` | `surface`, 1 px `line` border, radius 24, padding 16–18. |
| `NoirSegmented` | container `surface2`, padding 4, pill radius. Each tab is 44 tall, 15/700. Selected tab: white bg, black text. Unselected: transparent, muted. |
| `NoirHeader` | row of [leading NoirIconButton] [centered title 18/600 + subtitle 13 muted] [trailing widget or 44 px spacer]. |
| `PendingPill` | centered pill, 1 px **dashed** border `#FFFFFF47` (CustomPainter, no new package), trash icon 15 + "3 marked · ~11 MB" 14/600 `#D4D4D8`. |
| `NoirToast` | white pill, black 15/700 text, shadow `0 10 30 #66000000`, sits 112 px above the bottom, auto-hides after 1.4 s. |
| `ProgressTrack` | 4 px tall (6 px for milestones), `surface2` track, fill `accent` (or `reward` for milestones), pill ends, 300 ms animated width. |
| `ThumbStack` | 92×120 box with 3 thumbnails, each 76×96, radius 14, 2 px `surface` border, rotated −8°, +5° and 0°. Use `AssetEntityImage` thumbnails (ThumbnailSize 200). |

### 2.4 Helpers
- [ ] `String formatCount(int n)`: thousands separators by locale (en `26,414`; de/es/it/pt/pl `26.414`;
      fr `26 414`). Write it by hand, without intl.
- [ ] `String formatBytes(int)`: reuse `PhotoGroup.formatBytes`, and show MB with one decimal under 10 MB.

---

## Phase 3 — Sound and haptics

New `lib/services/feedback_service.dart` (singleton, like `AdService`).

```dart
enum Fx { mark, unmark, detent, delete, keep, undo, groupDone, groupKeep, success, milestone, declined, tap }
```

| Fx | Sound file | Haptic (Flutter `HapticFeedback`) |
|---|---|---|
| mark | `mark.wav` | `selectionClick()` |
| unmark | `unmark.wav` | `selectionClick()` |
| detent (drag crosses the decide line, either way) | — | `selectionClick()` |
| delete | `delete.wav` | `mediumImpact()` |
| keep | `keep.wav` | `lightImpact()` |
| undo | `undo.wav` | `lightImpact()` |
| groupDone ("Delete n · Next") | `group_done.wav` | `mediumImpact()` |
| groupKeep ("Keep all · Next") | `keep.wav` | `lightImpact()` |
| success (OS prompt confirmed) | `success.wav` | `lightImpact()` → 80 ms → `mediumImpact()` |
| milestone (0.9 s after success) | `milestone.wav` | success pattern → 120 ms → `heavyImpact()` |
| declined (OS prompt denied) | — | `mediumImpact()` → 80 ms → `mediumImpact()` |
| tap (tabs, toggles) | — | `selectionClick()` |

Implementation:
- [ ] `init()` at app start (in `AppProvider.init`): set a global audio context so iOS uses the
      **ambient** category (obeys the silent switch, mixes with music, never pauses it):
  ```dart
  await AudioPlayer.global.setAudioContext(AudioContextConfig(
    respectSilence: true,
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build());
  ```
  Preload one `AudioPlayer` per file with `PlayerMode.lowLatency` and
  `setSource(AssetSource('sounds/<file>.wav'))`, at volume 0.5.
- [ ] `play(Fx fx)`: check `soundsEnabled` / `hapticsEnabled` from `AppProvider`. Throttle sounds:
      drop one if another started < 50 ms ago (haptics are not throttled). For a replay, call
      `stop()` then `resume()`, wrapped in try/catch. A sound failure must never break a flow.
- [ ] Settings → new section **"Feedback"** with two switches, **Sounds** and **Haptics** (both default on),
      persisted as `sounds_enabled` / `haptics_enabled` in `SharedPreferences`.
- [ ] Reduce Motion (`MediaQuery.disableAnimations`): skip the fly-out, count-up and slide animations.
      Haptics and sounds still play.

**Done when:** each Fx in the table fires exactly once at its event on a real iPhone and a real
Android phone. The silent switch mutes sounds on iPhone, and Spotify keeps playing during a session.

---

## Phase 4 — Honest deletion results + rewards

### 4.1 `deleteAssets` returns a result
```dart
class DeleteResult {
  final int requested, deleted, bytes;
  final bool declined;              // user said no / nothing deleted
  final bool usedTrash;             // Android moveToTrash fallback was used (affects summary wording)
  final Milestone? newMilestone;    // highest milestone newly crossed, if any
}
```
- [ ] `deleteAssets()` and `flushPendingDeletions()` return `DeleteResult` (update all callers).
- [ ] **Real sizes:** in `flushPendingDeletions()`, after resolving ids to assets and **before**
      deleting, measure each asset with a new `PhotoService.assetBytes(asset)`:
  - Android: `(await asset.file)?.lengthSync()` (a real path, so it's fast).
  - iOS: only if `await asset.isLocallyAvailable()`, then `(await asset.originFile)?.lengthSync()`.
    Never trigger an iCloud download.
  - Run the measurements in parallel with an overall 2 s timeout. Anything unmeasured falls back to
    `kAvgPhotoBytes` / `kAvgVideoBytes`. If profiling shows iOS is slow, use estimates on iOS for 1.3
    and note it.
  - Sum the bytes **only for ids confirmed gone** by `_confirmDeleted`.
- [ ] Persist two new prefs, `measured_bytes` and `measured_count`, and use them for the
      "average photo size" in milestone equivalents (fallback `kAvgPhotoBytes`).
- [ ] Add `unqueueDeletion(List<AssetEntity>)`, which removes ids from `pending_delete_ids` (for Undo).

### 4.2 Milestones — new `lib/models/milestone.dart` + logic in `AppProvider`
- Ladder (bytes, using 1024): **100 MB, 250 MB, 500 MB, 1 GB, 2 GB, 5 GB, 10 GB, 25 GB, 50 GB**.
- `milestone_index` pref = the highest index reached (−1 = none).
- [ ] After a successful flush, compare `freedBytes` before and after. If it crossed one or more
      milestones, set `newMilestone` to the **highest** one crossed, celebrate it once, and save the index.
- [ ] **Migration** (first launch of 1.3, when the key is missing): set `milestone_index` to the tier
      already reached by the existing `freed_bytes`, **silently**, so it doesn't retro-celebrate.
- [ ] Equivalent text: `room for about N new photos`, where `N = bytes / avgPhotoBytes`, rounded to
      2 significant figures (30, 70, 140, 290, 580, 1,400…).
- Progress only counts confirmed deletions. In-session numbers are always labelled "marked" and "~".

---

## Phase 5 — Screens

Every screen uses `Noir.bg`, `SafeArea`, horizontal padding 20, top padding 12 below the safe area,
bottom padding 28, and a vertical gap of 16 unless stated otherwise.

### 5.1 Home (`home_screen.dart`, rewrite `_buildReady` and `_buildHeader`)
From top to bottom:
1. **Header row:** logo (34×34, radius 10, white, black check icon) + "CleanFotos" 20/600 · right: `NoirIconButton` (settings / sliders icon) → Settings.
2. **Freshness line:** an 8 px white dot + "Up to date · checked just now" (14, muted).
   While `isRescanning`, show "Looking for new photos…" with a pulsing dot. Use "checked N min ago" after 1 min.
   If `limitedAccess` is true, show the limited-access banner here instead (restyled as a `NoirCard` with a button).
3. **H1:** "Clean up your library".
4. **`NoirSegmented`:** "Photos · 26,414" | "Videos · 2,201". The counts come from `getAssetCount`.
   The first switch to Videos runs the existing video-permission flow. If it's denied, the Videos tab
   shows the cards with the meta pill "Allow access", and a tap opens `_showVideoAccessDialog`.
5. **Mode card 1** (`NoirCard`, full width, row: text column + `ThumbStack`):
   - Photos: title "Similar shots", desc "Bursts and retakes, grouped together.", meta pill "4,207 groups".
     Show "Finding groups…" until `groupsLoaded`. The thumbnails are the first 3 assets of the newest group.
   - Videos: "Similar clips", "Videos shot minutes apart, side by side.", meta "2,201 videos".
   - Tap → `_openMode(swipe:false)` / `_openVideoMode(grouped:true)`.
6. **Mode card 2:** "One by one". Photos desc: "Every photo, newest first." with meta "26,414 photos".
   Videos desc: "Every video, newest first. Hold to play." Show a single thumbnail of the newest asset.
   Tap → swipe modes.
7. `Spacer`.
8. **Milestone card** (`NoirCard`, tappable → Milestones screen):
   - Row 1: "Next milestone" (13 muted) … "72 MB to go" (13 muted).
   - Row 2: a 40 px ring with a 2 px `reward` border and the tier label ("100") inside in `reward`, plus
     a column of "28 MB" 20/600 and " of 100 MB freed" 15 muted, and below it a `ProgressTrack` (6 px, reward fill).
   - Before any deletion: "Free your first 100 MB" with an empty bar.
   - When every tier is reached: "All milestones reached · 52 GB freed".
9. **"Remove ads · one-time purchase"** ghost text button (14/600 muted, 40 tall). Non-Pro only.
   It opens the existing purchase flow.
10. Banner ad (non-Pro), below everything and inside the safe area, as today.

Remove: the 4 gradient mode cards, the orange Pro card, the Refresh button, the stats row, the
saved-summary card, `CelebrationOverlay` and the coachmark tour.
The "finish your cleanup" pending dialog stays, restyled.
The loading dialog when opening a mode stays, but becomes a small centered white spinner on 60% black.

### 5.2 Shared session flow
- Every mode sets `provider.inCleanupSession = true` on enter and `false` on exit.
- **Finish** = the header X button, or reaching the end of the deck/groups.
  - If nothing is marked, pop to Home (no summary).
  - Otherwise call `flushPendingDeletions()` → OS prompt → push `SessionSummaryScreen(result)`,
    replacing the mode route.
- Delete the per-mode "You're done!" screens (`_buildDoneScreen`, `_buildDone`) and the
  `deleteFailed` snackbar on exit.
- **Interstitial ad + review prompt:** keep `_afterMode`, but run it only after the user leaves the
  **summary** screen, never on top of the celebration.

### 5.3 One by one (`swipe_screen.dart` and `video_swipe_screen.dart`)
- `NoirHeader`: leading X ("Finish"), title "One by one", subtitle "{n} reviewed" (cards decided this
  session), trailing `NoirIconButton` with an undo icon, disabled when there's no history.
  Remove "26421 left".
- `PendingPill` under the header: "{n} marked · ~{size}" (estimate: count × avg size). Hide it when n = 0.
- **Card stack:** current card radius 28, shadow `0 18 40 #47000000`, bottom inset 16. The next card
  sits behind it at scale 0.95, translateY +14 and opacity 0.5. The date chip sits bottom-left
  (14 px inset): black 55%, white 14/600, pill. Format: "Today, 09:14" / "Yesterday, 23:02" /
  "Sun, Oct 4" (this year) / "Sep 27, 2024".
- **Drag:** keep the threshold at 100 px. Fire `Fx.detent` once when |dx| crosses the threshold, and
  again if it crosses back. Keep the existing DELETE/KEEP overlay label opacity.
- **Buttons row:** `NoirButton.danger(big, icon trash, "Delete")` + `NoirButton.secondary(big, icon check, "Keep")`, 12 px apart.
- **Footnote** (13 muted, centered): "Marked photos are deleted when you finish — you confirm once."
- **Undo:**
  - Keep a history stack of `(index, action)`, capped at 50.
  - Undoing a delete removes the asset from `_pendingDelete` and calls `provider.unqueueDeletion`.
  - Ad cards are skipped and never undone. The undo slides the card back in from the side it left.
- **First-run hint:** the very first card, once ever (pref `swipe_hint_seen`), shows an overlay
  "Swipe left to delete · right to keep". It hides on the first swipe.
- Remove the per-swipe `celebrate()` and the two instruction lines.
- **Video variant:** same layout. Keep "hold to play", and the `Fx` mapping is identical.
  The footnote says "videos".

### 5.4 Similar shots / Similar clips (`group_review_screen.dart` and `video_group_review_screen.dart`)
- `NoirHeader`: leading X, title = group time ("Today, 12:37"), subtitle "{n} similar photos",
  trailing counter "{i} / {total}" (13/700 muted).
- `ProgressTrack` (4 px) right under the header, with −4 px top margin.
- Hint row: "Tap the photos you don't want" (15/600 muted).
- **Grid:** 2 columns, 10 px gap, square tiles, radius 24, `ListView`/`GridView` scroll for big groups.
  - Marked tile: 3 px `danger` border, image opacity 0.45, a 30 px `danger` circle with a white
    trash icon (16) at top-right (8 px inset).
  - Tap toggles the mark (`Fx.mark` / `Fx.unmark`). Long-press keeps the existing detail view;
    for video, hold-to-play stays.
- **Bottom bar:** `NoirButton.secondary` square 60×60 with a chevron-left icon (previous group,
  disabled on the first group) + a primary CTA filling the rest of the width:
  - Nothing marked → `primary` "Keep all · Next" → `Fx.groupKeep`.
  - n marked → `danger` "Delete {n} · Next" → `Fx.groupDone`, then `NoirToast` "+~{size} marked".
  - On the last group, the CTA label ends with "· Finish".
- Remove the overscroll navigation (`_onScrollNotification`, `_navLock`, `_overscroll`),
  `IdleGestureHint`, the "Tap again to deselect" text and the `celebrate()` calls.
- Keep `_queueSelected()` → `queueForDeletion()` exactly as it is.

### 5.5 Finished — new `lib/screens/session_summary_screen.dart`
Input: `DeleteResult`, plus a media type (photos/videos/items).
- **Confirmed** (`deleted > 0`):
  1. Play `Fx.success` on enter.
  2. A white 88 px circle with a black check icon (40), then the display number "{bytes} freed",
     counting up from 0 over 600 ms (skip it with Reduce Motion). The count-up stops at the measured value.
  3. Body (16 muted, max 300 wide): "{n} photos moved to Recently Deleted. You can restore them there
     for 30 days." Android wording: "…moved to the trash…" when `moveToTrash` was used.
     Otherwise, on Android 11+ without trash, say "{n} photos deleted."
  4. If `newMilestone` is set: after 900 ms, play `Fx.milestone` and slide in (300 ms) the
     **milestone card**:
     - `NoirCard` with a 1 px border `reward` at 45%.
     - A 56 px `reward` circle with the tier in `onReward` ("100" 17/700 over "MB" 10/700).
     - "MILESTONE REACHED" 13/700 `reward`, tracking 0.06em, and the line "{total} freed in total —
       room for about {N} new photos." (16).
     - Below it: "Next: 250 MB … 138 MB to go" (13 muted) and a `ProgressTrack` with the reward fill.
  5. Buttons: `primary` "Keep going" (back into the same mode, with the next items) and `ghost` "Back to home".
- **Declined** (`declined == true`): play `Fx.declined`. Show a `surface2` circle with an info icon,
  the h1 "Nothing was deleted", and the body "Your photos are untouched and your marks were cleared.
  No progress was counted.", then the `primary` button "Back to home".
- **Partial** (some deleted, some still there): treat it as Confirmed with the real counts.

### 5.6 Milestones — new `lib/screens/milestones_screen.dart`
- `NoirHeader` with a back chevron and the title "Milestones".
- The total "{freed}" in h1 style (44/600), then "freed in total · {n} photos deleted" (15 muted).
- A `NoirCard` list (padding 6×16). Each row is 10 px vertical, with a hairline divider
  `#0FFFFFFF` between rows:
  - Reached: 36 px `reward` circle with a black check. Label 16/600 text. Trailing "Reached {date}".
    Store a `milestone_dates` JSON map when a tier is reached; migrated tiers have no date, so show "Reached".
  - Current: 36 px ring with a 2 px `reward` border and the percent (11/700 `reward`) inside.
    Label plus a 5 px progress bar below it. Trailing "{freed} of {tier}".
  - Locked: 36 px `surface2` circle with a lock icon in `faint`. Label in muted. Trailing "≈ {N} photos".

### 5.7 Settings (`settings_screen.dart`)
- Restyle with Noir: section headers 13/700 muted with 0.06em tracking, `NoirCard` groups and Noir switches
  (thumb white, active track `#3F3F46`, the selected state has a white outline).
- Sections: **Feedback** (Sounds, Haptics), **Progress** (one row "Milestones" → Milestones screen,
  plus Total freed and Deleted), **Language**, **Remove ads**, **About** (rate, privacy, ad privacy
  options, version).
- Remove the Theme section and the old 6-row statistics list.

### 5.8 Other states
Restyle the permission-denied, error and loading states, and the video-access and pending-cleanup
dialogs, with Noir tokens. The copy is unchanged unless it's listed in §6.

---

## Phase 6 — Strings (EN source; translate into es, de, fr, pt, it, pl)

| Key | English |
|---|---|
| homeTitle | Clean up your library |
| tabPhotos(n) | Photos · {n} |
| tabVideos(n) | Videos · {n} |
| upToDate | Up to date · checked just now |
| checkedAgo(m) | Up to date · checked {m} min ago |
| lookingForNew | Looking for new photos… |
| similarShots / similarShotsDesc | Similar shots / Bursts and retakes, grouped together. |
| similarClips / similarClipsDesc | Similar clips / Videos shot minutes apart, side by side. |
| oneByOne | One by one |
| oneByOnePhotosDesc / oneByOneVideosDesc | Every photo, newest first. / Every video, newest first. Hold to play. |
| groupsCount(n) / photosCount(n) / videosCount(n) | {n} groups / {n} photos / {n} videos |
| findingGroups | Finding groups… |
| allowAccess | Allow access |
| nextMilestone / toGo(size) / ofFreed(size) | Next milestone / {size} to go / of {size} freed |
| firstMilestone | Free your first 100 MB |
| allMilestones(size) | All milestones reached · {size} freed |
| removeAdsLink | Remove ads · one-time purchase |
| reviewed(n) | {n} reviewed |
| markedPending(n, size) | {n} marked · ~{size} |
| confirmOnceNote / confirmOnceNoteVideos | Marked photos are deleted when you finish — you confirm once. / (videos) |
| swipeFirstHint | Swipe left to delete · right to keep |
| similarCount(n) | {n} similar photos |
| tapToMark | Tap the photos you don't want |
| keepAllNext / deleteNext(n) / finishSuffix | Keep all · Next / Delete {n} · Next / · Finish |
| markedToast(size) | +~{size} marked |
| freed(size) | {size} freed |
| movedToRecentlyDeleted(n) | {n} photos moved to Recently Deleted. You can restore them there for 30 days. |
| movedToTrash(n) / deletedPlain(n) | {n} photos moved to the trash. / {n} photos deleted. |
| milestoneReached | MILESTONE REACHED |
| milestoneLine(total, n) | {total} freed in total — room for about {n} new photos. |
| nextTier(size) | Next: {size} |
| keepGoing / backHome | Keep going / Back to home |
| nothingDeleted / nothingDeletedBody | Nothing was deleted / Your photos are untouched and your marks were cleared. No progress was counted. |
| milestones / freedInTotal(n) | Milestones / freed in total · {n} photos deleted |
| reachedOn(date) / reached / aboutPhotos(n) / ofTier(a, b) | Reached {date} / Reached / ≈ {n} photos / {a} of {b} |
| feedback / sounds / haptics | Feedback / Sounds / Haptics |
| progress | Progress |

Pluralise "photo/photos" and "video/videos" the way `strings.dart` already does. Delete the unused
strings (refresh, swipeHint, recoverHint, idleSwipeHint, tapToDeselect, theme*, monetizationTips,
tip1–4, developerTip*).

---

## Phase 7 — Cleanup, QA, release

### Remove
`CelebrationOverlay` (and the `confetti` dependency if nothing else uses it), `IdleGestureHint`
usages, `CoachmarkOverlay` usage on Home, the overscroll navigation code, the per-mode done screens,
the Refresh button, the old gradient mode-card builder and the Theme setting.

### QA on real devices (one iPhone, one Android 13+, ideally one Samsung)
- [ ] **New photos:** take a photo with the app in the background, return, and see it as the first card and in the count without a tap.
- [ ] **Limited access** (iOS "Selected Photos" / Android "Selected"): the banner shows and the action opens the picker or settings.
- [ ] **One by one:** delete/keep/undo ×20 fast. The sounds don't stack, Undo restores the right card, and the pending pill is correct.
- [ ] **Force-quit** mid-swipe → relaunch → the "finish your cleanup" dialog shows the right count (the 1.2.1 behaviour still works).
- [ ] **Similar shots:** mark/unmark, Delete n · Next, Keep all · Next, Previous, the last group → Finish.
- [ ] **OS prompt Delete:** the summary shows the measured MB. It matches roughly what Settings/Storage reports.
- [ ] **OS prompt Don't Allow:** the "Nothing was deleted" screen appears, there's no progress, and nothing is asked again.
- [ ] **Milestone:** with a test build, set `freed_bytes` to 95 MB, delete 2 photos, and the milestone fires once. Doing it again doesn't re-fire it.
- [ ] **Upgrade from 1.2.x** with existing `freed_bytes`: there's no retro celebration and the Home card shows the correct next tier.
- [ ] **Silent switch on (iPhone):** no sound, haptics still play. Music playing: it isn't paused or ducked.
- [ ] **Settings:** Sounds/Haptics off are respected immediately and survive a restart.
- [ ] **Text size at the max (1.4):** no overflow on Home, the buttons or the summary.
- [ ] **Videos tab:** the permission flow, both video modes, hold-to-play, delete → summary.
- [ ] **Ads (non-Pro):** banner on Home; the interstitial only after leaving the summary and max once per 4 min. A Pro user sees no ads and no "Remove ads" link.
- [ ] `flutter analyze` is clean of errors, and release builds pass on both platforms.

### Release
- [ ] New store screenshots (Noir): Home, One by one, Similar shots, Finished with a milestone, Milestones.
- [ ] Release notes, both stores (Play ≤ 500 chars):
  ```
  A brand-new CleanFotos.
  • New look: calm, dark, and all about your photos.
  • Your newest photos now show up instantly — no more Refresh.
  • Clear buttons for every step, plus Undo.
  • Gentle sounds and haptics (switch them off in Settings).
  • Milestones that count only real space freed, measured from your actual files.
  ```
- [ ] iOS: commit + push → Codemagic `ios-testflight` → check that the log shows `1.3.0 (19)`.
      In App Store Connect, also set the **Marketing URL** to `https://crocodata.net` (open TODO).
- [ ] Android: `flutter clean && flutter pub get && flutter build appbundle --release` → Play Console.
      Check that release signing is set up. Also rename the Play listing to "CleanFotos" (open TODO).
- [ ] Update `PROJECT_NOTES.md`: Noir tokens, the FeedbackService, DeleteResult/milestones, the
      library change listener, and that confetti and overscroll navigation were removed on purpose.

---

## Suggested commit sequence
1. `fix: auto-reload library on change/resume; count via getAssetCount` (Phase 1, can ship as 1.2.2)
2. `feat: Noir tokens, Geist font, shared widgets, dark-only theme` (Phase 2)
3. `feat: FeedbackService with sounds and haptics + settings toggles` (Phase 3)
4. `feat: DeleteResult with measured sizes, milestones + migration` (Phase 4)
5. `feat: Noir Home + Milestones screen` (5.1, 5.6)
6. `feat: Noir swipe modes with undo` (5.3)
7. `feat: Noir group modes with explicit navigation` (5.4)
8. `feat: session summary screen; remove confetti/done screens` (5.2, 5.5)
9. `feat: Noir settings + restyled states` (5.7, 5.8)
10. `i18n: 1.3 strings in 7 languages` (Phase 6)
11. `chore: remove dead code, bump 1.3.0+19, notes` (Phase 7)
