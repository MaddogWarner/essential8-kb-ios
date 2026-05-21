# Essential 8 Knowledge Base

An iOS quick-reference for system administrators implementing the ASD Essential Eight using built-in Windows OS tooling.

## Purpose

Open the app, pick one of the eight mitigations, choose a Maturity Level (ML1, ML2 or ML3), and read the specific configuration changes — Group Policy paths, registry keys, PowerShell, `wbadmin`, `icacls`, `vssadmin` — required to meet that level. Designed for use on a phone next to a console, not as a learning resource.

The optional **M365 Additional Controls** settings page lets administrators select a Microsoft 365 licensing mode so maturity-level pages can show separate Microsoft 365 / Microsoft Defender additions without mixing them into the built-in Windows guidance.

## Scope

- Covers the **November 2023** release of the ASD Essential Eight Maturity Model.
- Only configuration achievable using **built-in Windows OS tooling** is documented (Group Policy, registry, AppLocker, Windows Defender Application Control, Microsoft Defender / ASR rules, Windows Update for Business, Windows LAPS, Windows Hello for Business, Windows Server Backup, ReFS, Credential Guard, etc.).
- Where a Maturity Level requires capability beyond what Windows ships natively (e.g. authenticated vulnerability scanning, cloud IdP for phishing-resistant MFA at ML3, immutable backup storage), the gap is called out explicitly on that level's screen under **"Beyond Windows built-in tooling"**.
- Microsoft 365 additions are hidden by default. If enabled, they are shown as additional or partial supports based on the selected licensing mode: **E3 + Entra ID P1**, **E3 + Entra ID P2**, or **E5**.
- Always verify against the current ASD Maturity Model before implementing — content reflects the model as known at the time of writing.

## Mitigations covered

1. Application Control
2. Patch Applications
3. Configure Microsoft Office Macros
4. User Application Hardening
5. Restrict Administrative Privileges
6. Patch Operating Systems
7. Multi-factor Authentication
8. Regular Backups

Each control surfaces an **ML0** description ("no controls implemented" — what an unmitigated environment looks like for this specific control) alongside the ML1/ML2/ML3 buttons.

## Navigation

- **Home** → list of all eight mitigations + M365 Additional Controls + About & Privacy.
- **M365 Additional Controls** → persisted local settings for None, E3 with P1/P2, or E5.
- **Control detail** → overview, ML0 description, three Maturity Level buttons.
- **Maturity Level detail** → optional M365 / MDE additions followed by numbered implementation steps with monospaced, copy-able command / GPO path / registry-key blocks. Tap-and-hold a code block to copy.
- A back chevron is provided automatically on every pushed screen via `NavigationStack`. Swipe-from-edge to go back also works.

## Project structure

```
Essential 8 Knowledge Base/
├── Essential_8_Knowledge_BaseApp.swift   App entry point
├── ContentView.swift                     Root NavigationStack wrapping HomeView
├── HomeView.swift                        List of mitigations + About sheet trigger
├── ControlDetailView.swift               Overview, ML0, ML1/2/3 buttons
├── MaturityLevelView.swift               Step-by-step implementation detail
├── Microsoft365SettingsView.swift        M365 Additional Controls settings page
├── Microsoft365LicenseMode.swift         Persisted M365 mode values
├── Microsoft365AdditionalControlsData.swift
│                                           M365 / MDE additions by control
├── AboutView.swift                       Purpose + Privacy Policy (modal sheet)
├── AppInformation.swift                  Static About / Privacy strings
├── EssentialControl.swift                Data model
├── EssentialControlsData.swift           All control + ML content
└── Assets.xcassets
```

## Architecture notes

- Pure SwiftUI. No SwiftData, no Combine, no `Observable` model objects — content is static, held in an `enum EssentialControlsData` namespace.
- `NavigationStack` with value-based navigation (`NavigationLink(value:)` + `.navigationDestination(for:)`).
- iOS 26+ deployment target. Liquid Glass styling is inherited from standard components; no custom theming.
- No analytics, no network calls, no persisted user data. The app is entirely offline.
- The selected M365 licensing mode is stored locally with `@AppStorage` and defaults to `None`.

## Privacy

Essential 8 Knowledge Base does not collect, record, store, transmit or share any user data. It does not require account access and does not request the microphone, camera, location services, contacts, photos or other device sensors. See `AppInformation.swift` for the canonical privacy text shown in-app.

## Building

Open `Essential 8 Knowledge Base.xcodeproj` in Xcode 26 or later and build for an iOS 26+ simulator or device. No dependencies, no package manager, nothing to install.

## Testing

The test targets include lightweight shipping checks:

- Unit tests verify that all eight controls are present, mitigation IDs are unique, maturity-level content is populated, and the in-app privacy copy covers the expected no-data-collection statements.
- Unit tests verify that M365 / MDE additions are hidden for `None` and expand for E3 P1, E3 P2 and E5 modes.
- UI tests verify the app launches to the home screen, shows the mitigation list, opens the M365 Additional Controls settings page, and opens the About & Privacy sheet.

## Credits

Built collaboratively:

- **Claude** — app scaffold, data model, content for the eight controls across ML0–ML3, and the home / control-detail / maturity-level views.
- **Codex** — About & Privacy screen, M365 Additional Controls settings, M365 / MDE additions, the `AppInformation` copy module, stable identifiers on implementation steps, and the unit / UI test suites.

## Disclaimer

The content provided is a **reference**, not authoritative guidance. Configuration changes — particularly to AppLocker / WDAC, Credential Guard, ASR rules and `SmartcardLogonRequired` — can lock users out or break business-critical software. Test in a representative non-production environment first, and validate against the current ASD Essential Eight Maturity Model and Microsoft documentation before applying changes in production.
