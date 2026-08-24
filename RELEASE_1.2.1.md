# CleanFotos 1.2.1 — Release Commands

Version bumped in `pubspec.yaml`: **`1.2.0+17` → `1.2.1+18`**

Run everything from the repo root: `C:\Users\alexa\CleanFotos`

---

## 0. One-time cleanup (do this first)

A stale git lock file was left behind and moved aside. Delete it:

```powershell
del .git\index.lock.stale-remove-me
```

---

## 1. Verify before committing

**This has not been run yet — Flutter isn't available in the sandbox I can reach.
Do not skip it.**

```powershell
flutter pub get
flutter analyze
```

Expect info/warnings only, no errors. If `analyze` reports errors in
`swipe_screen.dart`, `video_swipe_screen.dart`, or `app_provider.dart`, stop and
fix before committing.

Then smoke-test the actual fix on a device:

```powershell
flutter run
```

Test cases that matter for this release:

1. **Picture Swipe** — swipe 3–4 photos left, then force-quit from the app
   switcher *without* leaving the deck. Reopen → "Finish your cleanup" dialog
   should appear naming the right count.
2. **Video Swipe** — same test.
3. **Unanswered prompt** — swipe some, exit the deck so the OS delete prompt
   appears, then force-quit *while the prompt is on screen*. Reopen → the
   recovery dialog should still appear (this is the one-shot fix).
4. **Decline** — tap "Delete them", then deny the OS prompt. Reopen → should
   NOT ask again.
5. **Group modes** — confirm Picture Group / Video Group still delete in one
   prompt on exit.

---

## 2. Commit & push

```powershell
git add -A
git status
```

Review that list carefully before committing. It includes the deletion of 10
store screenshots under `assets/store/screenshots/` and
`assets/store/ios_screenshots/`, plus new untracked files
(`PROJECT_NOTES.md`, `STORE_LISTING_2026-08.md`,
`assets/store/play_feature_graphic_2026-08.png`,
`assets/images/IPhone/unnamed.png`).

```powershell
git commit -m "1.2.1+18 - persist swipe deletions, fix one-shot pending cleanup

Swipe decks now write each mark to disk via queueForDeletion and commit
through flushPendingDeletions, so a force-quit mid-session no longer loses
them silently - Home offers to finish the cleanup next launch, matching the
group modes.

flushPendingDeletions now clears the stored ids only AFTER deleteAssets
returns. Clearing beforehand threw the marks away when the app was killed
while the OS prompt was up - the exact case the recovery exists for.

Also refreshes the Play feature graphic and store listing copy for the
four current cleanup modes."

git push origin main
```

---

## 3. Tag the release

The repo has no tags yet, so this is the first one:

```powershell
git tag -a v1.2.1 -m "CleanFotos 1.2.1 - deletion reliability fixes"
git push origin v1.2.1
```

---

## 4. Android — Google Play

```powershell
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

> **Check first:** `RELEASE_GUIDE.md` §1 lists "Add a release signing config for
> Android (currently signs with debug keys)" as still open, and `PROJECT_OVERVIEW.md`
> repeats it. If `android/key.properties` and the release `signingConfig` in
> `android/app/build.gradle.kts` still aren't wired up, Play will reject the
> upload. Confirm before building.

Then in Play Console:

1. **Test and release → Production** (or your test track) → **Create new release**
2. Upload `app-release.aab` — version code **18** must be higher than anything
   previously uploaded
3. Paste the "What's New" text below
4. Review → roll out

---

## 5. iOS — TestFlight via Codemagic

Codemagic's `ios-testflight` workflow has no `triggering:` block, so start it
manually from the Codemagic UI on the `main` branch.

Confirm the build log line reads:

```
Building 1.2.1 (<n>)
```

The build *number* is auto-bumped from the latest TestFlight build when
`APP_STORE_APPLE_ID` is set, so it may not be 18 — that's expected. The build
*name* must say 1.2.1.

Note `submit_to_testflight: false` in `codemagic.yaml` — the build uploads and
processes, and internal testers get it, but it is not submitted for external
Beta App Review.

---

## "What's New" text

Play Store (500 char limit) and App Store both:

```
Fixes for deletions that didn't go through.

• If you close the app before confirming a deletion, CleanFotos now offers to finish the job next time you open it — in Picture Swipe and Video Swipe too, not just the group modes.
• The reminder explains why it's showing, so the system delete prompt is never a surprise.
• Marked items are no longer lost if the confirmation is left unanswered.
```

---

## Still open (not blocking this release)

- **Screenshots** — the old light-theme, three-mode mockups were deleted from
  the repo. Both stores still need fresh ones showing all four modes in the
  actual dark UI.
- **Android release signing** — see the warning in §4.
- **Store listing text** — `STORE_LISTING_2026-08.md` has the refreshed copy;
  it still needs pasting into Play Console and App Store Connect.
- **`STORE_LISTING.md` / `ASO_STORE_LISTING.md` / `PROJECT_OVERVIEW.md`** still
  say "CleanPics" throughout and describe three cleanup modes.
