# CleanFotos — Project Overview

CleanFotos is a Flutter app that helps people quickly clean up their photo
library by finding groups of similar photos (mostly bursts and near-duplicate
shots taken around the same time) and making them fast and satisfying to delete.

## The idea

People take many near-identical photos — ten selfies in a row, a few tries at
the same sunset — and never go back to clean them up. CleanFotos surfaces these
clusters and lets the user delete the extras in seconds, with a clear sense of
how much space they freed.

## How it works

### Finding similar photos

The core insight: **photos taken at the same time are usually similar**, so
time is the primary grouping signal. The grouping pipeline (`lib/services/photo_service.dart`):

1. **Time clustering** — photos are sorted newest-first and grouped when taken
   within `timeWindowMinutes` (default 5) of each other. This is the main signal.
2. **Location** — if two photos in a time cluster both have GPS data and are more
   than `locationRadiusMeters` (default 200 m) apart, they're split into separate
   groups.
3. **Visual hash (safety net)** — only for unusually large clusters (more than
   `visualSplitThreshold` photos), a lenient perceptual hash (dHash + Hamming
   distance) breaks up a long continuous shooting session so it doesn't collapse
   into one giant group. The threshold is deliberately permissive so time stays
   dominant.

All thresholds are constants at the top of `PhotoService`, easy to tune.

### Two cleanup modes

- **Group Review** — shows 4 photos from a group at a time. Tap photos to mark
  them, tap **Delete**, and freed slots refill from the rest of the group until
  the user taps **Skip/Continue**. Tap-and-hold opens a full-screen detail view.
- **Swipe Mode** — Tinder-style: swipe left to delete, right to keep, one photo
  at a time.

### Feeling of success

Every deletion triggers a confetti burst and a floating "X photos · Y MB freed"
badge (`lib/widgets/celebration_overlay.dart`). The home screen shows a running
"space freed" banner, and Settings shows library statistics (total photos,
library size, similar groups, potential savings, space freed, photos deleted).

## Tech & structure

- **Flutter** (Material 3), portrait-locked, large fonts throughout.
- **State**: `provider` (`lib/providers/app_provider.dart`).
- **Photos**: `photo_manager` + `photo_manager_image_provider` for access,
  thumbnails, and deletion.
- **Similarity**: `image` package for perceptual hashing.
- **Persistence**: `shared_preferences` (freed bytes, deleted count, language,
  ads toggle).
- **Monetization**: `google_mobile_ads` (AdMob).
- **i18n**: in-code strings (`lib/l10n/strings.dart`) for EN, ES, DE, FR, PT, IT.

```
lib/
  main.dart                  App entry, ad init, theme
  theme/app_theme.dart       Brand colors, typography
  l10n/strings.dart          6-language strings
  models/photo_group.dart    PhotoGroup + LibraryStats
  providers/app_provider.dart App state, delete logic, persistence
  services/
    photo_service.dart       Grouping algorithm (time + location + visual)
    ad_service.dart          AdMob init, banner + interstitial helpers
  screens/
    home_screen.dart         Stats, mode selection, banner ad
    group_review_screen.dart 4-up tap-to-delete mode
    swipe_screen.dart        Swipe-to-delete mode
    settings_screen.dart     Stats, language, ads, about
  widgets/
    photo_card.dart          Thumbnail + full-screen detail dialog
    celebration_overlay.dart Confetti + success badge
    banner_ad_widget.dart    Self-hiding adaptive banner
```

## Running it

```bash
flutter pub get      # required — dependencies were added
flutter run
```

Photo permissions are configured for Android (`READ_MEDIA_IMAGES` etc.) and iOS
(`NSPhotoLibraryUsageDescription`). Android `minSdk` is forced to 23+ for AdMob.

## Monetization

AdMob is wired with Google's **test** ad units: a banner on the home screen and
an interstitial after each cleanup session, both gated by the Settings "Show Ads"
toggle. See the "Monetization plan" section below for the recommended strategy.

## TODO / Before launch

**Required to publish**

- [ ] Replace test AdMob App IDs (`AndroidManifest.xml`, `ios/Runner/Info.plist`)
      and the test unit IDs in `lib/services/ad_service.dart` with real ones.
- [ ] Set a real `applicationId` / bundle identifier (currently
      `com.example.cleanfotos_app`).
- [ ] Add a release signing config for Android (currently signs with debug keys).
- [ ] Design a real app icon and logo (currently the default Flutter icon +
      an `auto_awesome` placeholder in-app).
- [ ] Add a privacy policy (required for photo access + ads) and a
      consent flow (GDPR/UMP) for ads in the EU.

**Product polish**

- [ ] Add a "Pro" in-app purchase to remove ads (see plan below).
- [ ] Reverse-geocode GPS coordinates to place names (currently shows raw
      lat/lng).
- [ ] Show per-group size ("free up 24 MB") on the group cards.
- [ ] Undo for accidental deletes.
- [ ] Move heavy grouping work off the UI thread (isolate) for very large
      libraries.
- [ ] Move in-code strings to ARB-based localization and add more languages.
- [ ] Optionally extend beyond photos to videos and screenshots.

## Monetization plan

For a free, worldwide consumer utility like this, a hybrid model works best:

1. **Ads (now)** — banner + interstitial via AdMob, already wired. Keep
   interstitials infrequent (once per cleanup session, as implemented) so they
   don't sour the "satisfying cleanup" feeling. This is your baseline revenue.
2. **One-time "Pro" unlock (highest impact)** — a single in-app purchase
   (~$2.99–4.99) that removes ads and could add nice-to-haves (advanced stats,
   video/screenshot cleanup, larger batch sizes). Utility apps convert far better
   on a cheap one-time unlock than on subscriptions, and it pairs naturally with
   the existing "Show Ads" toggle.
3. **Subscription (only if there's an ongoing service)** — justified only if you
   add a recurring-value feature like cloud backup or cross-device sync.
   Otherwise users resent subscriptions for a one-off cleanup tool.

Recommended path: ship with ads + a one-time Pro unlock. Add a subscription later
only if you build a genuinely recurring feature. Growth comes mostly from App
Store Optimization and good ratings — prompt for a review right after a big,
satisfying cleanup.
