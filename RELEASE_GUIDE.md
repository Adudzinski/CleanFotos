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

3. **Real AdMob IDs.** ✅ Android done — real App ID in
   `android/app/src/main/AndroidManifest.xml` and real banner/interstitial unit
   IDs in `lib/services/ad_service.dart`. iOS still uses test IDs
   (`ios/Runner/Info.plist` `GADApplicationIdentifier` + the iOS unit IDs in
   `ad_service.dart`) — fill these in only when you ship iOS. Debug builds always
   use Google test units regardless.

4. **Create the Pro in-app product.** In each store, create a **non-consumable**
   product with the exact ID `cleanpics_pro` (see `purchase_service.dart`). Set
   the price (planned: $1.99). Until this exists, the Pro button stays disabled.

5. **Privacy policy (required).** Done — hosted at
   `https://crocodata.net/cleanpics/privacy-policy.html` and linked in the app's
   Settings. Use this URL in the Play Console data-safety / store-listing forms.
   (Remember to deploy the website so the page is live: `firebase deploy`.)

6. **Ad consent (EU/UK + US).** ✅ Implemented in code via Google's UMP (User
   Messaging Platform): consent is gathered before any ad loads, ads are gated on
   `canRequestAds`, and Settings has an "Ad privacy options" entry for revocation.
   **Console steps (do these):** in AdMob → Privacy & messaging, create & publish
   the **GDPR** message and the **US states** message. Use **UMP SDK** deployment
   (not "ad unit deployment") so the in-app privacy options satisfy the
   revocation-link requirement. To publish, enable the ad-partner toggles and set
   the privacy-policy URL on the message.

7. **Bump the version** in `pubspec.yaml` (currently `1.0.1+2`).

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

## 3. Go-live checklist (Android — don't ship without these)

- [x] Real bundle ID (`com.crocodata.cleanpics`).
- [x] Real app icon + branded splash (no boxed logo on Android 12+).
- [x] Real AdMob app + unit IDs (Android).
- [ ] `cleanpics_pro` product created and priced in Play Console.
- [ ] Release signing configured (Android keystore).
- [x] Hosted privacy policy URL, linked in Settings.
- [x] UMP consent flow in code; [ ] GDPR + US messages published in AdMob.
- [ ] Play Console: Data safety form, photo-permission declaration, app-ads.txt.
- [ ] Tested on a real device (from a Play track): photos load, delete works,
      ads show, Pro unlock + restore work.
- [ ] Store listings, screenshots, content rating / data safety completed.

(iOS is deferred — see section 2 when you're ready.)

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
