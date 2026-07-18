# CleanFotos (iOS) — Codemagic → TestFlight setup

The repo already has `codemagic.yaml` (workflow **iOS → TestFlight**) and an iOS
`Podfile`. You just need to connect the accounts once. No Mac required.

## 0. Prerequisites

- **Apple Developer Program** membership ($99/year) — enrolled and active.
- **App Store Connect app record** for CleanFotos — you created this. It must
  use bundle ID **`com.crocodata.cleanpics`** (same as the code). Check under
  App Store Connect → your app → **App Information → Bundle ID**. If it's
  different, tell me and I'll change it in the project + `codemagic.yaml`.
- Your code pushed to GitHub (`Adudzinski/CleanFotos`), including the new
  `ios/Podfile` and `codemagic.yaml`:
  ```powershell
  git add . && git commit -m "iOS: Podfile + Codemagic TestFlight" && git push
  ```

## 1. Create an App Store Connect API key

This lets Codemagic sign the app and upload to TestFlight for you.

1. App Store Connect → **Users and Access → Integrations → App Store Connect API**.
2. Click **+** to generate a key. Give it a name, access role **App Manager**.
3. **Download the `.p8` file** (you only get one chance).
4. Note the **Issuer ID** (top of the page) and the **Key ID** (next to the key).

## 2. Sign up for Codemagic & add the app

1. Go to **codemagic.io** → sign up with your **GitHub** account.
2. Authorize access to the `Adudzinski/CleanFotos` repository.
3. Add it as an app. Codemagic will detect `codemagic.yaml` automatically.

## 3. Add the API key to Codemagic (this is the key step)

1. In Codemagic: **Teams** (or your user) → **Integrations → Developer Portal → Manage keys → Add key**.
2. Upload the `.p8`, and enter the **Issuer ID** and **Key ID** from step 1.
3. **Name the integration exactly `CleanPics`** — this must match
   `integrations: app_store_connect: CleanPics` in `codemagic.yaml`. (If you
   name it something else, change that line to match.)

## 4. Fill in the numeric App ID

1. App Store Connect → your app → **App Information → Apple ID** (a number like
   `6751234567`).
2. Open `codemagic.yaml` and set:
   ```yaml
   APP_STORE_APPLE_ID: "6751234567"
   ```
   (This makes build numbers auto-increment from the latest TestFlight build.)
   Commit + push. It also works empty — it just uses the pubspec build number.

## 5. Run the build

1. In Codemagic, open the app → pick the **iOS → TestFlight** workflow →
   **Start new build** on branch `main`.
2. Codemagic will: install pods, auto-create the signing certificate +
   provisioning profile via your API key, build the signed `.ipa`, and upload it
   to TestFlight.
3. First build takes ~10–20 min. If signing fails, it's almost always a bundle
   ID mismatch (step 0) or the integration name not matching (step 3).

> Tip: to verify the app compiles before touching Apple credentials, run the
> **iOS unsigned smoke build** workflow first — it needs no keys.

## 6. Test on your iPhone

1. After the build, App Store Connect → **TestFlight**. The build shows
   "Processing" for ~10–30 min, then becomes available.
2. Add yourself as an **Internal tester** (TestFlight → Internal Testing).
3. Install the **TestFlight** app on your iPhone and open the invite.

## iOS-specific notes (not blocking TestFlight, but know these)

- **Ads:** the app uses Google's **test** ad units on iOS (no iOS AdMob app
  created yet), so test ads show — fine for TestFlight. Create an iOS AdMob app
  + real unit IDs before a public App Store release, and set the real
  `GADApplicationIdentifier` in `ios/Runner/Info.plist`.
- **In-app purchase:** the `cleanpics_pro` product must ALSO be created in App
  Store Connect (separate from Google Play) for the Pro unlock to work on iOS.
- **App Tracking Transparency:** not implemented, so iOS serves
  non-personalized ads only. Add ATT + `NSUserTrackingUsageDescription` later if
  you want personalized ads on iOS.
- **Permissions:** the `Podfile` compiles only the Photos permission and strips
  the rest, so Apple review won't flag unused permission APIs.

## What to send me if you get stuck

The Codemagic build log (or the specific error line) — signing and pod errors
are usually a one-line fix.
