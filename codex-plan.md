# codex-plan.md — v1.6: OS Scope Tags + Progress Backup & Transfer

**Authored by:** Claude (13/07/2026)
**Implemented by:** Codex, in step order. Run the verification gate after each step before moving on.
**Scope:** exactly what is written here. If a step has a technical or security problem, stop and surface it — don't build the flaw.
**Prerequisite:** branch off current `main`, which already contains the v1.5 content corrections (merged 05/07/2026, PR #9) and the CodeQL workflow (PR #10). Do not build from the stale `fix/content-corrections-v1.5` branch.

---

## Overview

Two features for version 1.6, plus About-page version display and version housekeeping:

- **Feature A — OS scope tags (Workstation vs Server filtering).** Every implementation step is tagged with where it applies: Windows 11 client, Windows Server, or both. A three-way selector on the About page (Workstation / Server / Both, default **Both**) filters the whole app: out-of-scope steps are hidden from lists and search, and all compliance metrics recalculate over the in-scope step set only.
- **Feature B — Progress backup and transfer (export/import).** JSON export of all persistent app state via the share sheet (AirDrop, Files, etc.) and import from the Files picker, replacing local state after an explicit confirmation. Fully offline — no network, no new entitlements.
- **About page:** displays the app version and build number read from the bundle, so it updates automatically on every version bump with no code change.

Design decisions (locked — do not revisit):

1. **Filtering hides and recalculates.** When the scope is Workstation or Server, out-of-scope steps disappear from maturity level pages, control detail progress, the home dashboard and Global Search, and every compliance computation runs over the filtered step set — consistent with how Not Applicable already excludes steps from the denominator.
2. **Default scope is Both**, so existing users see no change until they choose otherwise. Stored in `UserDefaults` like every other setting; no data migration.
3. **Tagging is conservative.** A step is tagged `workstation` or `server` only when the content is unambiguous (e.g. `wbadmin`/Windows Server Backup → server; Credential Guard, ASR rules, Office/browser client hardening → workstation). Anything uncertain stays `both`. **A wrong tag that hides a step someone needed is the same defect class as a wrong ISM identifier: an over-broad `both` is correct; a wrong narrow tag is a defect.**
4. **Export captures all persistent state** — step progress plus every setting (M365 licence mode, target maturity level, splash toggle, reference-only mode, OS scope). A restored device behaves identically to the old one.
5. **Import replaces, never merges**, behind a confirmation dialog that states existing data will be overwritten. A file that fails validation changes nothing — no partial imports.
6. **Single source of truth for persisted state.** All persisted `UserDefaults` keys are declared in one registry that `resetAll()`, the backup encoder and the backup decoder all consume. A unit test asserts the backup covers every registered key. **Standing rule for every future version: any new feature that persists data must add its key to this registry, which forces it into export/import and Reset App Data — see Step 8.**
7. All data stays local (`UserDefaults` / `@AppStorage` / temporary export file), consistent with the app's privacy posture. No new entitlements, no network.

---

## Verification gates

- **GATE-BUILD** (every step):
  ```
  xcodebuild -scheme "Essential 8 Knowledge Base" -destination "generic/platform=iOS Simulator" -configuration Debug clean build CODE_SIGNING_ALLOWED=NO
  ```
- **GATE-TEST** (steps 9–10): same scheme against a named simulator, e.g.
  ```
  xcodebuild -scheme "Essential 8 Knowledge Base" -destination "platform=iOS Simulator,name=iPhone 16" test CODE_SIGNING_ALLOWED=NO
  ```
  (Substitute any installed iPhone simulator if that name is unavailable.)

---

## Step 1 — Data model: OS scope on steps

**Files:** `EssentialControl.swift`, `EssentialControlsData.swift`

1. Add to `EssentialControl.swift`:
   ```swift
   /// Where an implementation step applies. `both` is the safe default —
   /// only tag `workstation` or `server` when the content is unambiguous.
   enum OSScope: String, Codable, CaseIterable {
       case workstation
       case server
       case both
   }
   ```
2. Add to `ImplementationStep`:
   ```swift
   /// OS scope this step applies to. Defaults to `.both`; see OSScope.
   let osScope: OSScope
   ```
   with `osScope: OSScope = .both` in the memberwise `init`.
3. Give the private `step(...)` helper in `EssentialControlsData.swift` a new parameter `osScope: OSScope = .both` and pass it through, so the whole data file compiles unchanged before Step 3 populates tags.
4. Add the filtering helpers to `EssentialControl.swift`:
   ```swift
   extension ImplementationStep {
       /// True when this step is in scope for the user's selected filter.
       func matches(scope filter: OSScope) -> Bool {
           filter == .both || osScope == .both || osScope == filter
       }
   }

   extension EssentialControl {
       /// All steps in scope when targeting `level`, filtered to `scope`.
       func steps(upTo level: MaturityLevel, scope: OSScope) -> [ImplementationStep] {
           steps(upTo: level).filter { $0.matches(scope: scope) }
       }
   }
   ```
   Keep the existing `steps(upTo:)` — callers that must ignore the filter (none today, tests tomorrow) still have it.

**Gate:** GATE-BUILD.

---

## Step 2 — Scope filter persistence

**Files:** `ProgressStore.swift`

1. Storage key: `"osScopeFilter"`, the `String` raw value of `OSScope`, read via `@AppStorage` in views (same pattern as `targetMaturityLevel`). Default `OSScope.both.rawValue`. Invalid raw values fall back to `.both`.
2. Change `isControlComplete` to take the scope:
   ```swift
   func isControlComplete(_ control: EssentialControl, upTo target: MaturityLevel, scope: OSScope) -> Bool
   ```
   Same logic over `control.steps(upTo: target, scope: scope)`. Update the call site (HomeView, Step 4). Remove the old signature — don't keep both.
3. `resetAll()` gains the new key — but do this via the registry refactor in Step 8, not by adding a sixth hardcoded line here. If Step 8 hasn't happened yet when you reach this line, add the hardcoded key now and let Step 8 absorb it.

**Gate:** GATE-BUILD.

---

## Step 3 — Tag the content

**Files:** `EssentialControlsData.swift` only (the Windows Audit Policy and M365 pages use their own data types and are out of scope for tagging).

1. Review all 68 `step(...)` calls and add `osScope:` **only** where the step is unambiguously single-scope. Apply decision 3 (conservative tagging). Expected candidates — verify each against the step's actual text before tagging:
   - `server`: `wbadmin` / Windows Server Backup steps (Regular Backups).
   - `workstation`: Credential Guard, ASR rules (Defender ASR requires Windows 10/11 client SKU behaviour described in the step text), Office macro and browser/user-application-hardening steps that only make sense on a client.
   - Everything else stays `both` by omission (AppLocker, patching, MFA, privileged-access process steps, etc. apply to both fleets or are process-level).
2. Do **not** tag from memory of what a technology supports — tag from what the step's title, description and technical details actually say. If a step mixes client and server guidance, it stays `both`.
3. At the top of the file, extend the header comment with one line noting steps carry OS scope tags and the conservative-tagging rule.
4. Produce a handoff summary: every step tagged non-`both`, with a one-line justification each, plus a count of steps left `both` — so Claude can review the tag list in the PR (same review pattern as the ISM mapping).

**Gate:** GATE-BUILD.

---

## Step 4 — Apply the filter across the app

**Files:** `HomeView.swift`, `ControlDetailView.swift`, `MaturityLevelView.swift`, `GlobalSearchView.swift`

In each view, read `@AppStorage("osScopeFilter") private var osScopeRawValue = OSScope.both.rawValue` and compute `scopeFilter: OSScope` (fall back to `.both` on invalid raw value).

1. **HomeView:** dashboard computations (`overallTotalSteps`, implemented/NA counts, compliance percentage, `chartData`) iterate `control.steps(upTo: targetLevel, scope: scopeFilter)`. The per-control completion checkmark uses the new `isControlComplete(_:upTo:scope:)`.
2. **ControlDetailView:** `allSteps` becomes `control.steps(upTo: targetLevel, scope: scopeFilter)`. In `maturityButton(level:content:)`, the per-level `doneCount/totalCount` counts only `content.steps.filter { $0.matches(scope: scopeFilter) }`.
3. **MaturityLevelView:** the step list, completed/NA counts and header text all use `content.steps.filter { $0.matches(scope: scopeFilter) }`. Step numbering renumbers over the filtered list — that is intended. If the filtered list is empty, show a single footnote row: `"No steps in this level apply to the selected OS scope. Change the scope in About."`
4. **GlobalSearchView:** search iterates only steps matching the scope filter, so results never deep-link to a hidden step.
5. **Scope badges:** in `MaturityLevelView`, when a step's `osScope != .both`, render a small capsule next to the step title reading `"Workstation"` or `"Server"` (`.caption2`, grey capsule — mirror the ISM capsule styling). This is the visible half of the tagging even when the filter is Both. Include the scope in the step's accessibility label.

**Gate:** GATE-BUILD. Manual check: with scope Both nothing changes anywhere; switching to Workstation removes the `wbadmin` steps from Regular Backups, renumbers the list, and the dashboard totals drop accordingly; searching for `wbadmin` under Workstation scope returns nothing.

---

## Step 5 — About page: scope selector + app version

**Files:** `AboutView.swift`, `AppInformation.swift`

1. In the existing **Preferences** section, above the Reference Only Mode toggle, add a segmented picker:
   ```swift
   Picker("OS scope", selection: $osScopeRawValue) {
       Text("Workstation").tag(OSScope.workstation.rawValue)
       Text("Server").tag(OSScope.server.rawValue)
       Text("Both").tag(OSScope.both.rawValue)
   }
   .pickerStyle(.segmented)
   ```
   with a caption label above it ("OS Scope") and extend the section footer: `"OS scope hides implementation steps that don't apply to the selected environment and recalculates compliance over the remaining steps."` Give the picker an accessibility label.
2. Add to `AppInformation`:
   ```swift
   /// Version string sourced from the bundle so it tracks MARKETING_VERSION /
   /// CURRENT_PROJECT_VERSION automatically on every release bump.
   static var versionDisplay: String {
       let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
       let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
       return "Version \(version) (\(build))"
   }
   ```
   Never hardcode the version anywhere in the UI.
3. At the bottom of the About list (below References), add a section with no header showing `AppInformation.versionDisplay` centred, `.footnote`, secondary colour.

**Gate:** GATE-BUILD. Manual check: About shows "Version 1.6 (7)" once Step 10's bump lands (shows 1.5 (6) until then — expected).

---

## Step 6 — Backup file format

**Files:** new `BackupFile.swift` in the app target

1. Define the codable envelope:
   ```swift
   /// Versioned on-disk format for full app-state backup. Bump schemaVersion
   /// only on breaking changes; additive fields decode as optionals.
   struct BackupFile: Codable {
       let schemaVersion: Int          // currently 1
       let appVersion: String          // AppInformation marketing version at export
       let exportedAt: Date            // ISO 8601 via encoder strategy
       let stepProgress: [String: StepStatus]
       let settings: BackupSettings
   }

   struct BackupSettings: Codable {
       let microsoft365LicenseMode: String?
       let targetMaturityLevel: Int?
       let showSplashOnStartup: Bool?
       let referenceOnlyMode: Bool?
       let osScopeFilter: String?
   }
   ```
   All settings optional so older backups (or hand-edited files) still import; a missing setting leaves the app default.
2. Encoder/decoder: `JSONEncoder` with `.iso8601` date strategy and `.prettyPrinted, .sortedKeys` output; decoder with `.iso8601`.
3. Validation on decode (reject the whole file on any failure — never partially apply):
   - `schemaVersion == 1` (a newer number → error telling the user to update the app).
   - File size cap of 1 MB before decoding (the real payload is a few KB; this bounds hostile input).
   - Every `stepProgress` value's `state` must decode to a valid `StepState` (Codable enforces this); imported step IDs that don't exist in the current content are **kept**, not dropped — they may belong to a newer content version and are harmless in the dictionary.
   - `targetMaturityLevel`, `osScopeFilter` and `microsoft365LicenseMode` values that don't map to a valid case are treated as absent (default), not as errors.

**Gate:** GATE-BUILD.

---

## Step 7 — Export and import UI

**Files:** `AboutView.swift`, `ProgressStore.swift`, `BackupFile.swift`

1. **ProgressStore support:**
   - `func exportBackup() throws -> BackupFile` — snapshots `statuses` plus the registered settings (Step 8 registry).
   - `func importBackup(_ backup: BackupFile)` — replaces `statuses` wholesale, writes each present setting to its `UserDefaults` key, then `save()`. Absent settings reset to defaults (remove the key) — import means "make this device look like the backup", not "overlay".
2. **AboutView — new section** between "Tools & Feedback" and "Preferences", header `"Backup & Restore"`, footer: `"Backups are plain JSON containing your step statuses, N/A reasons and app settings. They never leave your device unless you share them. Importing replaces all current data."`
   - **Export row:** `square.and.arrow.up` icon, "Export Backup". On tap: encode `exportBackup()`, write to `FileManager.default.temporaryDirectory` as `Essential8-Backup-<yyyy-MM-dd>.json`, present a `ShareLink`/`UIActivityViewController` for that file URL (AirDrop, Save to Files, etc.). Surface encoding/write failures in an alert — don't fail silently.
   - **Import row:** `square.and.arrow.down` icon, "Import Backup". On tap: `.fileImporter` limited to `UTType.json`. On selection: read (with `startAccessingSecurityScopedResource` if needed), validate per Step 6. On success show a confirmation alert — `"Replace all app data?"` with message `"This will replace all step statuses and settings with the backup from <exportedAt, dd/MM/yyyy> (app version <appVersion>). This cannot be undone."` — destructive "Replace" button calls `importBackup`, plus Cancel. On validation failure show an error alert naming the reason (not a raw decoding error dump).
3. Clean up the temporary export file after the share sheet dismisses (best-effort).
4. No iCloud, no background export, no automatic backup — explicitly out of scope.

**Gate:** GATE-BUILD. Manual check in the simulator: export → Save to Files produces valid pretty-printed JSON; re-import after changing some statuses restores the exported state exactly; importing a truncated/garbage JSON file shows the error alert and changes nothing.

---

## Step 8 — Persisted-state registry (the future-proofing rule)

**Files:** `ProgressStore.swift` (or `BackupFile.swift` — keep it next to whichever reads it most), `README.md`

1. Declare one registry of every persisted settings key:
   ```swift
   /// Every UserDefaults settings key the app persists.
   ///
   /// ── RULE FOR ALL FUTURE VERSIONS ─────────────────────────────────────
   /// Any new feature that persists data MUST add its key here AND extend
   /// BackupSettings + exportBackup()/importBackup(). The
   /// testBackupCoversAllPersistedKeys unit test fails if the registry and
   /// BackupSettings drift apart. Step progress (e8kb.stepProgressDict) is
   /// handled separately as the stepProgress payload.
   /// ─────────────────────────────────────────────────────────────────────
   enum PersistedSettingsKey: String, CaseIterable {
       case microsoft365LicenseMode
       case targetMaturityLevel
       case showSplashOnStartup
       case referenceOnlyMode
       case osScopeFilter
   }
   ```
2. Refactor `resetAll()` to remove the step-progress keys (`key`, `legacyKey`) plus `PersistedSettingsKey.allCases` — deleting the five hardcoded `removeObject` lines. Behaviour must be identical to today plus the new `osScopeFilter` key.
3. `exportBackup()`/`importBackup()` read/write settings via these key raw values — no string literals.
4. **README.md:** add a short "Backup format & persistence rule" subsection under the project-structure/development notes stating: the backup JSON schema lives in `BackupFile.swift`; every future persisted key must be added to `PersistedSettingsKey`, `BackupSettings` and both transfer functions; the coverage unit test enforces it; breaking format changes bump `schemaVersion`.

**Gate:** GATE-BUILD.

---

## Step 9 — Tests

**Files:** `Essential 8 Knowledge BaseTests/Essential_8_Knowledge_BaseTests.swift`, `Essential 8 Knowledge BaseUITests/Essential_8_Knowledge_BaseUITests.swift`

Unit tests (extend the existing file/style):

1. `ImplementationStep.matches(scope:)` truth table — both/workstation/server step × both/workstation/server filter (9 cases).
2. `steps(upTo:scope:)` — for Regular Backups, the workstation-scoped ML-target step count is strictly less than the unfiltered count (guards against the content tagging being silently dropped), and `scope: .both` equals the unfiltered list for every control.
3. Scope-filtered compliance maths — with a server-only step left not-implemented and all workstation/both steps implemented, `compliancePercentage` over the workstation-scoped list is 100 and over the unfiltered list is below 100.
4. Backup round-trip — populate a store with mixed statuses (including an N/A with reason) and non-default settings; `exportBackup()` → encode → decode → `importBackup()` into a clean store reproduces identical statuses and settings.
5. Backup rejection — decoding rejects `schemaVersion: 2` and malformed JSON; a `BackupSettings` with all fields absent imports without error and resets settings to defaults.
6. `testBackupCoversAllPersistedKeys` — every `PersistedSettingsKey` case has a corresponding `BackupSettings` coding key (compare the sorted raw-value list against `BackupSettings` `CodingKeys`). This is the drift alarm from Step 8.
7. Tag hygiene sweep — every step's `osScope` is a valid case (trivially true via the type system, so instead assert: at least one step in `EssentialControlsData.all` is tagged `server` and at least one `workstation`, guarding the content work).

UI tests (extend the existing file/style):

8. About page shows the OS scope segmented control defaulting to Both, and the version string matching `Version \d+\.\d+ \(\d+\)`.
9. Selecting Workstation scope persists across relaunch and reduces a known step count (e.g. Regular Backups detail page total).

**Gate:** GATE-TEST — all new and existing tests pass.

---

## Step 10 — Splash, version bump, changelog, README, roadmap

**Files:** `SplashView.swift`, `Essential 8 Knowledge Base.xcodeproj/project.pbxproj`, `CHANGELOG.md`, `README.md`, `ROADMAP.md`

1. **SplashView:** heading becomes `"What's New in Version 1.6"`. **Remove all existing feature rows** — from this release onward the splash lists only the features added in the current build. Rows, in order:
   - `desktopcomputer` icon (or closest available) — **"OS Scope Filtering"** — "Filter every step to Workstation, Server or Both — compliance recalculates for the environment you manage."
   - `arrow.up.arrow.down.circle` icon (or closest) — **"Backup & Transfer"** — "Export all progress and settings as JSON and restore it on another device — fully offline."
   - `info.circle` icon (or closest) — **"App Version in About"** — "The About page now shows the installed app version and build."
2. **Version:** in `project.pbxproj`, set every `MARKETING_VERSION = 1.5` → `1.6` and every `CURRENT_PROJECT_VERSION = 6` → `7` (all build configurations, all targets — currently five occurrences of each).
3. **CHANGELOG.md:** add `## 1.6 — <today's date, YYYY-MM-DD>` at the top in the existing bullet style: OS scope tags + filter + recalculated compliance; scope badges; backup export/import + replace-on-import confirmation; persisted-state registry + coverage test; About-page version display; splash update; version/build bump; new tests.
4. **README.md:** update where behaviour changed (About-page scope picker, Backup & Restore section, version row, scope badges on maturity pages) plus the Step 8 persistence-rule subsection. Do not restructure the README.
5. **ROADMAP.md:** move candidates 6 and 7 out of the candidate list into the shipped/in-flight sections per the existing document conventions.

**Gate:** GATE-BUILD + GATE-TEST, then manual check: fresh launch shows the v1.6 splash; About shows "Version 1.6 (7)".

---

## Out of scope for this build

- Multiple environment profiles (roadmap candidate 3) — the backup format is its enabler, but no profile UI, no multi-store.
- Compliance report export (PDF/CSV), audit trail, verification commands, ATT&CK mapping, iPad layout, Spotlight (other roadmap candidates).
- iCloud/automatic backup, backup encryption, or any network capability.
- OS scope tagging for the Windows Audit Policy or M365 pages.
- Refactors or style changes beyond the files listed. Every changed line must trace to a step above.
