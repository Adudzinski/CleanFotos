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

Overscroll-to-change-group must handle **both**: measure `metrics.pixels`
beyond `min/maxScrollExtent` (iOS) *and* accumulate `OverscrollNotification`
(Android). iOS also springs back through the same out-of-range positions, so a
`_navLock` is needed to prevent a double trigger on the rebound.

### `VideoPlayerController.contentUri` is Android-only
On iOS `getMediaUrl()` returns a file URL and `contentUri` fails silently. Use
the shared `buildAssetVideoController()` helper
(`video_group_review_screen.dart`), which branches on `Platform.isAndroid`.

### `CelebrationOverlay.of(context)` returns null
`findAncestorStateOfType` searches **ancestors**, but each screen builds the
overlay *below* its own context — so the lookup always failed and confetti never
appeared anywhere. All four screens now use a `GlobalKey<CelebrationOverlayState>`.

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
├── main.dart                       resets setIgnorePermissionCheck(false)
├── providers/app_provider.dart     state, caches, deletion, pending queue
├── services/
│   ├── photo_service.dart          library scan + time grouping
│   ├── video_service.dart          video access (partial-permission flow)
│   ├── ad_service.dart             ATT → UMP consent → AdMob
│   ├── purchase_service.dart       cleanpics_pro
│   ├── review_service.dart         rate button + native prompt
│   └── notification_service.dart   twice-yearly reminders
├── screens/                        home, group_review, video_group_review,
│                                   swipe, video_swipe, settings
└── widgets/                        celebration_overlay, idle_gesture_hint,
                                    photo_card, banner_ad_widget, coachmark
```

Localization is **in-code** (`l10n/strings.dart`), not ARB: a base `AppStrings`
class with one subclass per language. 7 languages: **en, es, de, fr, pt, it, pl**.
Adding a string means adding it to the base class *and* 6 overrides.

### The four cleanup modes

| Mode | Colour | Interaction |
|---|---|---|
| Video Group | blue `#2563EB` | grid, tap to mark, **hold a tile to play inline** |
| Video Swipe | teal `#16BFA6` | one at a time, hold to preview |
| Picture Group | crimson `#C2185B` | grid, tap to mark |
| Picture Swipe | pink `#FF6584` | one at a time |

Group modes: **no Next button**. Navigate by pulling past the top/bottom of the
grid (overscroll). Idle for ~4s → animated arrows explain the gesture.

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

**Known honesty gap:** the confetti says "12 MB freed" the moment items are
marked, before the OS confirms. Safe (nothing is lost) but overstated. Moving
the celebration after confirmation is an open improvement.

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
- [ ] Verify on a real iPhone: overscroll group navigation, inline video
      hold-to-play, and the full delete flow. Both iOS paths were written
      without device testing.
- [ ] Video groups may be sparse — grouping needs 2+ videos within 3 minutes.
      Consider widening the window for videos.
- [ ] Dependencies are several majors behind. Upgrade one at a time, never
      right before a release (`flutter_local_notifications` 17→22 is breaking).
- [ ] Optional: fire the celebration only after the OS confirms deletion.

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
