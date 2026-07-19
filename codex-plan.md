# codex-plan.md — v1.7: Multiple Environment Profiles + Per-Step Audit Trail

**Authored by:** Claude (19/07/2026)
**Implemented by:** Codex, in step order. Run the verification gate after each step before moving on.
**Scope:** exactly what is written here. If a step has a technical or security problem, stop and surface it — don't build the flaw.
**Prerequisite:** branch off `main` **after the v1.6 work (OS scope tags + backup/transfer) is merged**. This spec assumes v1.6 is present: `OSScope` on steps, `BackupFile` schema **1**, the `PersistedSettingsKey` registry, `AppInformation.versionDisplay`, and the About-page Preferences/Backup sections. Do not build on a tree that lacks v1.6.

---

## Overview

Two features for version 1.7, plus splash regeneration and the version bump:

- **Feature A — Multiple environment profiles (candidate 3).** A named-profile switcher layered over `ProgressStore` so one person can track several environments/orgs/clients separately (e.g. production vs DR, or multiple MSP clients). Gated behind a **Multiple Profiles** toggle in About. Each profile owns its own *assessment context* — step progress, audit trail, target maturity level, OS scope and M365 licence mode. There is always at least one profile.
- **Feature B — Per-step audit trail (candidate 5, "deep audit mode").** Gated behind a **Deep Audit Mode** toggle in About. When on, every step status change is date-stamped and recorded, with an **optional** free-text note captured at the moment of change. A read-only per-step history surfaces the entries. Image/screenshot attachment is **explicitly out of scope** — parked for a future version.
- **Splash + version:** regenerate the "What's New" splash for v1.7 and bump the marketing/build version.

Both features are local-only (`UserDefaults` / `@AppStorage`), consistent with the app's privacy posture. No network, no new entitlements.

### Locked decisions (agreed 19/07/2026 — do not revisit)

1. **Per-profile assessment context.** Each profile independently owns: step progress, audit trail, **target maturity level, OS scope filter, M365 licence mode**. Everything else — `showSplashOnStartup`, `referenceOnlyMode`, and the two new feature toggles — is **global** (device-level, shared across profiles). Switching the active profile re-points the whole app (dashboard, control detail, maturity pages, search) at that profile's context.
2. **A profile always exists.** On first launch of v1.7, existing single-store data migrates into a profile named **"Default"** (see Step 3). The Multiple Profiles toggle only *reveals the switcher and management UI* — it never deletes profiles. With the toggle off, the active profile is still whatever it was; the app just hides multi-profile UI.
3. **Audit comment is optional, captured on change.** When Deep Audit Mode is on and the user changes a step's status to *Implemented* or *Not Implemented*, an optional note prompt appears; Save commits the change (with or without a note), Cancel aborts the change entirely. For *Not Applicable*, the existing N/A reason alert doubles as the note — no second prompt. Every recorded change is timestamped even when the note is blank. Deep Audit off = current behaviour, no prompts, no entries.
4. **History is read-only.** Entries are never edited or added after the fact (that was the rejected "edit later" model). Deleting a profile deletes its audit trail with it.
5. **Backup is profile-aware and export offers a choice.** When more than one profile exists, Export offers **This profile** or **All profiles**. A single-profile export is a portable per-client assessment; an all-profiles export is a full-device transfer including global settings. See Steps 8–9 for exact import semantics.
6. **Audit trail travels in backups, capped.** Audit entries are included in exports, capped at **200 entries per step** (oldest dropped) to bound growth. The import size guard rises to **5 MB** for the richer schema; an all-profiles export that still exceeds the cap errors with advice to export profiles individually.
7. **Schema bump to 2, with v1 still importable.** `BackupFile.currentSchemaVersion` becomes **2**. The decoder accepts schema **1** (v1.6 backups) and maps them into a single imported profile, so no existing backup is stranded.
8. **Single source of truth preserved.** The persisted-state registry + coverage test from v1.6 is kept and split into *global keys* vs *per-profile fields*; the drift-alarm test is updated, not removed. **Standing rule stays: any new persisted datum must be added to the relevant registry and the backup format, or the coverage test fails.**

---

## Verification gates

- **GATE-BUILD** (every step):
  ```
  xcodebuild -scheme "Essential 8 Knowledge Base" -destination "generic/platform=iOS Simulator" -configuration Debug clean build CODE_SIGNING_ALLOWED=NO
  ```
- **GATE-TEST** (test steps): same scheme against a named simulator, e.g.
  ```
  xcodebuild -scheme "Essential 8 Knowledge Base" -destination "platform=iOS Simulator,name=iPhone 16" test CODE_SIGNING_ALLOWED=NO
  ```
  (Substitute any installed iPhone simulator if that name is unavailable.)

---

## Step 1 — Data model: audit entry + profile

**Files:** new `Profile.swift` (app target); `ProgressStore.swift` (types can live here if you prefer — keep `AuditEntry`/`Profile` next to `StepStatus`). Whichever file, keep them in the app target so tests can `@testable import` them.

1. Audit entry:
   ```swift
   /// One recorded status change for a step. Written only while Deep Audit
   /// Mode is on; never edited after creation (history is read-only).
   struct AuditEntry: Codable, Equatable, Hashable, Identifiable {
       let id: UUID
       let timestamp: Date
       let previousState: StepState
       let newState: StepState
       let note: String?          // optional free-text; N/A reason is copied here
   }
   ```
2. Profile:
   ```swift
   /// A named assessment context. Each profile is an independent environment
   /// (org / client / prod / DR). See locked decision 1 for what is per-profile.
   struct Profile: Codable, Equatable, Identifiable {
       let id: UUID
       var name: String
       let createdAt: Date
       var stepProgress: [String: StepStatus]
       var auditTrail: [String: [AuditEntry]]   // stepID -> chronological (oldest first)
       // assessment context (stored as raw values; invalid values fall back to defaults on read)
       var targetMaturityLevelRaw: Int
       var osScopeFilterRaw: String
       var microsoft365LicenseModeRaw: String

       static func newDefault(name: String = "Default") -> Profile {
           Profile(
               id: UUID(),
               name: name,
               createdAt: Date(),
               stepProgress: [:],
               auditTrail: [:],
               targetMaturityLevelRaw: MaturityLevel.ml3.rawValue,
               osScopeFilterRaw: OSScope.both.rawValue,
               microsoft365LicenseModeRaw: Microsoft365LicenseMode.none.rawValue
           )
       }
   }
   ```
3. Audit cap constant, kept next to `Profile`:
   ```swift
   /// Max audit entries retained per step; oldest are dropped on overflow.
   let auditEntriesPerStepCap = 200
   ```

**Gate:** GATE-BUILD.

---

## Step 2 — Global settings + per-profile registries

**Files:** `ProgressStore.swift`

Replace the single `PersistedSettingsKey` registry with two clearly-separated registries plus the structural keys. The v1.6 comment block and its "rule for all future versions" intent is preserved, updated for the split.

1. Global keys (device-level, shared across profiles):
   ```swift
   /// Device-level UserDefaults keys shared across all profiles.
   /// RULE: any new *global* persisted setting MUST be added here AND to
   /// GlobalSettingsBackup, or backupCoversAllGlobalKeys() fails.
   enum GlobalSettingsKey: String, CaseIterable {
       case showSplashOnStartup
       case referenceOnlyMode
       case deepAuditEnabled
       case multiProfileEnabled
   }
   ```
2. Structural storage keys (not part of the settings registry, handled directly):
   - `e8kb.profiles` — JSON-encoded `[Profile]`.
   - `e8kb.activeProfileID` — UUID string of the active profile.
3. Per-profile fields are the three `...Raw` properties on `Profile`. The former standalone keys `targetMaturityLevel`, `osScopeFilter`, `microsoft365LicenseMode` are **removed from the global registry** — they now live inside each `Profile`. Their string identity (`"targetMaturityLevel"` etc.) is retained only as the migration source in Step 3.

**Gate:** GATE-BUILD (will fail to compile until Steps 3–5 land the store rewrite; land Steps 2–5 as one working unit and gate at the end of Step 5 if needed — note this in the commit).

---

## Step 3 — ProgressStore rewrite: profiles + active context + migration

**Files:** `ProgressStore.swift`

The store becomes the single source of truth for *all* profile state. Keep the existing public method names so view call sites change as little as possible.

1. State:
   ```swift
   @Published private(set) var profiles: [Profile]
   @Published private(set) var activeProfileID: UUID
   ```
   Add `private func activeIndex() -> Int` (guaranteed valid — see invariant below) and computed `var activeProfile: Profile { profiles[activeIndex()] }`.
   **Invariant:** `profiles` is never empty and `activeProfileID` always matches an existing profile. Enforce on every mutation.

2. `init(defaults:)`:
   - If `e8kb.profiles` decodes to a non-empty `[Profile]`, load it; read `activeProfileID`, falling back to `profiles[0].id` if missing/stale.
   - **Else migrate (first v1.7 launch):** build one `Profile.newDefault(name: "Default")` and populate it from the v1.6 world:
     - `stepProgress` ← decode `e8kb.stepProgressDict` (and the legacy `e8kb.stepProgress` array migration already in place — reuse that logic).
     - `targetMaturityLevelRaw` ← `defaults` `"targetMaturityLevel"` if present.
     - `osScopeFilterRaw` ← `"osScopeFilter"` if present.
     - `microsoft365LicenseModeRaw` ← `"microsoft365LicenseMode"` if present.
     - `auditTrail` empty.
     Save the new `profiles`/`activeProfileID`. **Leave the global keys (`showSplashOnStartup`, `referenceOnlyMode`) untouched** — they stay global. Do not delete the old per-setting keys yet in the same session is fine, but they are no longer read after migration; leave them (harmless) rather than risk a half-migration.

3. Step-progress API — unchanged names, now operating on the active profile:
   - `var statuses: [String: StepStatus] { activeProfile.stepProgress }` (computed, read-only; keeps test/consumer compatibility).
   - `status(for:)`, `isCompleted`, `isNotApplicable`, `completedCount(for:)`, `notApplicableCount(for:)`, `compliancePercentage(for:)`, `isControlComplete(_:upTo:scope:)` — identical logic, reading `activeProfile.stepProgress`.
   - Keep `setStatus(_:reason:for:)` as a thin wrapper calling the new note-aware method with `note: nil` (Step 6).

4. Per-profile context accessors (get/set route to the active profile and persist):
   ```swift
   var targetMaturityLevel: MaturityLevel { get / set }   // reads ...Raw, falls back .ml3
   var osScope: OSScope { get / set }                      // falls back .both
   var licenseMode: Microsoft365LicenseMode { get / set }  // falls back .none
   ```
   Setters mutate `profiles[activeIndex()]`, then `save()`.

5. `private func save()` encodes `profiles` to `e8kb.profiles`, writes `activeProfileID`, and sends `objectWillChange`. All mutators call it.

6. `resetAll()`:
   - Replace `profiles` with `[Profile.newDefault()]`, set `activeProfileID` to it.
   - Remove `e8kb.profiles`, `e8kb.activeProfileID`, `e8kb.stepProgressDict`, `e8kb.stepProgress`.
   - Remove every `GlobalSettingsKey` (this turns Deep Audit and Multiple Profiles off).
   - Also remove the now-legacy `"targetMaturityLevel"`, `"osScopeFilter"`, `"microsoft365LicenseMode"` keys so a reset is total.
   - `save()`.

**Gate:** GATE-BUILD (jointly with Steps 4–5).

---

## Step 4 — Profile management API

**Files:** `ProgressStore.swift`

Add, each preserving the non-empty/active invariant and calling `save()`:

```swift
func switchProfile(to id: UUID)                 // no-op if id unknown
@discardableResult func createProfile(named name: String) -> UUID
                                                // trims name; empty -> "New Profile";
                                                // does NOT switch — caller decides
func renameProfile(_ id: UUID, to name: String) // trims; ignores empty
func deleteProfile(_ id: UUID)                  // refuses if it's the last profile;
                                                // if deleting the active one, switch to
                                                // another (first remaining) first
```

`createProfile` makes a fresh `Profile.newDefault(name:)` with a new `UUID`. Name collisions are allowed (UUID is the identity); the UI shows names, so leave de-duplication to the user.

**Gate:** GATE-BUILD (jointly with Steps 3–5).

---

## Step 5 — Route views through the active profile

**Files:** `HomeView.swift`, `ControlDetailView.swift`, `MaturityLevelView.swift`, `GlobalSearchView.swift`, `Microsoft365SettingsView.swift`, `AboutView.swift`

Replace the direct `@AppStorage` reads of the **three per-profile settings** with the store accessors. `showSplashOnStartup` and `referenceOnlyMode` **stay** `@AppStorage` (global) — do not touch those lines.

For each site currently using `@AppStorage("targetMaturityLevel")`, `@AppStorage("osScopeFilter")` or `@AppStorage("microsoft365LicenseMode")`:

1. Delete the `@AppStorage` property and any `private var xFilter/xLevel` computed wrapper.
2. Read the value from `progressStore` (`progressStore.targetMaturityLevel`, `.osScope`, `.licenseMode`).
3. Where a `Picker`/segmented control needs a `Binding`, build one against the store, e.g.:
   ```swift
   private var scopeBinding: Binding<String> {
       Binding(get: { progressStore.osScope.rawValue },
               set: { progressStore.osScope = OSScope(rawValue: $0) ?? .both })
   }
   ```
   Use the analogous pattern for target maturity (HomeView) and licence mode (Microsoft365SettingsView).

Because `ProgressStore` is an `@EnvironmentObject` and these are `@Published`-backed, switching profiles updates every view automatically. There are **9 per-profile `@AppStorage` properties across 6 views** to convert: targetMaturityLevel ×2 (HomeView, ControlDetailView), osScopeFilter ×5 (AboutView, HomeView, ControlDetailView, MaturityLevelView, GlobalSearchView), microsoft365LicenseMode ×2 (MaturityLevelView, Microsoft365SettingsView). The derived `scopeFilter`/`targetLevel`/`selectedLicenseMode` computed vars are *consumers* of those properties, not separate `@AppStorage` sites — update them to read the store, don't count them again.

**Gate:** GATE-BUILD. Manual check: with a single "Default" profile, behaviour is functionally identical to v1.6 (the persistence representation changes from standalone keys to profile JSON; observable behaviour must not) — same dashboard, same OS scope picker in About, same M365 mode in settings; changing any of them persists across relaunch.

---

## Step 6 — Audit recording in the store

**Files:** `ProgressStore.swift`

1. New note-aware setter (the 3-arg `setStatus` wraps this):
   ```swift
   func setStatus(_ state: StepState, reason: String?, note: String?, for stepID: String)
   ```
   Logic:
   - `let previous = status(for: stepID).state`.
   - Apply the state to `activeProfile.stepProgress` exactly as today (`.notImplemented` removes the key; otherwise store `StepStatus(state:reason:)`).
   - **Audit:** if `deepAuditEnabled` (read from `defaults`/`GlobalSettingsKey.deepAuditEnabled`, default false) **and `state != previous`**, append an `AuditEntry(id: UUID(), timestamp: Date(), previousState: previous, newState: state, note:` note-or-N/A-reason `)` to `activeProfile.auditTrail[stepID]`. For `.notApplicable`, use `note ?? reason` (the reason is the note). Trim `activeProfile.auditTrail[stepID]` to the last `auditEntriesPerStepCap` entries (drop oldest).
   - `save()`.
   - No audit entry when Deep Audit is off, or when the state is unchanged.
2. Read API for the UI: `func auditEntries(for stepID: String) -> [AuditEntry]` returning newest-first (`activeProfile.auditTrail[stepID]?.reversed()` as an array).
3. `deepAuditEnabled` / `multiProfileEnabled` remain plain `@AppStorage` in views (global toggles); the store reads `deepAuditEnabled` from `defaults` directly for the recording decision — do not add a second source of truth.

**Gate:** GATE-BUILD.

---

## Step 7 — Audit UI: optional note prompt + read-only history

**Files:** `MaturityLevelView.swift`, new `StepAuditHistoryView.swift`

1. **Read the global toggle:** `@AppStorage("deepAuditEnabled") private var deepAuditEnabled = false`.
2. **Status menu behaviour** (the existing `Menu` with Implemented / Not Applicable / Not Implemented):
   - *Implemented* and *Not Implemented*:
     - Deep Audit **off** → call `progressStore.setStatus(state, reason: nil, for: step.id)` (current behaviour).
     - Deep Audit **on** → stash a pending change (`pendingAuditStepID`, `pendingAuditState`), preset `auditNoteText = ""`, present a note alert (mirror the existing N/A alert): a `TextField("Add a note (optional)")`, **Save** → `setStatus(pendingState, reason: nil, note: trimmedNote, for: pendingID)`, **Cancel** (role `.cancel`) aborts — no state change, no entry.
   - *Not Applicable*: unchanged flow. The existing reason alert's Save calls `setStatus(.notApplicable, reason: trimmedReason, note: trimmedReason, for: stepID)` so the reason is recorded as the audit note when Deep Audit is on (when off, `note` is ignored by Step 6's guard). No second prompt.
3. **History surface:** inside each step's `VStack`, when `deepAuditEnabled` **and** `!progressStore.auditEntries(for: step.id).isEmpty`, add a `NavigationLink` row: `Label("History (\(count))", systemImage: "clock.arrow.circlepath")`, `.font(.footnote)`, secondary tint, → `StepAuditHistoryView(stepTitle: step.title, entries: progressStore.auditEntries(for: step.id))`. Do not show the row when Deep Audit is off or there are no entries.
4. **`StepAuditHistoryView`** — read-only `List`, newest-first. Each row: transition line `"\(previousState.rawValue) → \(newState.rawValue)"` (`.subheadline.weight(.semibold)`), timestamp `dd/MM/yyyy HH:mm` (en_AU, `.caption`, secondary), and the note in `.footnote` when present. Navigation title the step title (inline). Combine each row for accessibility (`"<date>, changed from <prev> to <new>, note: <note or 'no note'>"`). Empty state text isn't needed — the row only appears when entries exist.

**Gate:** GATE-BUILD. Manual check: with Deep Audit on, marking a step Implemented shows the note prompt; Save with a note then Cancel on a second change leaves one entry; History lists it newest-first; marking N/A records the reason as the note with no second prompt; with Deep Audit off, no prompt and no History row appear.

---

## Step 8 — Backup format v2 (profiles + audit + global settings)

**Files:** `BackupFile.swift`

1. Bump and widen the envelope; keep v1 decodable:
   ```swift
   struct BackupFile: Codable {
       static let currentSchemaVersion = 2
       static let maximumFileSize = 5_242_880   // 5 MB (was 1 MB); richer schema
       static let minimumSupportedSchema = 1

       let schemaVersion: Int
       let appVersion: String
       let exportedAt: Date
       let profiles: [Profile]              // one (This-profile export) or many (All)
       let globalSettings: GlobalSettingsBackup?  // present ONLY in All-profiles exports
   }

   struct GlobalSettingsBackup: Codable {
       let showSplashOnStartup: Bool?
       let referenceOnlyMode: Bool?
       let deepAuditEnabled: Bool?
       let multiProfileEnabled: Bool?

       enum CodingKeys: String, CodingKey, CaseIterable {
           case showSplashOnStartup, referenceOnlyMode, deepAuditEnabled, multiProfileEnabled
       }
   }
   ```
2. **Encoder** unchanged (`.iso8601`, `.prettyPrinted`, `.sortedKeys`). Before encoding, trim each profile's `auditTrail` per step to `auditEntriesPerStepCap` (belt-and-braces with Step 6).
3. **Decoder** (`decode(_:) throws -> BackupFile`), rejecting the whole file on any failure:
   - Enforce the 5 MB size cap first.
   - Read `schemaVersion`.
   - `schemaVersion == 2` → decode as above, then **reject the file** (`BackupError.invalidFile`) if `profiles` is empty or contains duplicate profile `id`s. A backup that violates the store's non-empty and unique-identity invariants must never be applied — catching it at decode keeps the invariants an import can't break.
   - `schemaVersion == 1` → decode the **v1.6 shape** (`stepProgress: [String: StepStatus]`, `settings: BackupSettings` with the five old fields) and map to a single `Profile` named `"Imported"`: `stepProgress` → progress; `settings.targetMaturityLevel/osScopeFilter/microsoft365LicenseMode` → the profile's context (invalid → defaults); empty audit trail. Set `globalSettings = nil` (do **not** import a v1 backup's device prefs). Return `profiles: [thatProfile]`.
   - `schemaVersion > 2` → `BackupError.unsupportedSchema` ("update the app"). `< 1` → `.invalidFile`.
   - Invalid enum raw values inside a profile's context are treated as absent/default, never errors (same rule as v1.6).
4. Keep the existing `BackupError` cases; the "file too large" message can stay generic or mention 5 MB — your call, but keep it accurate.

**Gate:** GATE-BUILD.

---

## Step 9 — Export/import UI (profile-aware)

**Files:** `AboutView.swift`, `ProgressStore.swift`

1. **ProgressStore support:**
   - `func exportActiveProfile() throws -> BackupFile` → `profiles: [activeProfile]`, `globalSettings: nil`.
   - `func exportAllProfiles() throws -> BackupFile` → `profiles: profiles`, `globalSettings:` a `GlobalSettingsBackup` snapshot of the four global keys.
   - `func importAsNewProfile(_ backup: BackupFile)` → append each profile in `backup.profiles` with a **fresh `UUID`** and, on exact name match with an existing profile, suffix `" (imported)"`; switch active to the first imported profile; if the result has more than one profile, set `multiProfileEnabled = true`. Does **not** touch other profiles or global settings.
   - `func importFullDevice(_ backup: BackupFile)` → replace `profiles` with `backup.profiles` (decode already guaranteed non-empty + unique ids per Step 8), set active to the first, and apply `backup.globalSettings`. **Global-settings restoration is exhaustive over `GlobalSettingsKey`:** for every key, if the backup carries a value write it; if the value is absent (`nil`), **remove the key** so the setting reverts to its *application default* (the literal `@AppStorage` default in code), not to whatever the device held before. "Make this device identical to the backup" means an absent setting is a real state, not a no-op. Do not rely on `UserDefaults.register(defaults:)` — removing the key is what makes absence observable.
   - The importer chooses the path by `backup.globalSettings != nil` (present ⇒ full-device restore; nil ⇒ import-as-new-profile). A v1 backup (globalSettings nil) therefore imports as a new profile — the safe default.
2. **AboutView — Backup & Restore section (existing):**
   - **Export:** if `progressStore.profiles.count > 1`, tapping Export presents a `confirmationDialog` with **"This profile only"**, **"All profiles"**, Cancel. Single profile → export the active one directly (no dialog). Write to `temporaryDirectory` as `Essential8-<sanitisedProfileName>-<yyyy-MM-dd>.json` for a single export, or `Essential8-AllProfiles-<yyyy-MM-dd>.json` for all. Present the existing `ShareLink` sheet. If encoded size exceeds `maximumFileSize`, show an alert advising to export profiles individually (only reachable on an oversized All export).
   - **Import:** `.fileImporter` (`.json`) unchanged. On decode:
     - `globalSettings != nil` → confirmation **"Replace everything?"**, message: *"This replaces all profiles and app settings with the backup from <dd/MM/yyyy> (<n> profile(s), app version <appVersion>). This cannot be undone."* → destructive **Replace** calls `importFullDevice`.
     - `globalSettings == nil` → confirmation **"Import profile?"**, message: *"This adds <n> profile(s) from the backup of <dd/MM/yyyy> (app version <appVersion>). Your existing profiles are unchanged."* → **Import** (non-destructive) calls `importAsNewProfile`.
     - Decode failure → existing error alert, naming the reason.
   - Update the section footer to reflect profiles + audit: *"Backups are plain JSON containing your profiles — step statuses, N/A reasons, audit history and per-profile settings. Export this profile to share one assessment, or all profiles to move everything to another device. They never leave your device unless you share them."*
3. Clean up the temp export file after the share sheet dismisses (existing `cleanUpExport`).
4. Out of scope: iCloud, automatic/background export, encryption, merge-on-import.

**Gate:** GATE-BUILD. Manual check: with two profiles, Export offers the choice; a single-profile file imports as a new profile without disturbing the current one; an all-profiles file (after confirmation) replaces everything including the toggles; a v1.6 backup imports as one "Imported" profile; garbage/oversized files error and change nothing.

---

## Step 10 — About: feature toggles + Profiles management UI

**Files:** `AboutView.swift`, new `ProfilesView.swift`

1. **Feature toggles.** In a new section headed **"Assessment Features"** (place it above the existing Preferences/OS-scope section):
   ```swift
   @AppStorage("multiProfileEnabled") private var multiProfileEnabled = false
   @AppStorage("deepAuditEnabled") private var deepAuditEnabled = false
   ```
   - `Toggle("Multiple Profiles", isOn: $multiProfileEnabled)`
   - `Toggle("Deep Audit Mode", isOn: $deepAuditEnabled)`
   - Footer: *"Multiple Profiles lets you track separate environments or organisations, each with its own progress, settings and audit history. Deep Audit Mode records a timestamped, optionally-annotated history for every status change in the active profile."*
2. **Profiles section** — shown only `if multiProfileEnabled`. A single `NavigationLink` to `ProfilesView`, with the active profile name as its detail text: `Label("Profiles", systemImage: "person.2")` and a secondary line `progressStore.activeProfile.name`. Footer: *"The active profile determines what every screen shows. Switching profiles changes the dashboard, steps and audit history."*
3. **`ProfilesView`** (`@EnvironmentObject var progressStore`):
   - `List` of `progressStore.profiles`: each row shows the name, `createdAt` (dd/MM/yyyy, `.caption` secondary), and a trailing `checkmark` when it is the active profile. Tapping a row calls `switchProfile(to:)` and dismisses (or stays — dismissing is cleaner).
   - Toolbar **+** → alert with a `TextField` to name and create (`createProfile(named:)`), then optionally switch to it (offer "Create" only; leave switching to a tap — or create-and-switch; pick create-and-switch for fewer taps and note it).
   - Swipe-to-delete → confirmation alert (`"Delete profile '<name>'? Its progress and audit history are permanently removed."`) → `deleteProfile`. The last remaining profile has no delete action (the API refuses anyway).
   - Rename: a `NavigationLink`/context action or an edit alert per row calling `renameProfile(_:to:)`. Keep it simple — an alert with a `TextField` prefilled with the current name is fine.
   - Navigation title "Profiles", inline.
4. When `multiProfileEnabled` is toggled off, the Profiles section simply disappears; the active profile is unchanged. Do not delete or reset anything on toggle-off.

**Gate:** GATE-BUILD. Manual check: enabling Multiple Profiles reveals Profiles; create "Client A"/"Client B", set different OS scope + progress in each, confirm switching swaps the whole app; delete is confirmed and blocked for the last profile; disabling the toggle hides the UI but keeps data.

---

## Step 11 — Tests

**Files:** `Essential 8 Knowledge BaseTests/Essential_8_Knowledge_BaseTests.swift`, `Essential 8 Knowledge BaseUITests/Essential_8_Knowledge_BaseUITests.swift`

Rework the v1.6 backup tests for the new model and add coverage. Use the existing `makeIsolatedStore()` helper (it already injects a private `UserDefaults`).

Unit tests:
1. **Migration:** seed an isolated `UserDefaults` with legacy `e8kb.stepProgressDict` + `targetMaturityLevel`/`osScopeFilter`/`microsoft365LicenseMode`, construct a `ProgressStore`, assert one profile named "Default" exists, active, carrying the migrated progress and context.
2. **Profile lifecycle:** create → rename → switch → delete; assert the non-empty invariant (deleting the last profile is refused) and that deleting the active profile reselects another.
3. **Per-profile isolation:** two profiles; set different `osScope`/progress in each; assert the store's active reads reflect the active profile only and don't bleed across.
4. **Audit recording:** Deep Audit on → `setStatus` transitions create entries with correct `previousState`/`newState`; unchanged-state calls create none; Deep Audit off creates none; N/A records the reason as the note; per-step cap trims to `auditEntriesPerStepCap` (push cap+5, assert count == cap and oldest dropped).
5. **Backup round-trip (all profiles):** two profiles with mixed statuses + audit + non-default context and non-default global toggles → `exportAllProfiles()` → encode → decode → `importFullDevice` into a clean store reproduces profiles, contexts, audit and global settings.
5b. **Full-device restore clears absent global settings:** seed a store's `UserDefaults` with non-default global keys, then `importFullDevice` a backup whose `globalSettings` has those fields `nil`; assert each `GlobalSettingsKey` is genuinely removed (`defaults.object(forKey:) == nil`) — not merely reading as its default. Guards the "absent means default" semantics against registered-defaults masking.
6. **Backup import-as-new (single profile):** `exportActiveProfile()` from a populated store → import into a store that already has a "Default" profile → profile count increases by one, existing profile untouched, `multiProfileEnabled` becomes true.
7. **v1 compatibility:** hand-build a schema-1 `BackupFile` JSON (old `stepProgress` + `settings` shape) and assert it decodes to one "Imported" profile with mapped context and `globalSettings == nil`.
8. **Rejection:** schema 3 and malformed JSON throw `BackupError`; an oversized (>5 MB) blob throws `.fileTooLarge`; a schema-2 file with an **empty `profiles` array** throws `.invalidFile`; a schema-2 file with **two profiles sharing a `id`** throws `.invalidFile` (both guard the store invariants at the decode boundary).
9. **Registry coverage (drift alarms):**
   - `backupCoversAllGlobalKeys` — `GlobalSettingsKey.allCases` raw values sorted == `GlobalSettingsBackup.CodingKeys.allCases` raw values sorted.
   - `profileCarriesAllContextFields` — round-trip a `Profile` through JSON and assert the three context raw fields + `auditTrail` + `stepProgress` survive (guards against a context field being added to the model but omitted from `Codable`).

UI tests:
10. About shows the two feature toggles; enabling Multiple Profiles reveals the Profiles row.
11. Creating a second profile and switching it persists across relaunch (e.g. a distinct OS scope per profile is retained).

**Gate:** GATE-TEST — all new and existing tests pass. Delete/replace the obsolete v1.6 `backupRoundTripRestoresProgressAndSettings`, `backupValidationRejects...`, and `backupCoversAllPersistedKeys` tests (superseded by 5/8/9); keep every non-backup v1.6 test intact.

---

## Step 12 — Splash, version bump, changelog, README, roadmap

**Files:** `SplashView.swift`, `Essential 8 Knowledge Base.xcodeproj/project.pbxproj`, `CHANGELOG.md`, `README.md`, `ROADMAP.md`

1. **SplashView:** heading → `"What's New in Version 1.7"`. **Replace all v1.6 feature rows** (splash lists only the current release). Rows, in order:
   - `person.2` icon (blue) — **"Multiple Profiles"** — "Track separate environments or organisations, each with its own progress, settings and audit history. Turn it on in About."
   - `clock.arrow.circlepath` icon (green) — **"Deep Audit Mode"** — "Record a timestamped history of every status change, with an optional note — the evidence auditors ask for. Turn it on in About."
   (Two features this release — two rows. Use the closest available SF Symbols if either is unavailable.)
2. **Version:** in `project.pbxproj`, set **all** `MARKETING_VERSION = 1.6` → `1.7` and **all** `CURRENT_PROJECT_VERSION = 7` → `8` (every build configuration and target — currently six occurrences of each).
3. **CHANGELOG.md:** add `## 1.7 — <today's date, YYYY-MM-DD>` at the top in the existing bullet style: multiple environment profiles (per-profile progress/audit/context, create/rename/switch/delete, About toggle); deep audit mode (timestamped per-step history, optional note on change, read-only history view, About toggle); profile-aware backup v2 (this-profile vs all-profiles export, import-as-new vs full-device restore, v1 backups still importable, 5 MB guard, audit capped at 200/step); splash + version bump; new/updated tests.
4. **README.md:** update the Backup format & persistence subsection for schema v2 and the split global/per-profile registries; note the two new toggles and the profiles/audit behaviour. Do not restructure the README.
5. **ROADMAP.md:** move candidates 3 (profiles) and 5 (audit trail) out of the candidate list into Shipped as **v1.7**, per the existing document conventions. In candidate 5's place, leave a one-line future note that **image/screenshot evidence attachment** remains a parked enhancement on top of the shipped audit trail. Renumber/keep remaining candidates consistent.

**Gate:** GATE-BUILD + GATE-TEST, then manual: fresh launch shows the v1.7 splash; About shows "Version 1.7 (8)".

---

## Out of scope for this build

- **Image/screenshot evidence attachment** on audit entries — parked for a future version (keep it on the roadmap).
- Editing or deleting individual audit entries; audit history is append-only and read-only.
- Compliance report export (PDF/CSV), verification commands, ATT&CK mapping, iPad split-view, Spotlight (other roadmap candidates).
- iCloud / automatic / background backup, backup encryption, cross-profile merge on import, or any network capability.
- Profile-scoping the global UI prefs (`showSplashOnStartup`, `referenceOnlyMode`) — they remain device-level by decision 1.
- Refactors or style changes beyond the files listed. Every changed line must trace to a step above.
```