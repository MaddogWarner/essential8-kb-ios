# Essential 8 Knowledge Base

An iOS quick-reference for system administrators implementing the ASD Essential Eight using built-in Windows OS tooling.

## Purpose

Open the app, pick one of the eight mitigations, choose a Maturity Level (ML1, ML2 or ML3), and read the specific configuration changes — Group Policy paths, registry keys, PowerShell, `wbadmin`, `icacls`, `vssadmin` — required to meet that level. Designed for use on a phone next to a console, not as a learning resource.

The optional **M365 Additional Controls** settings page lets administrators select a Microsoft 365 licensing mode so maturity-level pages can show separate Microsoft 365 / Microsoft Defender additions without mixing them into the built-in Windows guidance.

## Scope

- Covers the **November 2023** release of the ASD Essential Eight Maturity Model.
- Only configuration achievable using **built-in Windows OS tooling** is documented (Group Policy, registry, AppLocker, Windows Defender Application Control, Microsoft Defender / ASR rules, Windows Update for Business, Windows LAPS, Windows Hello for Business, Windows Server Backup, ReFS, Credential Guard, etc.).
- Where a Maturity Level requires capability beyond what Windows ships natively (e.g. authenticated vulnerability scanning, cloud IdP for phishing-resistant MFA at ML3, immutable backup storage), the gap is called out explicitly on that level's screen under **"Beyond Windows built-in tooling"**.
- ISM control identifiers are sourced from ASD's *Essential Eight maturity model and ISM mapping* (October 2024) and displayed on mapped implementation steps. Global Search can find both full IDs (e.g. `ISM-1490`) and numeric fragments.
- Implementation steps carry conservative **Workstation**, **Server** or **Both** scope tags. The About-page selector filters Home, control and maturity pages, and Global Search; compliance is recalculated only over visible in-scope steps.
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

- **Home** → welcome splash screen on startup (recurrence toggled via custom checkbox) + compliance dashboard (optional, hideable via Reference Only Mode, containing target maturity picker, overall compliance ring & stacked bar chart) + list of all eight mitigations + M365 Additional Controls + About & Privacy.
- **Global Search** → search bar for querying GPO paths, registry paths, commands, and ISM identifiers across all controls, with direct navigation to matched steps.
- **M365 Additional Controls** → persisted local settings for None, E3 with P1/P2, or E5.
- **Control detail** → overview, ML0 description, three Maturity Level buttons, target-scoped compliance percentage progress, and beyond-target badges for maturity levels above the selected target.
- **Maturity Level detail** → optional M365 / MDE additions followed by scope-filtered implementation steps with OS scope capsules and verified ISM tags, a multi-state status selection menu (Implemented, Not Applicable with custom reason, Not Implemented) and copy-able technical details.
- **About & Privacy** → modal sheet with app purpose, author references, privacy policy statements, OS Scope and Reference Only Mode preferences, offline Backup & Restore actions, bundle-driven version/build display, external ASD/Microsoft links, App Store rating link, and local data reset buttons.

## Project structure

```
Essential 8 Knowledge Base/
├── Essential_8_Knowledge_BaseApp.swift   App entry point
├── ContentView.swift                     Root NavigationStack wrapping HomeView
├── HomeView.swift                        List of mitigations + target-scoped compliance dashboard + About sheet
├── SplashView.swift                      Startup screen with app overview & current-build updates
├── GlobalSearchView.swift                Search interface for GPOs, registry keys, commands, and ISM IDs
├── ControlDetailView.swift               Overview, ML0, target-scoped compliance & level buttons
├── MaturityLevelView.swift               Scope-filtered detail with OS/ISM tags, status Menu & N/A reason prompt
├── Microsoft365SettingsView.swift        M365 Additional Controls settings page
├── Microsoft365LicenseMode.swift         Persisted M365 mode values
├── Microsoft365AdditionalControlsData.swift
│                                           M365 / MDE additions by control
├── AboutView.swift                       Purpose, privacy, backup/restore, preferences, version + reset
├── AppInformation.swift                  About / Privacy strings, rating URLs and bundle version
├── BackupFile.swift                      Versioned JSON backup schema, encoding and validation
├── EssentialControl.swift                Data model
├── EssentialControlsData.swift           All control + ML content
├── ProgressStore.swift                   Store tracking step statuses (Implemented/NA/Not Implemented) & reset logic
└── Assets.xcassets
```

## Architecture notes

- Pure SwiftUI. Uses a Combine-backed `ProgressStore` to persist implementation step status (Implemented, Not Applicable, Not Implemented) via `UserDefaults` with support for legacy progress migration.
- `NavigationStack` with value-based navigation (`NavigationLink(value:)` + `.navigationDestination(for:)`).
- iOS 26+ deployment target. Leverages SwiftUI's Charts framework for rendering visual compliance progress.
- No analytics, no network calls, no persisted user data outside the device. The app is entirely offline.
- The selected M365 licensing mode is stored locally with `@AppStorage` and defaults to `None`.
- The selected target maturity level is stored locally with `@AppStorage` and defaults to ML3 so existing compliance totals remain unchanged until the user chooses a lower target.
- The selected OS scope is stored locally with `@AppStorage` and defaults to Both. Backup export/import remains fully offline and transfers all progress plus persisted settings.

### Backup format & persistence rule

The versioned backup JSON schema lives in `BackupFile.swift`. Every future persisted setting must be added to `PersistedSettingsKey`, `BackupSettings`, and both transfer functions in `ProgressStore`; `testBackupCoversAllPersistedKeys` enforces coverage. Breaking backup-format changes must increment `schemaVersion`.

## Privacy

Essential 8 Knowledge Base does not collect, record, store, transmit or share any user data. It does not require account access and does not request the microphone, camera, location services, contacts, photos or other device sensors. See `AppInformation.swift` for the canonical privacy text shown in-app.

## Building

Open `Essential 8 Knowledge Base.xcodeproj` in Xcode 26 or later and build for an iOS 26+ simulator or device. No dependencies, no package manager, nothing to install.

## Testing

The test targets include lightweight shipping checks:

- Unit tests verify that all eight controls are present, mitigation IDs are unique, maturity-level content is populated, and the in-app privacy copy covers the expected no-data-collection statements.
- Unit tests verify that M365 / MDE additions are hidden for `None` and expand for E3 P1, E3 P2 and E5 modes.
- Unit tests verify that `ProgressStore` calculates compliance percentage correctly with mixed implementation states, handles target-scoped maturity calculations, handles state persistence, and resets all configurations including Reference Only Mode and Target Maturity Level.
- Unit tests verify ISM identifier format, OS scope truth tables and content tags, scope-filtered compliance, backup validation/round trips, persisted-key coverage, and search matching behaviour for ISM IDs.
- UI tests verify the app launches to the home screen, shows the mitigation list, opens the M365 Additional Controls settings page, persists the Target Maturity Level and OS Scope pickers, shows the dynamic version row and beyond-target badges, toggles Reference Only Mode, and opens About & Privacy.

## Credits

Built collaboratively:

- **Claude** — app scaffold, data model, content for the eight controls across ML0–ML3, and the home / control-detail / maturity-level views.
- **Codex** — About & Privacy screen, M365 Additional Controls settings, M365 / MDE additions, the `AppInformation` copy module, stable identifiers on implementation steps, and the unit / UI test suites.

## Disclaimer

The content provided is a **reference**, not authoritative guidance. Configuration changes — particularly to AppLocker / WDAC, Credential Guard, ASR rules and `SmartcardLogonRequired` — can lock users out or break business-critical software. Test in a representative non-production environment first, and validate against the current ASD Essential Eight Maturity Model and Microsoft documentation before applying changes in production.
