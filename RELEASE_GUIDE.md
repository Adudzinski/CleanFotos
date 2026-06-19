# CleanPics — Release Guide

A step-by-step path to publishing CleanPics on the **Google Play Store** and
the **Apple App Store**. Do the "Prepare once" section first, then follow the
store you're targeting.

---

## 0. Prepare once (both stores)

These apply regardless of platform.

1. **Bundle/application ID.** Set to `com.crocodata.cleanpics`.
   - Android: already set in `android/app/build.gradle.kts` → `applicationId`.
   - iOS: still needs to be set to `com.crocodata.cleanpics` in Xcode (see iOS
     section).

2. **App icon & name.** Replace the default Flutter icon.
   - Add `flutter_launcher_icons` to `dev_dependencies`, point it at a 1024×1024
     PNG, and run it. This generates all Android/iOS icon sizes.
   - The in-app logo placeholder (`auto_awesome` icon) can stay or be replaced.

3. **Real AdMob IDs.** Replace the Google **test** IDs with your own:
   - App IDs: `android/app/src/main/AndroidManifest.xml` and
     `ios/Runner/Info.plist` (`GADApplicationIdentifier`).
   - Unit IDs: `lib/services/ad_service.dart` (banner + interstitial).

4. **Create the Pro in-app product.** In each store, create a **non-consumable**
   product with the exact ID `cleanpics_pro` (see `purchase_service.dart`). Set
   the price (planned: $1.99). Until this exists, the Pro button stays disabled.

5. **Privacy policy (required).** Because the app accesses photos and shows ads,
   both stores require a hosted privacy policy URL. Generate one (e.g. with a
   free policy generator) and host it (a GitHub Pages page works).

6. **Ad consent (EU/UK).** Add Google's UMP consent flow (User Messaging
   Platform) so EU users get a GDPR consent prompt before personalized ads.
   This is required by AdMob policy for EU traffic.

7. **Bump the version** in `pubspec.yaml` (`version: 1.0.0+1` → name+build).

---

## 1. Google Play Store (Android)

**Accounts & cost:** Google Play Developer account — one-time **$25**.

### Build setup

1. **Create a signing keystore** (do this once, keep it safe forever):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Create `android/key.properties`** (do NOT commit it):
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<absolute path to upload-keystore.jks>
   ```
3. **Wire release signing** in `android/app/build.gradle.kts`: load
   `key.properties` and set the `release` `signingConfig` to use it (replace the
   current "signs with debug keys" placeholder).

### Build the release bundle

```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Publish

1. Play Console → **Create app** → fill name, language, app/game, free/paid.
2. Complete the required forms: **store listing** (description, screenshots from
   a Pixel emulator, feature graphic), **content rating**, **data safety** (you
   access photos + use ads → declare it), **target audience**, **privacy policy
   URL**.
3. **Monetize → Products → In-app products**: create `cleanpics_pro`.
4. **Upload the AAB** to a testing track first (Internal testing), install via
   the opt-in link, verify photos load, ads show, and Pro purchase works (use a
   license-test account so you aren't charged).
5. Promote the release to **Production** and submit for review.

---

## 2. Apple App Store (iOS)

**Accounts & cost:** Apple Developer Program — **$99/year**. Requires a Mac with
Xcode.

### Build setup (in Xcode)

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **Signing & Capabilities** → select your Team, set the Bundle Identifier to
   your real ID. Enable automatic signing.
3. Set the **app icon** (the asset catalog; flutter_launcher_icons fills this).
4. Add the **In-App Purchase** capability.

### Build & upload

```bash
flutter build ipa --release
```
Then open the generated archive in Xcode's **Organizer** (or use **Transporter**)
and upload to App Store Connect.

### Publish

1. App Store Connect → **My Apps → +** → create the app (pick the bundle ID).
2. Fill the listing: description, keywords, screenshots (required sizes for
   iPhone), support URL, **privacy policy URL**, and **App Privacy** answers
   (photos access, ads/tracking via AdMob → declare).
3. **Features → In-App Purchases**: create the `cleanpics_pro` non-consumable.
4. Add the build (from your upload) to the version, optionally test via
   **TestFlight** first.
5. **Submit for review.**

---

## 3. Go-live checklist (don't ship without these)

- [ ] Real bundle ID (no `com.example`).
- [ ] Real app icon.
- [ ] Real AdMob app + unit IDs (test IDs removed).
- [ ] `cleanpics_pro` product created and priced in both stores.
- [ ] Release signing configured (Android keystore; iOS team).
- [ ] Hosted privacy policy URL.
- [ ] UMP consent flow for EU ads.
- [ ] Tested on a real device: photos load, delete works, ads show, Pro unlock +
      restore work.
- [ ] Store listings, screenshots, content rating / app privacy completed.

---

## 4. After launch

- **ASO** (App Store Optimization): a clear title, keyword-rich description, and
  good screenshots drive most organic installs.
- **Prompt for ratings** right after a big, satisfying cleanup (use the native
  in-app review APIs).
- Watch crash reports and AdMob/IAP revenue; iterate on the TODO list in
  `PROJECT_OVERVIEW.md` (undo, reverse-geocoded locations, videos/screenshots).

---

### Quickest possible path
Android is faster and cheaper to launch first ($25, no Mac needed): finish the
"Prepare once" list, set up signing, `flutter build appbundle --release`, and
push to Play Console internal testing → production. Add iOS later.
