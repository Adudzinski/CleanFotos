# CleanFotos — Store Listing Refresh (August 2026)

Prepared after adding video cleanup. Two problems prompted this refresh, not just the new feature:

1. **Stale copy.** The listing text currently live under the "CleanFotos" title is actually the old `ASO_STORE_LISTING.md` draft, written back when the app was still called *CleanPics*. Only the title got updated when the app was renamed — the body still says "CleanPics" throughout.
2. **Outdated feature list.** That draft describes "three ways to clean" (Picture Swipe, Group Review, Video Swipe). Since the 1.2 release you actually ship **four** modes: Video Group, Video Swipe, Picture Group, and Picture Swipe — plus Picture Group itself was reworked (overscroll between groups, batched deletion).

Decision made: **keep the name CleanFotos.** It's the name already live on both stores with existing installs, reviews, and search ranking — renaming now would reset ASO history for a purely cosmetic gain. The current title ("CleanFotos: Storage Cleaner") is already media-neutral, so it doesn't need to change either. What needed fixing was the body copy: consistent branding, and the two video modes fairly represented.

Also corrected in passing: the old listing said "6 languages" — `lib/l10n/strings.dart` shows a Polish locale was added since, making it 7.

---

## App identity (unchanged)

| Field | Value |
|---|---|
| App name | CleanFotos |
| Package / application ID | `com.crocodata.cleanpics` (internal, not user-facing) |
| Google Play | `com.crocodata.cleanpics` |
| Apple App Store | Apple ID `6792250332` |
| Current version | 1.2.0+17 |

---

## Google Play

### Title (max 30 chars) — 27 chars, unchanged

```
CleanFotos: Storage Cleaner
```

### Short description (max 80 chars) — 76 chars

```
Duplicate photo & video cleaner. Swipe or group-review to free storage fast.
```

### Full description (max 4000 chars) — ~2,600 chars

```
CleanFotos is the fastest, simplest way to clean up your gallery on Android. Find duplicate and similar photos and videos, delete the ones you don't need, and free up storage in seconds — no more endless scrolling through your gallery.

We all take the same shot ten times: a burst of selfies, a few tries at the same sunset, screenshots you forgot about, and video clips you recorded twice. CleanFotos finds those look-alikes and clutter for you and makes deleting them fast and satisfying.

━━ WHY CLEANFOTOS ━━
• Free up storage space fast by removing duplicate and similar photos and videos
• Clean up your whole gallery — photos AND videos, not just one or the other
• Big, clear, dead-simple design — no learning curve
• See exactly how much space you've reclaimed
• A little celebration every time you clean up

━━ FOUR WAYS TO CLEAN ━━
• Video Group — CleanFotos groups videos taken around the same moment, just like Picture Group. Hold any tile to play it instantly, with sound.
• Video Swipe — swipe through your videos (they take the most space!), hold to preview with sound, and delete the ones you don't want.
• Picture Group — review similar photos a few at a time and mark the ones to remove. Keep scrolling past the top or bottom of a group to move to the next one — no extra taps.
• Picture Swipe — swipe through your photos newest-first. Swipe left to delete, right to keep. Tinder-style cleanup.

━━ DUPLICATE & SIMILAR PHOTO FINDER ━━
CleanFotos automatically groups photos and videos taken around the same time, so duplicates, bursts and near-identical shots show up together. Delete the extras and keep the best — reclaim gigabytes without the hassle.

━━ PRIVATE BY DESIGN ━━
All analysis runs 100% on your device. Your photos and videos are NEVER uploaded to any server — we never see them. Deleted items go to your phone's "Recently Deleted" album, so you can restore them for about 30 days if you change your mind.

━━ FREE, WITH AN OPTIONAL UPGRADE ━━
CleanFotos is free to use, supported by ads. Don't like ads? Unlock CleanFotos Pro with a single one-time purchase to remove them forever — no subscription.

━━ MADE FOR EVERYONE ━━
Available in 7 languages: English, Spanish, German, French, Portuguese, Italian and Polish.

Clean up your photos and videos. Free up your phone. Download CleanFotos today and reclaim your storage.

Keywords: photo cleaner, video cleaner, duplicate photo remover, delete duplicate photos, similar photo finder, gallery cleaner, free up space, storage cleaner, clean up photos and videos, swipe to delete, photo organizer, video organizer.
```

---

## Apple App Store

Apple splits things Play doesn't (a separate Subtitle field under the name, a Promotional Text field you can update anytime without a new build, and a dedicated Keywords field that isn't shown to users but feeds search).

### Name (max 30 chars) — 27 chars, matches Play title for consistency

```
CleanFotos: Storage Cleaner
```

### Subtitle (max 30 chars) — 21 chars

```
Photo & Video Cleaner
```

### Promotional text (max 170 chars) — 154 chars

```
Four ways to clean: Video Group, Video Swipe, Picture Group, Picture Swipe — find duplicates and similar shots, then swipe or tap to free up storage fast.
```

### Description (max 4000 chars) — ~2,170 chars

```
CleanFotos is the fastest, simplest way to clean up your photo and video library.

We all take the same shot ten times: a burst of selfies, a few tries at the same sunset, screenshots you forgot about, and video clips you recorded twice. CleanFotos finds those look-alikes and clutter for you and makes deleting them fast and satisfying.

WHY CLEANFOTOS
• Free up storage space fast by removing duplicate and similar photos and videos
• Clean up your whole library — photos AND videos, not just one or the other
• Big, clear, dead-simple design — no learning curve
• See exactly how much space you've reclaimed
• A little celebration every time you clean up

FOUR WAYS TO CLEAN
• Video Group — CleanFotos groups videos taken around the same moment, just like Picture Group. Hold any tile to play it instantly, with sound.
• Video Swipe — swipe through your videos (they take the most space!), hold to preview with sound, and delete the ones you don't want.
• Picture Group — review similar photos a few at a time and mark the ones to remove. Keep scrolling past the top or bottom of a group to move to the next one — no extra taps.
• Picture Swipe — swipe through your photos newest-first. Swipe left to delete, right to keep. Tinder-style cleanup.

DUPLICATE & SIMILAR PHOTO FINDER
CleanFotos automatically groups photos and videos taken around the same time, so duplicates, bursts and near-identical shots show up together. Delete the extras and keep the best — reclaim gigabytes without the hassle.

PRIVATE BY DESIGN
All analysis runs 100% on your device. Your photos and videos are NEVER uploaded to any server — we never see them. Deleted items go to your phone's "Recently Deleted" album, so you can restore them for about 30 days if you change your mind.

FREE, WITH AN OPTIONAL UPGRADE
CleanFotos is free to use, supported by ads. Don't like ads? Unlock CleanFotos Pro with a single one-time purchase to remove them forever — no subscription.

MADE FOR EVERYONE
Available in 7 languages: English, Spanish, German, French, Portuguese, Italian and Polish.

Clean up your photos and videos. Free up your phone. Download CleanFotos today and reclaim your storage.
```

### Keywords field (max 100 chars, comma-separated, no spaces) — 96 chars

Apple already indexes words in Name and Subtitle, so this list deliberately skips "CleanFotos", "photo", "video", and "cleaner":

```
duplicate,remover,gallery,declutter,storage,space,swipe,similar,organizer,delete,free,album,pics
```

---

## Not done here — worth checking

- **In-app purchase display name.** The product ID is `cleanpics_pro` (internal, fine to leave). Check what display name shows to users in Play Console / App Store Connect — if it still says "CleanPics Pro" there, update it to "CleanFotos Pro" to match.
- **Screenshots.** `STORE_LISTING.md` suggests screenshots of "home screen, group review (4-up), swipe mode, celebration banner" — that predates Video Group and the reworked Picture Group. Worth recapturing to show all four modes and the new overscroll gesture.
- **Localization.** Both `TODO.md` and the old ASO doc flag the listing as English-only despite shipping 7 languages. Translating this refreshed copy is still open — happy to draft it once this English version is approved.
- **Website copy.** `TODO.md` notes `crocodata_website` already reflects Android + iOS; worth a quick check that it doesn't also describe only three cleaning modes.
