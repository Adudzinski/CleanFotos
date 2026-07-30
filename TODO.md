# CleanFotos — TODO

Current release: **1.1.0+14** · Live on Google Play (`com.crocodata.cleanpics`) and the App Store (Apple ID `6792250332`)
Last updated: 28 July 2026

---

## 1. Blocked on the next App Store release

These need a new version because the metadata fields are locked on the released build.

- [ ] **Set the Marketing URL to `https://crocodata.net`** — App Store Connect → version page → below Support URL.
      Bare root only: no `www.`, no path, no trailing slash.
      **This is what unblocks AdMob.** Apple publishes the Marketing URL as "Developer Website" on the
      product page, and that is the only field AdMob reads before appending `/app-ads.txt`.
      The Support URL (already set) shows as "App Support" and is ignored by AdMob.
- [ ] After Apple propagates (a few hours, up to 24), confirm **Developer Website** appears on
      https://apps.apple.com/us/app/cleanfotos/id6792250332
- [ ] Only then: **AdMob → Apps → CleanFotos (iOS) → app-ads.txt → Check for updates**.
      Checking earlier just fails again.

`app-ads.txt` itself is already correct and live — verified returning `200 text/plain` at
https://crocodata.net/app-ads.txt with `google.com, pub-6352577985769083, DIRECT, f08c47fec0942fa0`.
The same line covers Askra and AppSwipe (one shared publisher ID). Nothing to change there.

---

## 2. Store listing fixes (no new build needed)

- [ ] **Legal entity name is misspelled on the App Store**: shows *"Crocodata Sp. z z.o."*, should be
      **"Crocodata Sp. z o.o."** — App Store Connect → Business → Legal Entity Name.
      The Seller field further down the listing is already correct, so it's only the display name.
- [ ] **Listing is English-only** while the app ships 7 languages. Adding localisations is free ASO —
      start with DE, ES, FR, PT, IT.
- [ ] Consider Play Console → **Store listing experiments** (icon + first two screenshots).
      Conversion gains compound with every future install, paid or organic.

---

## 3. Latency — measured problems in the code

### 3.1 The library is scanned up to four times per session (biggest win)

`loadAllAssets()` is called from four places in `lib/providers/app_provider.dart`:

| Line | Call |
|---|---|
| 178 | `_service.totalCount()` → which itself calls `loadAllAssets()` |
| 192 | `allPhotos = await _service.loadAllAssets()` |
| 213 | `final all = await _service.loadAllAssets()` |
| 251 | `final all = await _service.loadAllAssets()` |

Each call re-enumerates every album and re-materialises up to 50,000 `AssetEntity` objects.

- [ ] Cache the asset list in `AppProvider` and invalidate on permission change / photo-library
      change notification, rather than reloading per screen.

### 3.2 `totalCount()` loads the whole library just to return a number

`lib/services/photo_service.dart:45-48` calls `loadAllAssets()` and returns `.length`.

- [ ] Sum `album.assetCountAsync` instead — metadata only, no asset materialisation.
      Note the dedupe caveat: albums overlap, so counting needs the "All" album where available
      rather than a naive sum across albums.

### 3.3 Album merge is O(albums × assets)

`loadAllAssets()` (`photo_service.dart:54-85`) iterates **every** album and calls
`getAssetListRange(0, count)` on each, then dedupes by id. On Samsung/Xiaomi devices with many
albums this loads the same photos repeatedly.

- [ ] Short-circuit when the system "All" album returns a count matching the device total, and only
      fall back to the merge when it looks incomplete. Keep the current behaviour as the fallback —
      the comment explains why the merge exists, and that reasoning is sound.

### 3.4 Grouping runs on the main isolate

`groupAssets()` sorts up to 50,000 assets twice (`photo_service.dart:91` and `:127`), and the second
sort calls `librarySortTime` inside a `reduce` for every group on every comparison — that's repeated
work inside the comparator.

- [ ] Precompute each group's newest timestamp once, then sort on the cached value.
- [ ] Move grouping into `compute()` / an isolate if profiling still shows jank.
      `AssetEntity` isn't trivially sendable, so this may need mapping to plain
      `(id, timestamp)` records first, grouping those, then re-associating.

### 3.5 Profiling to do first

- [ ] Run in profile mode on a real device with a large library (10k+ photos) and capture a timeline.
      Confirm where time actually goes before optimising — the four scans are the obvious suspect,
      but thumbnail decoding in `photo_card.dart` may dominate on the grid screens.
- [ ] Check whether `maxPhotosToScan = 50000` silently truncates real users' libraries, and whether
      that truncation is communicated in the UI.

---

## 4. Group mode — the real weakness

**Grouping is currently time-only.** `PhotoService.timeWindowSeconds = 180` puts every photo taken
within 3 minutes into the same group, with no visual comparison at all.

Consequences:

- Photos of *completely different subjects* taken 3 minutes apart are presented as duplicates.
- `similarityScore: 0.95` (`photo_service.dart:107`) is **hardcoded**, not computed. Any UI showing
  it is showing a constant.
- The App Store description promises "look-alike shots" and "similar and duplicate photos" — time
  proximity is a weak proxy for that claim.

Ideas, cheapest first:

- [ ] **Tighten the window and make it adaptive.** A burst is seconds apart, not minutes. Consider
      ~10 s for the base window, widening only when EXIF suggests continuous shooting.
- [ ] **Add a perceptual hash** (dHash/aHash over a small thumbnail, e.g. 8×8 or 9×8 grayscale) and
      split each time-group by Hamming distance. This is the real fix: cheap, on-device, no ML model,
      and it makes `similarityScore` an actual number.
      Compute lazily per group when the user opens it, and cache by asset id so it isn't recomputed.
- [ ] **Sub-group within a group** rather than showing one flat list — "3 of these 7 are near-identical".
- [ ] Consider surfacing **exact duplicates** (same size + same hash) as a separate, high-confidence
      category — that's the case users trust most and delete fastest.

---

## 5. Accuracy issues worth fixing alongside

- [ ] **Freed-space numbers are estimates, not measurements.** `photo_service.dart:106` uses
      `current.length * kAvgPhotoBytes`, and `estimateStats()` does the same for the whole library.
      If the UI shows "free up 240 MB", that figure can be materially wrong.
      Use `asset.file` / `AssetEntity` size where available, or clearly label the figure as approximate.
- [ ] Once real sizes are used, the celebration overlay total becomes trustworthy.

---

## 6. Elsewhere (not this repo)

- Company-wide legal and compliance open items live in
  `C:\Users\alexa\crocodata_website\COMPLIANCE.md` — including the Impressum gaps, DPAs to confirm,
  trademark clearance, and the UK/Swiss representative question.
- The website already reflects CleanFotos as **Android + iOS**, with both store links, dual-platform
  terms, privacy policy and deletion instructions (all v3.0, 28 July 2026).
- Website deploy: `cd C:\Users\alexa\crocodata_website` → `.\scripts\deploy.ps1`

---

## 7. Suggested order for the next version

1. Profile on a real device — establish the baseline.
2. Cache the asset list; fix `totalCount()`. Biggest perceived speed win, lowest risk.
3. Fix the group sort comparator.
4. Perceptual hashing for group quality — the feature that differentiates the app.
5. Real file sizes.
6. Ship, and set the **Marketing URL** in the same submission.
7. Verify AdMob.
