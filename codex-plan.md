# codex-plan.md — v1.4: Target Maturity Level + ISM Control Mapping

**Authored by:** Claude (05/07/2026)
**Implemented by:** Codex, in step order. Run the verification gate after each step before moving on.
**Scope:** exactly what is written here. If a step has a technical or security problem, stop and surface it — don't build the flaw.

---

## Overview

Two features for version 1.4, plus splash screen and version housekeeping:

- **Feature A — Target Maturity Level.** The user picks an organisation-wide target (ML1/ML2/ML3). All compliance metrics (home dashboard ring, stacked bar chart, control detail progress, completion badges) measure against the target instead of implicitly against ML3. Levels above the target remain fully browsable as reference content.
- **Feature B — ISM control mapping.** Each implementation step is tagged with the corresponding ISM control identifier(s) (e.g. `ISM-1490`) from the ASD *Essential Eight Maturity Model and ISM Mapping* publication (November 2023 release). Tags are displayed on maturity level pages and are searchable in Global Search.

Design decisions (locked — do not revisit):

1. Target is **organisation-wide, not per-control**. ASD guidance is to achieve one maturity level across all eight mitigations before progressing, so a single target matches the model.
2. Maturity levels are **cumulative**: a target of ML2 means the in-scope step set is ML1 + ML2 steps. ML3 target = all steps (current behaviour).
3. Default target is **ML3**, so existing users see no change in their numbers until they choose a lower target. No data migration required.
4. ISM identifiers must be sourced from the ASD Essential Eight Maturity Model / ISM mapping (November 2023). **Never guess an identifier.** A step with no confident mapping gets an empty array — an absent tag is correct; a wrong tag is a defect.
5. All data stays local (`UserDefaults` / `@AppStorage`), consistent with the app's privacy posture. No new entitlements, no network.

---

## Verification gates

- **GATE-BUILD** (every step):
  ```
  xcodebuild -scheme "Essential 8 Knowledge Base" -destination "generic/platform=iOS Simulator" -configuration Debug clean build CODE_SIGNING_ALLOWED=NO
  ```
- **GATE-TEST** (steps 8–9): same scheme against a named simulator, e.g.
  ```
  xcodebuild -scheme "Essential 8 Knowledge Base" -destination "platform=iOS Simulator,name=iPhone 16" test CODE_SIGNING_ALLOWED=NO
  ```
  (Substitute any installed iPhone simulator if that name is unavailable.)

---

## Step 1 — Data model changes

**Files:** `EssentialControl.swift`, `EssentialControlsData.swift`

1. Add to `ImplementationStep`:
   ```swift
   /// ISM control identifiers this step maps to (e.g. "ISM-1490"), from the
   /// ASD Essential Eight Maturity Model / ISM mapping (November 2023). Empty
   /// when no confident mapping exists.
   let ismControls: [String]
   ```
2. Give the private `step(...)` helper in `EssentialControlsData.swift` a new parameter `ismControls: [String] = []` and pass it through, so the whole data file compiles unchanged before Step 5 populates content.
3. Add helpers to `EssentialControl.swift`:
   ```swift
   extension MaturityLevel {
       /// Levels included when this level is the target (cumulative: ML1...self).
       var cumulativeLevels: [MaturityLevel] {
           MaturityLevel.allCases.filter { $0.rawValue <= rawValue }
       }
   }

   extension EssentialControl {
       /// All steps in scope when targeting `level` (cumulative).
       func steps(upTo level: MaturityLevel) -> [ImplementationStep] {
           level.cumulativeLevels.flatMap { content(for: $0).steps }
       }
   }
   ```

**Gate:** GATE-BUILD.

---

## Step 2 — Target maturity level persistence

**Files:** `ProgressStore.swift`

1. Storage key: `"targetMaturityLevel"`, an `Int` raw value of `MaturityLevel`, read via `@AppStorage` in views (same pattern as `microsoft365LicenseMode`). Default `3` (ML3). Do **not** store it inside `ProgressStore.statuses`.
2. Change `isControlComplete` to be target-aware:
   ```swift
   func isControlComplete(_ control: EssentialControl, upTo target: MaturityLevel) -> Bool
   ```
   Same logic as today but over `control.steps(upTo: target)`. Update the existing call site (HomeView) in Step 3. Remove the old signature — don't keep both.
3. Add `"targetMaturityLevel"` to the `UserDefaults` keys removed in `resetAll()` so Reset App Data restores the ML3 default.

**Gate:** GATE-BUILD.

---

## Step 3 — Home dashboard: target picker + target-scoped metrics

**Files:** `HomeView.swift`

1. Add `@AppStorage("targetMaturityLevel") private var targetMaturityRawValue = MaturityLevel.ml3.rawValue` and a computed `targetLevel: MaturityLevel` (fall back to `.ml3` on invalid raw value).
2. In the **Maturity Dashboard** section, above the compliance ring row, add a segmented picker:
   ```swift
   Picker("Target maturity level", selection: $targetMaturityRawValue) {
       ForEach(MaturityLevel.allCases) { Text($0.shortName).tag($0.rawValue) }
   }
   .pickerStyle(.segmented)
   ```
   Label it with a caption above ("Target Maturity Level") styled like the existing "Maturity Breakdown by Control" caption. Give the picker an accessibility label.
3. Re-scope the dashboard computations to the target: `overallTotalSteps`, `overallImplementedSteps`, `overallNASteps`, `overallCompliancePercentage`, and `chartData` all iterate `control.steps(upTo: targetLevel)` instead of `MaturityLevel.allCases`.
4. The green per-control completion checkmark uses `progressStore.isControlComplete(control, upTo: targetLevel)`.
5. Reference Only Mode note: when the dashboard is hidden the picker is hidden too — that is acceptable and intended; the stored target still applies elsewhere. Do not add a second picker in AboutView.

**Gate:** GATE-BUILD. Manual check: with a fresh install the picker shows ML3 selected and all numbers match v1.3 behaviour; switching to ML1 shrinks step totals and the ring animates to the recalculated percentage.

---

## Step 4 — Control detail: target-scoped progress + beyond-target badges

**Files:** `ControlDetailView.swift`

1. Read the same `@AppStorage("targetMaturityLevel")` value (same fallback rule).
2. `allSteps` becomes `control.steps(upTo: targetLevel)`; the Implementation Progress section (bar, counts, percentage) therefore measures against the target. Rename nothing else.
3. Update the section header/copy so the scope is explicit: header stays "Implementation Progress", and add a `footer` on that section: `"Measured against your target of ML\(targetLevel.rawValue). Change the target on the home dashboard."`
4. In `maturityButton(level:content:)`, when `level.rawValue > targetLevel.rawValue`, replace the `doneCount/totalCount` progress text with a small grey capsule reading `"Beyond target"` (caption2, secondary style — mirror the ML capsule styling in `GlobalSearchView`). The button stays fully navigable; content above target is reference material, not locked.

**Gate:** GATE-BUILD. Manual check: target ML1 → mitigation 1 shows ML2/ML3 rows with "Beyond target" capsules and the progress bar counts only ML1 steps.

---

## Step 5 — Populate ISM mappings in content

> **Review redirect (Claude, 05/07/2026):** Step 5 was reported blocked because "the PDF did not contain ISM identifiers" — the wrong publication was checked. The maturity model document does not carry the identifiers; ASD publishes them in a **separate** document: *Essential Eight maturity model and ISM mapping* (first published January 2019, last updated October 2024), 22 pages of requirement → ISM-#### tables. A verified local copy is saved at `reference/e8-ism-mapping-oct2024.pdf` in this repo (source: <https://www.cyber.gov.au/business-government/asds-cyber-security-frameworks/essential-eight/essential-eight-maturity-model-and-ism-mapping> — note cyber.gov.au intermittently times out; use the local copy). The October 2024 edition maps the same requirements as the November 2023 model release the app covers. Use it to complete this step as originally specified, and also: (a) fix the header comment in `EssentialControlsData.swift` to cite "ASD Essential Eight maturity model and ISM mapping (October 2024)", (b) restore the dropped test guard that at least one step has a non-empty mapping (spec Step 8, test 5), and (c) firm up the hedged splash/README wording ("once mapped" / "remain empty") once mappings are populated.

**Files:** `EssentialControlsData.swift` only (do not touch `WindowsAuditPolicyData.swift` or `Microsoft365AdditionalControlsData.swift`).

1. For every `step(...)` across all eight controls and all three levels, add `ismControls: [...]` with the ISM identifiers that the ASD *Essential Eight Maturity Model and ISM Mapping* (November 2023 release) assigns to the requirement the step implements.
2. Rules:
   - Format is exactly `ISM-` followed by four digits, e.g. `ISM-1490`.
   - One step may map to multiple ISM controls; list them all.
   - Steps that are app-added implementation plumbing with no direct ISM requirement (e.g. "Enable the Application Identity service" is a prerequisite of the AppLocker requirement) take the ISM identifier(s) of the requirement they serve — the AppLocker execution-prevention controls in that example.
   - **If you cannot confidently source an identifier from the mapping document, leave the array empty.** Do not infer numbers from memory of other documents.
3. At the top of the file, extend the existing header comment with one line citing the mapping source and release used.
4. Produce a short mapping summary in your handoff notes (control → step → ISM IDs, plus a list of steps left empty and why) so Claude can review content accuracy against the source document.

**Gate:** GATE-BUILD, plus a self-check: every populated identifier matches `^ISM-\d{4}$` (this becomes a unit test in Step 8).

---

## Step 6 — Display ISM tags on maturity level pages

**Files:** `MaturityLevelView.swift`

1. In each step section, below the step title/status row (after the N/A reason box when present, before `step.description`), render the tags when `!step.ismControls.isEmpty`: a horizontal wrap of small capsules, each showing the identifier in `.caption2` monospaced, `Color.blue.opacity(0.1)` capsule background with `.blue` text (match the ML capsule styling used in `GlobalSearchView`). Enable `.textSelection(.enabled)` so an assessor can copy the ID.
2. Steps with an empty array render exactly as today — no placeholder, no empty row.
3. Combine the capsules into one accessibility element labelled e.g. "ISM controls: ISM-1490, ISM-1656".

**Gate:** GATE-BUILD. Manual check: mitigation 1 ML1 shows capsules; a step with no mapping shows nothing extra.

---

## Step 7 — ISM identifiers in Global Search

**Files:** `GlobalSearchView.swift`

1. Extend matching: a step matches when any element of `step.ismControls` `localizedCaseInsensitiveContains(query)`. This makes `1490`, `ism-1490` and `ISM-1490` all hit.
2. Add matched ISM identifiers to the result row: reuse the existing "Matching Detail:" yellow-highlight block (append matched ISM IDs to `matchedDetails`, or render an equivalent highlighted line — pick whichever keeps `SearchResult` simplest).
3. Update the two empty-state hint texts to mention ISM identifiers, e.g. add `'ISM-1490'` to the example terms in the no-results view and "ISM control numbers" to the intro copy.

**Gate:** GATE-BUILD. Manual check: searching `1490` returns the tagged step(s) and navigates to the correct maturity level page.

---

## Step 8 — Tests

**Files:** `Essential 8 Knowledge BaseTests/Essential_8_Knowledge_BaseTests.swift`, `Essential 8 Knowledge BaseUITests/Essential_8_Knowledge_BaseUITests.swift`

Unit tests (extend the existing file/style):

1. `MaturityLevel.cumulativeLevels` — ML1 → [ML1]; ML3 → [ML1, ML2, ML3].
2. `EssentialControl.steps(upTo:)` — for a known control, ML1 count equals `ml1.steps.count`; ML3 count equals the sum of all three levels.
3. Target-scoped compliance maths — mark all ML1 steps of one control implemented; `compliancePercentage` over `steps(upTo: .ml1)` is 100 and over `steps(upTo: .ml3)` is below 100. Use the same store isolation pattern the existing tests use.
4. `isControlComplete(_:upTo:)` — true at ML1 target with only ML1 steps done; false at ML3 target.
5. ISM format sweep — every `ismControls` element across `EssentialControlsData.all` matches `^ISM-\d{4}$`; and at least one step in the data set has a non-empty mapping (guards against silent loss of the content work).
6. ISM search matching — replicate the `GlobalSearchView` matching predicate for a known tagged step: full ID, digits-only, and lowercase queries all match.

UI tests (extend the existing file/style):

7. Dashboard target picker exists, defaults to ML3, and selection persists across app relaunch.
8. With target ML1 selected, a control detail page shows the "Beyond target" text for ML2/ML3 rows.

**Gate:** GATE-TEST — all new and existing tests pass.

---

## Step 9 — Splash screen, version bump, changelog, README

**Files:** `SplashView.swift`, `Essential 8 Knowledge Base.xcodeproj/project.pbxproj`, `CHANGELOG.md`, `README.md`

1. **SplashView:** heading becomes `"What's New in Version 1.4"`. Feature rows become, in order:
   - `target` icon, indigo — **"Target Maturity Level"** — "Set your organisation's target (ML1–ML3) and measure dashboard compliance against it instead of everything."
   - `number` icon, teal — **"ISM Control Mapping"** — "Every implementation step is tagged with its ISM control identifiers — visible on each step and searchable in Global Search."
   - Keep the existing **Compliance Dashboard**, **Global Search**, and **Reference Only Mode** rows below the two new ones; drop the "Multi-State Statuses" and "Feedback & Settings Tools" rows to keep the list at five.
   (If either SF Symbol is unavailable at the deployment target, choose the closest available symbol and note the substitution.)
2. **Version:** in `project.pbxproj`, set every `MARKETING_VERSION = 1.3` → `1.4` and every `CURRENT_PROJECT_VERSION = 4` → `5` (all build configurations, all targets — currently five occurrences of each).
3. **CHANGELOG.md:** add a `## 1.4 — <today's date, YYYY-MM-DD>` entry at the top in the existing bullet style covering: target maturity level picker + target-scoped compliance metrics + beyond-target badges; ISM control mapping display + search; splash update; version/build bump; new tests.
4. **README.md:** update the Navigation and Project structure sections where behaviour changed (dashboard target picker, ISM tags on maturity level pages, ISM search, splash now describing v1.4). Do not restructure the README.

**Gate:** GATE-BUILD + GATE-TEST, then manual check: fresh launch shows the v1.4 splash; About sheet and App Store metadata paths unaffected.

---

## Out of scope for this build

- Per-control targets, target history, or notifications.
- ISM mappings for the Windows Audit Policy page or M365 additions.
- Any export/reporting features, profile support, or verification commands (candidate v1.5 items).
- Refactors or style changes beyond the files listed. Every changed line must trace to a step above.
