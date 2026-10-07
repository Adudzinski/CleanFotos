# CleanFotos — Project Notes

Working reference for the app: identities, credentials-adjacent config, hard-won
platform lessons, and the reasoning behind non-obvious design decisions.
Written so a future session (human or AI) can pick this up cold.

---

## 1. Identity & accounts

| Thing | Value |
|---|---|
| App name (both stores) | **CleanFotos** |
| iOS App Store name | CleanFotos: Group & Swipe |
| **Package / bundle ID** | `com.crocodata.cleanpics` ⚠️ permanent, cannot change |
| **IAP product ID** | `cleanpics_pro` ⚠️ permanent, cannot change |
| Apple App ID (numeric) | `6792250332` |
| Developer | Crocodata sp. z o.o. |
| Repo | https://github.com/Adudzinski/CleanFotos |
| Website | https://crocodata.net/cleanfotos/ |
| Privacy policy | https://crocodata.net/cleanfotos/privacy-policy.html |

> The `cleanpics` strings are historical (the app was renamed). They are
> invisible to users and **must not** be "fixed" — changing either would break
> the store listing and the purchase.

### AdMob (publisher `ca-app-pub-6352577985769083`)

| Unit | iOS | Android |
|---|---|---|
| App ID | `~1186188185` | `~6864043391` |
| Banner | `/2715012417` | `/7886470703` |
| Interstitial | `/1457650921` | `/8312856434` |
| Native | `/5587899409` | `/9710342782` |

Debug builds always use Google **test** IDs (`kDebugMode` check in
`ad_service.dart`) to avoid self-click strikes.

### Codemagic

- Workflow `ios-testflight`; integration name **`askra-asc-key`** (shared App
  Store Connect API key, also used by the Askra app — API keys are account-wide).
- `APP_STORE_APPLE_ID` lives in variable group **`appstore`**, not marked secure.
  It auto-bumps the build number from the latest TestFlight build.
- `submit_to_testflight: false` — uploading still happens; this only skips
  *external* Beta App Review, which fails with "Another build is in review"
  whenever a previous build of the same version is queued.
- Android is **not** built by Codemagic — build locally.

---

## 2. Release commands

```powershell
# iOS — bump the build number in pubspec.yaml first
git add -A; git commit -m "..."; git push origin main
# then run the ios-testflight workflow in Codemagic

# Android
flutter clean
flutter pub get
flutter build appbundle --release
# → build\app\outputs\bundle\release\app-release.aab  → Play Console
```

`version: X.Y.Z+N` in `pubspec.yaml`: `N` is the Android versionCode **and** the
iOS fallback build number. It must always increase. iOS auto-bumps past the
latest TestFlight build; Android uses the pubspec value literally.

---

## 3. Platform lessons (the expensive ones)

These each cost a debugging cycle. Don't relearn them.

### Deletion cannot be made silent
Both platforms **force** a system confirmation for deleting media the app didn't
create. There is no permission, entitlement or setting that pre-grants it, and
it can only be shown by a **foreground** app. iOS: `PHPhotoLibrary`.
Android 11+: `MediaStore.createDeleteRequest`. Design around it, not against it.

### `PhotoManager.setIgnorePermissionCheck(true)` breaks everything
It is a **global** flag. Setting it (originally for the video flow) silently
broke photo listing *and* deletion app-wide. `main.dart` now explicitly sets it
to `false` at startup as a guard.

### Android's `moveToTrash` fallback double-prompts
`deleteAssets` used to fall back to `moveToTrash` whenever nothing was deleted —
including when the user simply **declined**, producing a second dialog for the
same items. The fallback now only runs when `deleteWithIds` genuinely *threw*.

### iOS vs Android scroll physics
- Android `ClampingScrollPhysics` → never scrolls past the edge, reports
  `OverscrollNotification` deltas.
- iOS `BouncingScrollPhysics` → *moves* past the edge, emits almost no
  overscroll notifications.

(1.2's overscroll group navigation had to handle both. It was removed on
purpose in 1.3 — explicit buttons instead. Keep this in mind if a gesture like
it ever comes back.)

### `VideoPlayerController.contentUri` is Android-only
On iOS `getMediaUrl()` returns a file URL and `contentUri` fails silently. Use
the shared `buildAssetVideoController()` helper (`utils/video_utils.dart`),
which branches on `Platform.isAndroid`.

### The library cache never refreshed itself (fixed in 1.3)
The scan was cached for the process lifetime, and iOS keeps apps alive for
days — new photos never appeared until the user found Refresh. Now
`AppProvider` registers `PhotoManager.addChangeCallback` once, re-scans
(debounced 1.5 s) and re-checks on resume after 60 s. iOS fires "changes" for
every iCloud sync batch, so automatic re-scans first compare a cheap
fingerprint (count + newest id) and skip when nothing changed.

### Measuring file sizes on iOS copies the file
photo_manager's `originFile`/`file` on iOS writes the original into the app's
cache (`PHAssetResourceManager`). Measuring a batch of videos that way means
gigabytes of writes. 1.3 measures on Android only (a stat of the real path —
Android 10 also gets real paths because of `requestLegacyExternalStorage`)
and uses averages on iOS.

### `SliverFillRemaining(hasScrollBody: false)` + `LayoutBuilder` = crash
It asks its child for intrinsic sizes, which `LayoutBuilder` can't give — the
whole Home went blank. `ProgressTrack` uses `AnimatedFractionallySizedBox`.

### audioplayers: two traps
- `AudioContextConfig(respectSilence: true, focus: mixWithOthers)` *asserts* on
  iOS and maps Android to the ringtone stream. Build `AudioContextIOS(ambient)`
  / `AudioContextAndroid(sonification, focus none)` explicitly.
- The default `ReleaseMode.release` unloads a source after it plays; use
  `ReleaseMode.stop` for preloaded effects.

### Text without a `Material` ancestor
Renders with an ugly yellow/red dotted underline. Wrap overlay text in
`Material(type: MaterialType.transparency)`.

### `in_app_review.openStoreListing()` needs `appStoreId` on iOS
Without it the call throws and — if the catch block is empty — the button
silently does nothing. Always pass the numeric App Store ID.

### Store gotchas
- The first non-consumable IAP **must** be submitted attached to an app version.
  Later ones can go alone.
- An IAP needs a **review screenshot** or it stays unfetchable, and
  `queryProductDetails` returns nothing → dead buy button.
- The Paid Applications agreement must be **Active** or no IAP ever loads.
- AdMob won't serve real ads until the app is **live and linked** in AdMob
  ("Requires review" = no fill). Blank ads pre-launch are expected.
- AdMob's `app-ads.txt` check reads the **Marketing URL** from the App Store
  listing and looks for the file at that domain's root. The App Store URL itself
  is not a developer website.
- iOS deployment target must be **15.0+** (ITMS-90068). Set it in the Podfile
  `platform` line, all three Xcode configs, **and** the Podfile `post_install`
  hook — the hook overrides the pods otherwise.

---

## 4. Architecture

```
lib/
├── main.dart                       dark-only Noir theme; resets setIgnorePermissionCheck(false)
├── providers/app_provider.dart     state, caches, library change listener,
│                                   deletion → DeleteResult, milestones, pending queue
├── models/                         photo_group, delete_result (+ MediaKind), milestone
├── services/
│   ├── photo_service.dart          library scan, fingerprint, time grouping, measureBytes
│   ├── video_service.dart          video access (partial-permission flow)
│   ├── feedback_service.dart       Fx sounds + haptics (singleton)
│   ├── ad_service.dart             ATT → UMP consent → AdMob
│   ├── purchase_service.dart       cleanpics_pro
│   ├── review_service.dart         rate button + native prompt
│   └── notification_service.dart   twice-yearly reminders
├── screens/
│   ├── home_screen.dart            freshness line, tabs, mode cards, milestone card
│   ├── swipe_screen.dart           "One by one" (photos + videos; video_swipe_screen wraps it)
│   ├── group_review_screen.dart    "Similar shots/clips" (video_group_review_screen wraps it)
│   ├── session.dart                shared Finish → system prompt → Finished screen
│   ├── session_summary_screen.dart "Finished" (+ milestone card)
│   ├── milestones_screen.dart
│   └── settings_screen.dart
├── theme/                          noir.dart (tokens + type), app_theme.dart (ThemeData)
├── utils/                          format (counts/bytes, no intl), asset_utils, video_utils
└── widgets/noir/                   NoirButton, NoirCard, NoirHeader, PendingPill, …
```

Localization is **in-code** (`l10n/strings.dart`), not ARB: a base `AppStrings`
class with one subclass per language. 7 languages: **en, es, de, fr, pt, it, pl**.
Adding a string means adding it to the base class *and* 6 overrides.

### The cleanup modes (1.3)

Home has a Photos / Videos tab; each has two modes.

| Mode | Interaction |
|---|---|
| Similar shots / Similar clips | grid of one time-group, tap to mark; "Delete n · Next" / "Keep all · Next" / Previous; hold a video tile to play inline, hold a photo for the viewer |
| One by one (photos / videos) | card deck, Delete / Keep buttons or swipe, Undo (50 steps), hold to play videos |

Noir is **dark-only**. Colour has fixed jobs: the logo's purple
(`Noir.accent`, `accentStrong` behind white text) = primary actions, selected
tab, progress; green `Noir.success` = the Finished check and KEEP only; red
`Noir.danger` = delete only; gold `Noir.reward` = milestones only. (The plan
had white as the accent; Alexandra found it too plain, so purple came back.) Confetti, overscroll
navigation, idle hints and the Home coachmark tour were **removed on purpose**
in 1.3 — don't bring them back without a decision.

---

## 5. The deletion model (most important design decision)

**Problem:** the OS confirmation can't be avoided, and asking per group is
exhausting; asking only at the end risks losing work if the app is killed.

**Solution:**
1. Marking items **persists their IDs** to `SharedPreferences`
   (`pending_delete_ids`) immediately.
2. Everything is deleted in **one** system prompt when the user leaves the mode.
3. If the app is force-quit first, the marks survive. On next launch Home shows
   an explanatory dialog — *"You marked 12 items for deletion last time but
   didn't confirm it"* — then the system prompt.
4. Declining is **final**: the queue is cleared. Otherwise users would face a
   delete prompt on every single launch.

Guards that matter (all were real bugs):
- `_isFlushing` — app-start and resume callbacks could otherwise stack two
  system dialogs.
- De-duplication — re-marking an asset must not queue it twice.
- `ModalRoute.isCurrent` — background/resume *during* a session must not pop the
  "finish your cleanup" dialog over the active group screen.
- Never latch commits behind a one-shot bool: an early commit would consume it
  and everything marked afterwards would never delete.

**Honest results (1.3):** `deleteAssets` returns a `DeleteResult` (requested,
deleted, bytes, declined, usedTrash, newMilestone). Bytes count only ids the OS
confirmed gone — measured on Android, averaged on iOS. The celebration lives
on the Finished screen, after the prompt; in-session numbers are labelled
"marked" and "~". A decline shows "Nothing was deleted" and counts nothing.

**Session flow:** every mode sets `provider.inCleanupSession` (re-scans wait
until it's off). Finish with nothing marked → Home. Otherwise one prompt, then
`SessionSummaryScreen` replaces the mode (`session.dart`). Home awaits the
summary route before any interstitial / review / notification request, and
skips them while the user chains "Keep going".

**Milestones:** 100 MB, 250 MB, 500 MB, 1/2/5/10/25/50 GB (binary units).
`milestone_index` = highest reached; first 1.3 launch migrates it silently
from `freed_bytes`. `milestone_dates` stores when each tier was reached.

---

## 6. Other deliberate choices

- **Interstitial ads** only after the user actually deleted something, capped at
  one per 4 minutes.
- **Notification permission** is requested after the *first successful cleanup*,
  not at launch — first run already stacks photo access + ATT + ad consent.
- **ATT prompt** fires before the UMP consent form (App Review guideline
  5.1.2(i)). App Privacy in App Store Connect must declare tracking = **Yes** to
  match, or it's a rejection.
- **Library warm-up** runs in the background after Home appears, so the first
  mode tap doesn't sit on a spinner. `ensureGroups()` reuses the cached scan
  rather than re-reading the library.
- **iPhone-only** (`TARGETED_DEVICE_FAMILY = 1`) — avoids iPad screenshots and
  iPad review devices.

---

## 7. Open items

- [ ] AdMob: set the **Marketing URL** to `https://crocodata.net` so
      `app-ads.txt` verifies; link the app in AdMob so real ads serve.
- [ ] Confirm AdMob **Payments** profile is complete (blocks serving even after
      approval).
- [ ] Rename the **Play Store listing** from "CleanPics" to "CleanFotos".
- [ ] Verify 1.3 on a real iPhone: library auto-refresh, limited-access
      picker, hold-to-play, sounds with the silent switch, the full delete
      flow. The iOS paths were written without device testing (Android was
      checked on the API 36 emulator).
- [ ] Rename the app in the AdMob console — the consent form still says
      "CleanPics".
- [ ] Optional: measure real sizes on iOS too (needs a native PHAssetResource
      size lookup — photo_manager can't do it without copying).
- [ ] Video groups may be sparse — grouping needs 2+ videos within 3 minutes.
      Consider widening the window for videos.
- [ ] Dependencies are several majors behind. Upgrade one at a time, never
      right before a release (`flutter_local_notifications` 17→22 is breaking).

---

## 8. Debugging habits that paid off

- **Stale builds are the #1 false alarm.** Repeatedly, "the fix didn't work"
  meant uncommitted changes or a hot reload that missed `initState`. Check
  `git status` and use capital **R** (hot restart).
- Verify a fix is actually *in the commit*:
  `git show HEAD:lib/l10n/strings.dart | findstr "_PolishStrings"`.
- Codemagic builds from **GitHub**, not your disk. Unpushed work is invisible
  to it — and confirm the build log shows the expected commit *and* repo.
- Git lock files (`.git/index.lock`, `.git/HEAD.lock`) silently block commits.
  `del /f` them and re-run.
- `flutter analyze`: info/warnings are fine, **errors** are not. A clean analyze
  is the cheapest pre-build check there is.
