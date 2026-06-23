# CleanPics — Project Overview

CleanPics is a Flutter app that helps people quickly clean up their photo
library by finding groups of similar photos (mostly bursts and near-duplicate
shots taken around the same time) and making them fast and satisfying to delete.

## The idea

People take many near-identical photos — ten selfies in a row, a few tries at
the same sunset — and never go back to clean them up. CleanPics surfaces these
clusters and lets the user delete the extras in seconds, with a clear sense of
how much space they freed.

## How it works

### Finding similar photos

The core insight: **photos taken at the same time are usually similar**, so
time is the only grouping signal. The grouping (`lib/services/photo_service.dart`)
is intentionally lightweight so it stays fast even for libraries with tens of
thousands of photos:

- **Time clustering only** — photos are sorted newest-first and grouped when
  taken within `timeWindowSeconds` (default **30**) of each other. There are
  **no file reads and no image decoding** — it's pure metadata math (a sort plus
  one linear pass).

Earlier versions also used GPS location and a perceptual visual hash (dHash) to
refine large bursts. Those were **removed** on purpose: decoding thumbnails for
every photo was too heavy for large libraries. Pure time grouping is predictable
and near-instant. The trade-off: photos taken within the same 30s window are
grouped even if their subjects differ — tune `timeWindowSeconds` if that's too
loose.

The threshold is a constant at the top of `PhotoService`, easy to tune.

### Lazy, on-demand loading

To keep app start instant regardless of library size, photo work is deferred
(`lib/providers/app_provider.dart`):

1. **On launch — `prepare()`**: only requests permission and reads the photo
   *count* (fast metadata), so the home screen can show the library size
   immediately. No photo list is loaded and no grouping runs.
2. **On entering a cleanup mode — `ensureGroups()`**: loads the photo list and
   groups it by time, then **caches** the result so the second mode opens
   instantly. The home screen shows a brief loading spinner during this single
   heavy step. "Refresh" clears the cache and re-scans.

Until grouping has run, the home screen shows `—` for "Similar Groups" / "To Be
Saved" (we don't know them yet without scanning).

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

- **Flutter** (Material 3), portrait-locked, large fonts throughout (sizes were
  increased app-wide for readability, and the app respects the OS font-scale
  setting up to 1.4×).
- **State**: `provider` (`lib/providers/app_provider.dart`).
- **Photos**: `photo_manager` + `photo_manager_image_provider` for access,
  thumbnails, and deletion.
- **Grouping**: capture-time only (no image decoding / no `image` package use in
  the grouping path).
- **Persistence**: `shared_preferences` (freed bytes, deleted count, language,
  Pro status, reminders).
- **Monetization**: `google_mobile_ads` (AdMob) + `in_app_purchase` (one-time
  Pro unlock). Ad consent via Google's UMP (User Messaging Platform).
- **i18n**: in-code strings (`lib/l10n/strings.dart`) for EN, ES, DE, FR, PT, IT.

```
lib/
  main.dart                  App entry, theme, font-scale clamp
  theme/app_theme.dart       Brand colors, typography
  l10n/strings.dart          6-language strings
  models/photo_group.dart    PhotoGroup + LibraryStats
  providers/app_provider.dart App state, lazy load (prepare/ensureGroups), delete, persistence
  services/
    photo_service.dart       Grouping algorithm (capture-time only)
    ad_service.dart          UMP consent + AdMob init, banner + interstitial helpers
    purchase_service.dart    One-time "Pro" in-app purchase (removes ads)
  screens/
    home_screen.dart         Stats, mode selection (lazy load), banner ad
    group_review_screen.dart 4-up tap-to-delete mode
    swipe_screen.dart        Swipe-to-delete mode
    settings_screen.dart     Stats, language, Pro, reminders, ad privacy options, about
  widgets/
    photo_card.dart          Thumbnail + full-screen detail dialog
    celebration_overlay.dart Confetti + success badge
    banner_ad_widget.dart    Self-hiding adaptive banner (consent-gated)
```

## Running it

```bash
flutter pub get      # required — dependencies were added
flutter run
```

Photo permissions are configured for Android (`READ_MEDIA_IMAGES` etc.) and iOS
(`NSPhotoLibraryUsageDescription`). Android `minSdk` is forced to 23+ for AdMob.

## Monetization & ads

- **Ads**: a home-screen banner + an interstitial after a cleanup session, via
  AdMob. Real Android unit IDs are set in `ad_service.dart` (iOS still uses test
  IDs — iOS isn't being shipped yet). Debug builds always use Google **test**
  units to protect the account.
- **Pro (remove ads)**: a one-time, non-consumable in-app purchase
  (`cleanpics_pro`, `purchase_service.dart`). On purchase/restore, `setPro(true)`
  persists locally and ads stop. **There is no "show ads" toggle** — free users
  always see ads; the only way to remove them is Pro. (`adsEnabled => !isPro`.)
- **Consent (GDPR + US)**: Google's UMP flow runs before any ad loads
  (`AdService._gatherConsent`). Ads are gated on `canRequestAds`; the EEA/UK
  consent form shows when required, and Settings has an **"Ad privacy options"**
  entry so users can change their choice. Consent is only gathered for non-Pro
  users.

See the "Monetization plan" section below for strategy.

## TODO / Before launch

Targeting **Android first** (iOS deferred).

**Required to publish (Android)**

- [x] Real AdMob App ID (`AndroidManifest.xml`) + real banner/interstitial unit
      IDs (`lib/services/ad_service.dart`).
- [ ] Create the **non-consumable** product `cleanpics_pro` in Google Play
      Console and set its price (the displayed price comes from the store). The
      `plannedProPrice` in `purchase_service.dart` is only a pre-load fallback.
- [x] Android `applicationId` set to `com.crocodata.cleanpics`.
- [ ] Add a release signing config for Android (currently signs with debug keys).
- [x] App icon configured via `flutter_launcher_icons`; branded splash set so the
      logo isn't boxed on Android 12+ (`values-v31`, `launch_background.xml`).
- [x] Privacy policy hosted at https://crocodata.net/cleanpics/privacy-policy.html
      and linked in app Settings.
- [x] GDPR/UMP ad consent flow implemented in code. Console side: publish the
      **GDPR** and **US states** consent messages in AdMob (use **UMP SDK**
      deployment so the in-app "Ad privacy options" satisfies revocation).
- [ ] Play Console: complete **Data safety** form, **photo-permission**
      declaration, and host **app-ads.txt** on crocodata.net.

**Product polish**

- [x] One-time "Pro" in-app purchase to remove ads.
- [x] Lazy, on-demand photo loading + capture-time-only grouping (fast for large
      libraries).
- [x] Larger fonts app-wide for readability.
- [x] Per-group "Save ~X" size labels on the group review screen.
- [ ] Undo for accidental deletes.
- [ ] Move heavy grouping work off the UI thread (isolate) for very large
      libraries.
- [ ] Move in-code strings to ARB-based localization and add more languages.
- [ ] Optionally extend beyond photos to videos and screenshots.
- [ ] iOS release (real AdMob iOS IDs, ATT prompt, App Store IAP) — deferred.

## Monetization plan

For a free, worldwide consumer utility like this, a hybrid model works best:

1. **Ads (now)** — banner + interstitial via AdMob, already wired. Keep
   interstitials infrequent (once per cleanup session, as implemented) so they
   don't sour the "satisfying cleanup" feeling. This is your baseline revenue.
2. **One-time "Pro" unlock (highest impact)** — a single cheap in-app purchase
   that removes ads and could add nice-to-haves (advanced stats,
   video/screenshot cleanup, larger batch sizes). It's wired up and defaults to a
   planned price of **$1.99** (`plannedProPrice` in `purchase_service.dart`); the
   real localized price comes from the store once the product is configured.
   Utility apps convert far better on a cheap one-time unlock than on
   subscriptions. Free users always see ads (there is no opt-out toggle) — Pro is
   the only way to remove them, which keeps the upgrade incentive clear.

   Note: the in-app "ways to monetize" tips were removed from Settings (they're
   developer notes, not user-facing) — they live in this section instead.
3. **Subscription (only if there's an ongoing service)** — justified only if you
   add a recurring-value feature like cloud backup or cross-device sync.
   Otherwise users resent subscriptions for a one-off cleanup tool.

Recommended path: ship with ads + a one-time Pro unlock. Add a subscription later
only if you build a genuinely recurring feature. Growth comes mostly from App
Store Optimization and good ratings — prompt for a review right after a big,
satisfying cleanup.
