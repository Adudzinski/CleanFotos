# CleanFotos 1.1 — Release Notes

## "What's New" (App Store / Play Store — paste this)

```
Polish language support, plus a batch of fixes that make CleanFotos smoother:

• NEW: Polski — CleanFotos now speaks 7 languages
• Group Review now scrolls, so you can see every photo in a group, not just the first four
• Deleting inside a group keeps you in that group instead of jumping ahead
• Fixed the "Remove Ads" button so it always responds and opens the purchase
• Fixed "Rate CleanFotos" so it opens the App Store
• Cleaner storage numbers and tidier buttons in every language
• Sharper launch screen that follows your light/dark mode
```

## Shorter variant (if you want it punchier)

```
• NEW: Polish language
• Group Review now scrolls — see every photo in a group
• Deleting no longer skips you to the next group
• Fixed "Remove Ads" and "Rate CleanFotos" buttons
• Cleaner storage numbers, sharper launch screen
```

## What actually changed (internal)

### User-facing
- **Polish (pl)** added as a 7th language; auto-selected on Polish devices, and
  listed in Settings → Language.
- **Group Review reworked**: scrollable grid showing every photo in the group
  (was: 4 at a time). Deleting reflows the remaining photos and stays on the
  same group; bottom-left button is now "Next" rather than "Skip".
- **Group Review card text** shortened to "Photos taken within 3 minutes of
  each other." (was a two-sentence description that overflowed).
- **Library Size** now shows whole numbers ("90 GB", not "90.24 GB"), which
  also keeps the two home stat cards the same height.
- **Buttons auto-fit their text** so translations never overflow.
- **Splash screen** follows light/dark mode; logo no longer clipped by the
  Android 12 circular mask, and the white halo is gone.
- **Interstitial ads are less frequent** — they only appear if you actually
  deleted something during the session (still capped at once per 4 minutes).

### Bug fixes
- **"Remove Ads" was a dead button.** It was disabled whenever the in-app
  product hadn't loaded, so taps did nothing (this failed App Review under
  guideline 2.1(b)). It is now always tappable: it re-queries the store, opens
  the purchase sheet, and explains itself if the product is genuinely
  unavailable.
- **"Restore Purchase" is always visible** — Apple requires a restore path for
  non-consumable purchases.
- **"Rate CleanFotos" did nothing on iOS** — `openStoreListing()` requires the
  numeric App Store ID, which wasn't passed; the error was swallowed by an
  empty catch. Now passes the ID (6792250332) with a direct-URL fallback.

### Store / platform
- **App Tracking Transparency** implemented — the ATT prompt now appears on
  first launch, before ads and before the AdMob (UMP) consent form, as required
  by App Review guideline 5.1.2(i). App Privacy in App Store Connect must
  declare tracking = Yes to match.
- **iPhone-only**: `TARGETED_DEVICE_FAMILY = 1`, so the app is no longer
  reviewed or listed for iPad.
- **iOS interstitial ad unit** wired (`.../1457650921`); previously iOS fell
  back to a Google test ID because no production unit existed.
- **SKAdNetwork**: expanded from 1 to 55 identifiers so advertisers can
  attribute installs — materially improves iOS fill rate and eCPM.

## Release checklist

- [ ] `flutter pub get`
- [ ] Commit + push
- [ ] Codemagic `ios-testflight` → confirm log says `Building 1.1.0 (14)`
- [ ] Delete the app from your phone first, then install from TestFlight
      (so the ATT prompt appears — iOS only asks once per install)
- [ ] Verify: ATT prompt on first launch
- [ ] Verify: Settings → Remove Ads is tappable and opens the $1.99 sheet
- [ ] Verify: Restore Purchase visible
- [ ] Verify: Rate CleanFotos opens the App Store
- [ ] Verify: Polski in the language list
- [ ] App Store Connect → new version 1.1 → attach build 14 → paste "What's New"
- [ ] App Privacy → tracking = Yes (Device ID + Advertising Data) → Publish
- [ ] Submit for review

### Android (separate)
- [ ] `flutter build appbundle --release`
- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console
- [ ] Same "What's New" text
