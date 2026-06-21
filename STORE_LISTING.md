# CleanPics — Google Play Store Listing

Everything needed for the Play Console listing, in one place.

## App identity

| Field | Value |
|-------|-------|
| App name | CleanPics |
| Package / application ID | `com.crocodata.cleanpics` |
| Default language | English (UK) |
| Category | Tools / Productivity (App, not Game) |
| Pricing | Free (with ads) |
| Privacy policy URL | https://crocodata.net/cleanpics/privacy-policy.html |
| Developer contact | fotopostprint@gmail.com |

## In-app product (one-time)

| Field | Value |
|-------|-------|
| Product ID | `cleanpics_pro` |
| Purchase option ID | `cleanpics-pro-buy` |
| Purchase type | Buy (one-time / non-consumable, no expiry) |
| Tags | none |
| Base price | 1.99 USD (Google auto-converts to local currencies) |
| Status | Active |
| Purpose | Removes all ads permanently |

> Test purchases free: add your account under **Setup → License testing**.

## Short description (max 80 chars)

```
Find and delete duplicate & similar photos in seconds. Free up space fast.
```

## Full description

```
CleanPics is the fastest, simplest way to clean up your photo gallery.

We all take the same shot ten times — a burst of selfies, a few tries at the same sunset — and never go back to delete the extras. CleanPics finds those look-alike photos for you and lets you remove the ones you don't want in seconds, so you can free up storage without endless scrolling.

HOW IT WORKS
CleanPics automatically groups photos taken around the same moment, so duplicates and near-identical shots show up together. Then you choose how to clean:

• Group review — see a set of similar photos at once and tap the ones to delete
• Swipe mode — swipe left to delete, right to keep, one photo at a time

Tap any photo to see it full-screen before deciding.

WHY YOU'LL LOVE IT
• Free up real storage space — see how much you've reclaimed
• Big, clear, easy-to-use design — no clutter, no learning curve
• A little celebration every time you clean up
• Optional monthly reminder to keep your gallery tidy
• Available in 6 languages: English, Spanish, German, French, Portuguese, Italian

PRIVATE BY DESIGN
All photo analysis happens entirely on your device. Your photos are never uploaded to us or anyone else. Deleted photos go to your phone's "Recently Deleted" album, so you can restore them for about 30 days if you change your mind.

FREE, WITH AN OPTIONAL UPGRADE
CleanPics is free to use, supported by ads. Don't like ads? Unlock CleanPics Pro with a single one-time purchase to remove them forever — no subscription.

Clean up your photos. Free up your phone. Download CleanPics today.
```

## Graphic assets

| Asset | Spec | File |
|-------|------|------|
| App icon | 512×512 PNG | `assets/store/play_icon_512.png` |
| Feature graphic | 1024×500 PNG | `assets/store/play_feature_graphic.png` |
| Phone screenshots | 2–8, PNG/JPEG, 9:16 or 16:9, ≥1080 px short side | capture from the running app |
| Tablet screenshots | Optional — skip for launch | — |

Suggested screenshots: home screen with stats, group review (4-up), swipe mode,
the freed-space celebration banner.

## Content rating & audience

- **Content rating questionnaire:** category Utility; answer "No" to all
  violence / sexual / profanity / drugs / gambling / etc. → results in
  Everyone / PEGI 3.
- **Ads declaration:** Yes, contains ads.
- **Target audience:** 18 and over only (keeps the app out of the Families
  Policy / child-directed AdMob restrictions).
- **"Appeals to children?":** No.

## Data safety form

- Photos/media: accessed to find duplicates, **processed on-device, not shared,
  not uploaded**.
- Advertising/device IDs: collected by Google AdMob for ads.
- No account, no location, no personal data stored on our servers.
- Data is not sold.

## Release / versioning

- Build: `flutter build appbundle --release` →
  `build/app/outputs/bundle/release/app-release.aab`
- Current version: `1.0.1+2` (versionName 1.0.1, versionCode 2).
- **Bump the `+N` in `pubspec.yaml` for every new upload** (Play rejects a
  reused version code).
- Upload via: Play Console → Test and release → (track) → Create new release →
  upload AAB → review → roll out.

## Still TODO before public launch

- [ ] EU ad consent (UMP) flow in code
- [ ] Phone screenshots
- [ ] Complete all Play Console "App content" forms
- [ ] Deploy website so the privacy policy URL is live (`firebase deploy`)
