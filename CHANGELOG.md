# Changelog

## 1.1 — 2026-06-24

- Bumped marketing version to 1.1 and build number to 2 for the next App Store release.
- Added persistent implementation-progress tracking: tap-to-tick steps on each maturity-level page, per-level counters on the control detail page, and a green completion badge on the home screen when every step for a control is marked done. Progress survives app relaunches via `UserDefaults`.
- Replaced runtime UUIDs on implementation steps with stable `controlID-level-index` identifiers so progress state can persist across launches and builds.
- Added a Windows Audit Policy reference page accessible from the home screen, covering ASD-recommended minimum Windows Security Audit Policy settings for detection and response.
- Added an app-specific privacy policy link to the About & Privacy screen for App Store review and user access, while keeping the existing short in-app privacy summary.

## 0.2.1 — 2026-05-21

- Changed the bundle identifier from `au.com.maddogwarner.Essential-8-Knowledge-Base*` to `com.maddogwarner.Essential-8-Knowledge-Base*` across the app, unit test, and UI test targets.

## 0.2.0 — 2026-05-21

- Added a `MaturityLevel` enum for ML1, ML2, and ML3 so maturity-level selection is represented by a valid type instead of raw integers.
- Updated control detail and maturity-level navigation to use the new maturity-level type.
- Documented that Microsoft 365 / Microsoft Defender additions apply across maturity levels, while still tailoring their page copy to the selected maturity level.
- Reworked the M365 Additional Controls settings selection to use a typed SwiftUI binding backed by `@AppStorage`.
- Updated the home toolbar title to use a Dynamic Type-aware system text style instead of a fixed custom font size.
- Made implementation steps identifiable for cleaner SwiftUI list identity.
- Expanded content sanity tests to validate all eight Essential Eight controls and each ML1, ML2, and ML3 content set.
- Updated Office macro ML3 guidance to avoid unverified registry values and point to the V3 signature policy path and signing workflow instead.
- Updated PowerShell Constrained Language Mode guidance to lead with WDAC/AppLocker enforcement and mark `__PSLockdownPolicy` as temporary validation only.
- Verified live Xcode diagnostics are clean for touched files.
- Verified the project builds successfully in Xcode after the review fixes.

## 0.1.0 — 2026-05-20

- Added an About & Privacy button to the bottom of the home page.
- Added an About screen describing the app as a quick technical reference for administrators working with Essential Eight controls.
- Added an in-app privacy policy stating the app does not collect, record, store, transmit, or share user data, and does not request microphone, camera, location, contacts, photos, or sensor access.
- Centralised About and privacy copy in `AppInformation` for reuse by the UI and tests.
- Updated the home screen navigation title to display `Essential 8` and `Knowledge Base` on separate lines so the full app name fits more cleanly.
- Increased only the custom home screen title font size for better readability.
- Added a persisted M365 Additional Controls settings page with `None`, `E3 + P1`, `E3 + P2`, and `E5` modes.
- Added a Done button to the M365 Additional Controls settings page so users can return directly to Home after changing license mode.
- Added separate M365 / MDE additions to maturity-level pages when a Microsoft 365 mode is selected.
- Added Microsoft 365 / Microsoft Defender content covering additional and partial protections by Essential Eight control.
- Added tappable About screen reference links for ASD Essential Eight, the ASD Information Security Manual, and Microsoft 365 / Defender documentation.
- Made the About screen Done button dismiss through both the sheet binding and SwiftUI presentation dismiss so it reliably returns to Home.
- Used simple list identity for maturity implementation steps during the initial UI build.
- Replaced placeholder unit tests with content and privacy-copy sanity checks.
- Replaced placeholder UI tests with launch, home-screen, and About & Privacy flow checks.
- Verified the project builds successfully in Xcode.

### Contributors

- Claude — initial app scaffold: data model, content for all eight controls across ML0–ML3, home / control / maturity-level views, removal of the SwiftData starter template.
- Codex — About & Privacy screen, `AppInformation` copy module, stable identifiers on implementation steps, unit and UI test suites, build verification.
