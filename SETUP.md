# CleanFotos — Flutter App

## App Overview

**CleanFotos** helps users free up storage by finding and deleting similar/duplicate photos. Two modes:

- **Group Review** — Shows 4 photos at a time from a similar group. Tap to select, then delete. Confetti celebration on each delete.
- **Swipe Mode** — Tinder-style full-screen swipe: left = delete, right = keep.

## Quick Start

### 1. Install Flutter
Follow https://docs.flutter.dev/get-started/install

### 2. Get dependencies
```bash
cd cleanfotos_app
flutter pub get
```

### 3. Run on device (physical device recommended — photos need real library)
```bash
flutter run
```

> ⚠️ The app requires a real device. The photo similarity algorithm and photo deletion only work on physical iOS/Android devices, not on simulators.

---

## Similarity Algorithm

Photos are grouped by **three signals**:

| Signal | Logic |
|--------|-------|
| **Time** | Photos taken within 5 minutes of each other are candidates |
| **Location** | GPS coordinates within ~200 m reinforce grouping |
| **Visual Hash** | An 8×8 average-hash of thumbnail bytes — photos with ≥75% hash match are grouped together |

Groups are sorted **newest first** so users see their most recent duplicates immediately.

---

## Monetization Options

1. **Google AdMob** (already wired in) — banner + interstitial ads. Replace the test App IDs in:
   - `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
   - `ios/Runner/Info.plist` → `GADApplicationIdentifier`

2. **"Pro" one-time purchase** — Use `in_app_purchase` package. Offer:
   - Remove ads
   - Unlimited swipe mode
   - Advanced statistics (faces, locations breakdown)

3. **Subscription ($1.99/month)** — "CleanFotos Pro":
   - Auto-weekly duplicate scan
   - iCloud / Google Photos smart sync
   - Scheduled cleanup reminders

4. **App Store Optimization**
   - Keywords: "duplicate photo cleaner", "similar photo finder", "free up storage", "photo organizer"
   - Show the "X GB freed" stat prominently in screenshots
   - Target high-storage users (iPhone photographers, families)

---

## Languages Supported

| Code | Language |
|------|----------|
| `en` | English |
| `es` | Español |
| `de` | Deutsch |
| `fr` | Français |
| `pt` | Português |
| `it` | Italiano |

Add more languages in `lib/l10n/strings.dart` by extending `AppStrings`.

---

## File Structure

```
lib/
  main.dart                    — App entry, theme setup
  theme/app_theme.dart         — Purple/violet color palette
  models/photo_group.dart      — PhotoGroup & LibraryStats models
  services/photo_service.dart  — Similarity algorithm + photo loading
  providers/app_provider.dart  — State management (Provider)
  screens/
    home_screen.dart           — Dashboard + mode selection
    group_review_screen.dart   — 4-photo grid review mode
    swipe_screen.dart          — Tinder swipe mode
    settings_screen.dart       — Language, stats, ads toggle
  widgets/
    celebration_overlay.dart   — Confetti + toast on delete
    photo_card.dart            — Thumbnail card + full-screen viewer
  l10n/strings.dart            — All 6 language strings
```

---

## Improving the Algorithm

For a production-grade similarity engine, consider:

- **`image_hash`** package — proper perceptual hash (dHash/pHash)
- **TensorFlow Lite** on-device ML model for visual embeddings
- **`native_exif`** for precise GPS metadata reading
- Background isolate processing for large libraries (>5000 photos)
