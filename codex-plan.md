# codex-plan.md — v1.8: MITRE ATT&CK Technique Mapping + Coverage

**Authored by:** Claude (26/07/2026)
**Implemented by:** Codex, in step order. Run the verification gate after each step before moving on.
**Scope:** exactly what is written here. If a step has a technical or security problem, stop and surface it — don't build the flaw.
**Prerequisite:** branch off `main` **after v1.7 (multiple profiles + per-step audit trail) is merged**. This spec assumes v1.7 is present: `ProgressStore` with profiles and `auditEntries(for:)`, `BackupFile` schema **2**, the `PersistedSettingsKey` registry, `OSScope` on steps, `AppInformation.versionDisplay`.

**Source of truth for all mapping content:** `mitreattacke8.md` in the repo root, rebased to ATT&CK v19.1 and curated on 26/07/2026. **Transcribe it exactly.** Do not add, drop or "improve" a technique mapping. If you believe a row is wrong, stop and raise it — do not silently correct it.

---

## Overview

One feature for version 1.8, plus splash regeneration and the version bump.

**MITRE ATT&CK technique mapping (roadmap candidate 3).** Every implementation step gains a curated set of ATT&CK technique mappings, each with a relationship (Prevent / Detect / Recover / Support) and an optional note. These surface in three places:

1. **Technique capsules** on each step in `MaturityLevelView`, alongside the existing ISM capsules.
2. **A technique detail sheet** — canonical name, tactics, the steps that map to it grouped by relationship, notes, and a link to attack.mitre.org.
3. **An ATT&CK Coverage screen** — techniques grouped by tactic, each showing how much of its mapped coverage you have actually implemented, respecting the active profile, target maturity level and OS scope filter.

The data is static reference content. It is compiled into the binary exactly like `EssentialControlsData`. No network calls, no new entitlements, no new persisted state.

### Locked decisions (agreed 26/07/2026 — do not revisit)

1. **ATT&CK v19.1.** Enterprise, released 28/04/2026. The v19 split of Defense Evasion into **Stealth (TA0005)** and **Defense Impairment (TA0112)** is reflected throughout, and revoked `T1562` / `T1562.001` are replaced by `T1685 Disable or Modify Tools`. There is no legacy-name aliasing.
2. **Per-step mappings, per-control rollup derived.** Mappings key off `ImplementationStep.id`. The per-control view is computed by union, never hand-maintained. (This supersedes the ROADMAP line that scoped candidate 3 as per-control.)
3. **Always on.** No About toggle. ATT&CK is reference content like the ISM capsules shipped in v1.4, not a workflow mode. **This means no new `UserDefaults` key, no `PersistedSettingsKey` registry entry, and no backup schema change — `BackupFile.currentSchemaVersion` stays at 2.**
4. **Partial coverage is shown as a fraction.** A technique reports *n of m* contributing steps implemented, with a badge: **Covered** (all), **Partial** (some), **Not covered** (none).
5. **Only Prevent / Detect / Recover count toward the fraction.** `Support` mappings are prerequisites or partial contributors — counting them would overclaim. A technique whose mappings are *all* Support shows an **Indirect** badge and no fraction.
6. **Not Applicable steps leave the denominator**, matching the existing compliance maths in `HomeView.overallCompliancePercentage`. A technique whose contributing steps are all N/A shows **Not applicable**, not 100%.
7. **Reference Only Mode hides the Coverage screen entirely** — it is a compliance surface. Step capsules and the technique detail sheet stay visible, because they are pure reference.
8. **Derived, non-authoritative, and the app says so.** ASD publishes no Essential Eight → ATT&CK mapping and MITRE's Mappings Explorer does not cover the Essential Eight or the ISM. Every ATT&CK surface carries a disclaimer. Wording is fixed in Step 6 — do not paraphrase it.
9. **The technique catalogue is closed.** 35 techniques, exactly as listed in `mitreattacke8.md`. A mapping referencing an ID outside the catalogue is a build-breaking defect, enforced by test (Step 10).

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

## Step 1 — Data model

**File:** new `ATTACKTechnique.swift` (app target).

```swift
/// ATT&CK Enterprise tactics, in v19.1 matrix order. Only the tactics reachable
/// from this app's mappings are modelled; `allCases` order is the display order.
enum ATTACKTactic: String, CaseIterable, Codable, Hashable, Identifiable {
    case initialAccess       = "Initial Access"
    case execution           = "Execution"
    case persistence         = "Persistence"
    case privilegeEscalation = "Privilege Escalation"
    case stealth             = "Stealth"
    case defenseImpairment   = "Defense Impairment"
    case credentialAccess    = "Credential Access"
    case lateralMovement     = "Lateral Movement"
    case collection          = "Collection"
    case impact              = "Impact"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

/// How an implementation step relates to an adversary technique.
/// Definitions are binding — see `mitreattacke8.md`.
enum ATTACKRelationship: String, CaseIterable, Codable, Hashable, Identifiable {
    /// Stops the technique succeeding, or removes the capability it depends on.
    case prevent = "Prevent"
    /// Produces the telemetry that reveals the technique. Does not stop it.
    case detect  = "Detect"
    /// Restores the environment after the technique has already succeeded.
    case recover = "Recover"
    /// A prerequisite for, or partial contributor to, coverage delivered elsewhere.
    case support = "Support"

    var id: String { rawValue }

    /// Support is deliberately excluded — see locked decision 5.
    var countsTowardCoverage: Bool { self != .support }
}

struct ATTACKTechnique: Identifiable, Hashable {
    /// ATT&CK ID, e.g. "T1204.002".
    let id: String
    /// Canonical ATT&CK name, e.g. "Malicious File".
    let name: String
    /// Every tactic ATT&CK lists for this technique, in matrix order.
    let tactics: [ATTACKTactic]
    let url: URL

    var isSubTechnique: Bool { id.contains(".") }
    /// Parent ID for a sub-technique, e.g. "T1204" for "T1204.002".
    var parentID: String? { isSubTechnique ? String(id.prefix(while: { $0 != "." })) : nil }
}

/// One curated link between an implementation step and a technique.
struct ATTACKMapping: Identifiable, Hashable {
    /// Matches `ImplementationStep.id` — "control-level-index", 0-based index.
    let stepID: String
    let techniqueID: String
    let relationships: [ATTACKRelationship]
    /// Caveat, scope limit or known bypass. Never put caveats in a technique name.
    let note: String?

    var id: String { "\(stepID)|\(techniqueID)" }
}
```

Use `[ATTACKTactic]` and `[ATTACKRelationship]`, not `Set` — display order matters and these collections are tiny. (This intentionally differs from the draft schema that used to sit at the bottom of `mitreattacke8.md`, which used `Set` and had no note field.)

**GATE-BUILD.**

---

## Step 2 — Technique catalogue

**File:** new `ATTACKCatalogue.swift` (app target).

Transcribe all 35 techniques from the "Technique catalogue" table in `mitreattacke8.md`. Header comment must record:

```
//  MITRE ATT&CK® Enterprise v19.1 (released 28/04/2026).
//  Technique IDs, names and tactics validated against the machine-readable
//  ATT&CK STIX bundle (mitre-attack/attack-stix-data, collection 19.1).
//  Re-verify on every ATT&CK major version bump (roughly April and October).
//  ATT&CK® is a registered trademark of The MITRE Corporation.
```

```swift
enum ATTACKCatalogue {
    static let attackVersion = "v19.1"
    static let attackVersionReleased = "28 April 2026"
    /// Publication year of the ATT&CK release reproduced above — NOT the current
    /// year and NOT the build year. It advances only when the pinned version does,
    /// which is the only time the reproduced content actually changes.
    static let attackCopyrightYear = "2026"

    static let all: [ATTACKTechnique] = [ /* 35 entries, ascending by ID */ ]

    static let byID: [String: ATTACKTechnique] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func technique(_ id: String) -> ATTACKTechnique? { byID[id] }
}
```

`Dictionary(uniqueKeysWithValues:)` traps on a duplicate ID — that is the intended behaviour, it catches a transcription slip at first launch rather than shipping a silently deduplicated catalogue.

**GATE-BUILD.**

---

## Step 3 — Mapping data

**File:** new `ATTACKMappingData.swift` (app target).

Transcribe every row of the eight "Step mappings" tables in `mitreattacke8.md`. Where the source document lists the same `Step ID` on several rows (because different techniques carry different relationships or notes), that is deliberate — produce one `ATTACKMapping` per row.

Where a row lists several techniques sharing one relationship and note, expand it to one `ATTACKMapping` per technique.

```swift
enum ATTACKMappingData {
    /// One entry per (step, technique) pair. Source: mitreattacke8.md (26/07/2026).
    static let all: [ATTACKMapping] = [ /* grouped by control, in step order */ ]

    static let byStepID: [String: [ATTACKMapping]] = Dictionary(grouping: all, by: \.stepID)
    static let byTechniqueID: [String: [ATTACKMapping]] = Dictionary(grouping: all, by: \.techniqueID)

    static func mappings(for stepID: String) -> [ATTACKMapping] { byStepID[stepID] ?? [] }
    static func mappings(forTechnique id: String) -> [ATTACKMapping] { byTechniqueID[id] ?? [] }
}
```

Two steps are **deliberately unmapped** — `2-1-2` (Inventory installed applications) and `6-1-2` (Inventory OS versions). Do not invent mappings for them. Record the reason as a code comment at the point in the file where each would otherwise appear: defender asset inventory is not the adversary discovery behaviour described by `T1518` / `T1082`.

**GATE-BUILD.**

---

## Step 4 — Coverage engine

**File:** new `ATTACKCoverage.swift` (app target).

Pure functions over `ProgressStore` — no view code, so it can be unit tested directly.

```swift
struct TechniqueCoverage: Identifiable, Hashable {
    let technique: ATTACKTechnique
    /// Steps mapped with Prevent/Detect/Recover that are in scope and not N/A.
    let contributingTotal: Int
    let contributingImplemented: Int
    /// Steps mapped only with Support, in scope and not N/A.
    let supportingTotal: Int
    /// True when this technique has mappings, but none of them count toward coverage.
    let isIndirectOnly: Bool
    /// True when every contributing step in scope is marked Not Applicable.
    let isNotApplicable: Bool

    var id: String { technique.id }

    var fraction: Double? {
        guard contributingTotal > 0 else { return nil }
        return Double(contributingImplemented) / Double(contributingTotal)
    }

    var status: CoverageStatus { /* see below */ }
}

enum CoverageStatus {
    case covered        // contributingTotal > 0 && implemented == total
    case partial        // contributingTotal > 0 && 0 < implemented < total
    case notCovered     // contributingTotal > 0 && implemented == 0
    case indirect       // isIndirectOnly
    case notApplicable  // every in-scope contributing step is N/A
}
```

Scope rules, applied in this order:

1. **In scope** = the step appears in `control.steps(upTo: progressStore.targetMaturityLevel, scope: progressStore.osScope)` for its owning control. Reuse the existing helpers; do not reimplement scope matching.
2. **Contributing** = in-scope, and mapped to this technique with at least one relationship where `countsTowardCoverage` is true.
3. **Not Applicable steps are removed from both numerator and denominator** (`progressStore.isNotApplicable(_:)`).
4. **Implemented** = `progressStore.isCompleted(_:)`.

Precedence when statuses conflict: `indirect` beats everything (the technique has no contributing mappings at all), then `notApplicable` (contributing mappings existed but all were marked N/A), then the fraction-based cases.

A technique with no in-scope mappings at all (e.g. every mapped step sits above the target maturity level) is **omitted from the Coverage screen** rather than shown as 0%. State this in the screen's footer so an empty tactic group is not read as a bug.

Public API:

```swift
enum ATTACKCoverageCalculator {
    static func coverage(for technique: ATTACKTechnique, store: ProgressStore) -> TechniqueCoverage?
    static func allCoverage(store: ProgressStore) -> [TechniqueCoverage]          // in-scope only, ID order
    static func techniques(forControl controlID: Int, store: ProgressStore) -> [ATTACKTechnique]
    static func grouped(store: ProgressStore) -> [(tactic: ATTACKTactic, coverage: [TechniqueCoverage])]
}
```

`grouped` returns tactics in `ATTACKTactic.allCases` order, omitting empty groups. **A technique with several tactics appears under each of them** — that is ATT&CK's own model, and the screen footer must say so, otherwise the totals look inflated.

**GATE-BUILD.**

---

## Step 5 — Step capsules and technique detail

**Files:** `MaturityLevelView.swift` (modify), new `ATTACKTechniqueDetailView.swift`.

**5a. Capsules.** Add an `ATTACKTechniqueCapsules` view built exactly like the existing `ISMControlsCapsules` (same `LazyVGrid`, same padding and capsule shape) but tinted **purple** to distinguish it from the blue ISM capsules, and rendered as tappable buttons rather than static text. Place it directly beneath `ISMControlsCapsules(controls: step.ismControls)` in the step body. Capsule label: the technique ID (`T1204.002`) — IDs are what an analyst searches for and they keep the row compact.

Render nothing when the step has no mappings. Accessibility label: `"ATT&CK techniques: T1204.002 Malicious File, T1059 Command and Scripting Interpreter"`.

**5b. Detail sheet.** Tapping a capsule presents `ATTACKTechniqueDetailView` as a sheet:

- Header: technique ID, canonical name, tactic capsules.
- **Relationship sections** — Prevent, Detect, Recover, Support, in that order, omitting empty ones. Each lists every step mapped to this technique under that relationship, across *all eight controls*, showing control name, ML badge, step title, current status icon and the mapping note if present. This cross-control view is the point of the sheet: it shows that (say) `T1550.002` is addressed by LAPS, Credential Guard, Protected Users and smart-card enforcement at once.
- Footer: the disclaimer from Step 6, and a `Link` to `technique.url` labelled "View on attack.mitre.org".
- Steps listed here are **not** filtered by target maturity level or OS scope — the sheet is reference, not assessment. Mark out-of-scope steps with a muted "Not in your current scope" caption so the difference from the Coverage screen is visible rather than confusing.

**GATE-BUILD.**

---

## Step 6 — Attribution, disclaimer and MITRE trademark compliance

**Files:** `AppInformation.swift`, `AboutView.swift` (modify).

Verified 30/07/2026 against MITRE's [Terms of Use](https://attack.mitre.org/resources/legal-and-branding/terms-of-use/) and [Legal & Branding](https://attack.mitre.org/resources/legal-and-branding/) pages. ATT&CK is licensed non-exclusively and royalty-free for research, development **and commercial** purposes, so App Store distribution is permitted — provided the copyright designation below is reproduced and the naming rules are followed.

Add to `AppInformation`, verbatim:

```swift
static let attackDisclaimerShort =
    "Derived mapping — not an ASD or MITRE product."

static let attackDisclaimer =
    "ASD does not publish an Essential Eight to MITRE ATT&CK mapping. These technique links are derived and curated by the author from the ASD Essential Eight to ISM mapping and MITRE ATT&CK technique descriptions, and are provided as an aid to understanding — not as an authoritative or certified mapping. Verify against your own threat model before relying on them."

/// Required by MITRE's Terms of Use. The rendered string must be character-for-character
/// as MITRE specifies; only the year is interpolated, and it is bound to the pinned
/// ATT&CK release so it cannot drift out of step with the data it describes.
static let attackAttribution =
    "© \(ATTACKCatalogue.attackCopyrightYear) The MITRE Corporation. This work is reproduced and distributed with the permission of The MITRE Corporation. MITRE ATT&CK® and ATT&CK® are registered trademarks of The MITRE Corporation."

/// MITRE's own caveat. Load-bearing for a screen that shows "Covered" badges.
static let attackCoverageCaveat =
    "MITRE does not claim ATT&CK enumerates every possible adversary behaviour, and using ATT&CK does not guarantee full defensive coverage. A technique shown as covered means the mapped implementation steps are complete — not that your environment is defended against it."

static let attackVersionNote =
    "Mapped against MITRE ATT&CK® Enterprise \(ATTACKCatalogue.attackVersion), released \(ATTACKCatalogue.attackVersionReleased)."
```

Also amend the existing `aboutMeDescription`, which currently disclaims affiliation with ASD and Microsoft only:

```swift
static let aboutMeDescription = "MadDogWarner is not affiliated with ASD, Microsoft or The MITRE Corporation in any way. This project is a passion project built to provide a clear, easy to understand security tool that helps technical teams uplift Essential Eight practices to the masses."
```

Add two entries to `AppInformation.referenceLinks`: `https://attack.mitre.org/` as "MITRE ATT&CK Enterprise matrix", and `https://attack.mitre.org/resources/legal-and-branding/terms-of-use/` as "MITRE ATT&CK terms of use".

In `AboutView`, add a section headed **"MITRE ATT&CK®"** showing `attackDisclaimer`, `attackCoverageCaveat`, `attackVersionNote` and `attackAttribution`, in that order.

Do not reword `attackDisclaimer`, `attackAttribution` or `attackCoverageCaveat`. The first two are the legal posture; the third is MITRE's own caveat and is the honest answer to a user who reads a green "Covered" badge as "I am safe from this".

### MITRE naming rules — binding on every user-facing string

These come from MITRE's branding page and apply to all UI text, the splash, App Store metadata and release notes:

1. **The first reference in any piece of writing must be "MITRE ATT&CK®"**; later references in the same context may be plain "ATT&CK" with no symbol. Applied below: the splash feature title, the Home section label and the About section header all carry the full form with ®, because each can be a user's first sight of the name. Deeper labels (capsule accessibility text, the control-detail rollup row, navigation titles) use plain "ATT&CK".
2. **Headlines always use "MITRE ATT&CK®"** — never bare "ATT&CK®".
3. **Always capitalise ATT&CK.** Never hyphenate, abbreviate or alter it ("ATTK", "Att&ck", "ATT&CK'd" are all prohibited).
4. **Never use ATT&CK in a product name, service name, trademark, logo or company name.** "Essential 8 Knowledge Base" is unaffected — but this constrains App Store metadata (see Step 12).
5. **Never imply MITRE affiliation, sponsorship or endorsement.** This is why `attackDisclaimerShort` appears on every ATT&CK surface, not just in About.
6. **No MITRE logos or brand imagery.** The app uses an SF Symbol, which sidesteps the logo rules entirely. Do not add a MITRE mark.

The Swift identifiers `ATTACKTechnique`, `ATTACKCatalogue`, `ATTACKMappingData` etc. are unaffected by rule 3 — Swift identifiers cannot contain `&`, these strings are never displayed, and MITRE's own repositories use the same `attack` form (`mitre-attack/attack-stix-data`, `enterprise-attack.json`).

**GATE-BUILD.**

---

## Step 7 — Coverage screen

**Files:** new `ATTACKCoverageView.swift`; `HomeView.swift` (modify).

**7a. Entry point.** In `HomeView`, add a section directly after the "Event Logging" section:

```swift
if !referenceOnlyMode {
    Section {
        NavigationLink { ATTACKCoverageView() } label: {
            Label("MITRE ATT&CK® Coverage", systemImage: "shield.checkerboard")
        }
    } header: {
        Text("Threat Coverage")
    } footer: {
        Text("Which adversary techniques your implemented steps act against. \(AppInformation.attackDisclaimerShort)")
            .font(.footnote)
    }
}
```

Locked decision 7: the whole section is hidden under Reference Only Mode. Pick a different SF Symbol if `shield.checkerboard` is unavailable on the deployment target.

**7b. The screen.** A `List` driven by `ATTACKCoverageCalculator.grouped(store:)`:

- **Summary header** — counts of Covered / Partial / Not covered across in-scope techniques, and the line "Measured against your target of ML*n*, *scope* scope." matching the existing wording style in `ControlDetailView`.
- **One section per tactic**, in matrix order, headed by the tactic name and a count.
- **Each row**: technique ID, name, a coverage badge, and `n of m steps` where a fraction exists. Badge colours follow the app's existing semantics — green Covered, orange Partial, secondary-grey Not covered, secondary-grey Indirect, orange Not applicable. Do not use red; nothing here is an error state.
- Tapping a row opens the same `ATTACKTechniqueDetailView` from Step 5.
- **Footer**, required: "A technique that belongs to several tactics appears under each. Techniques with no steps in your current maturity and OS scope are not listed. \(AppInformation.attackDisclaimerShort)"
- **`AppInformation.attackCoverageCaveat` must appear on this screen**, not only in About — either as a second footer line or in the summary header. This is the screen that renders green "Covered" badges, so it is the screen that has to say a covered technique means the mapped steps are complete, not that the environment is defended.

**GATE-BUILD.**

---

## Step 8 — Per-control rollup

**File:** `ControlDetailView.swift` (modify).

Add a section after "Implementation Progress":

```swift
Section {
    NavigationLink {
        ATTACKCoverageView(controlFilter: control.id)
    } label: {
        Label("\(techniqueCount) ATT&CK techniques addressed", systemImage: "shield.checkerboard")
    }
} header: {
    Text("Threat Coverage")
}
```

`techniqueCount` comes from `ATTACKCoverageCalculator.techniques(forControl:store:)`. Give `ATTACKCoverageView` an optional `controlFilter: Int?` (default `nil`) that restricts the technique set to those mapped from that control's steps; the navigation title becomes "\(control.name) — ATT&CK". Hide this section under Reference Only Mode, consistent with Step 7.

**GATE-BUILD.**

---

## Step 9 — Global Search

**File:** `GlobalSearchView.swift` (modify).

Extend `ImplementationStep.matchesSearchQuery(_:)` and `matchingDetails(for:)` so a step also matches on:

- technique ID (`T1204.002`, and a bare `T1204` must match its sub-techniques),
- canonical technique name (`Malicious File`),
- mapping note text (this is what makes the documented `T1553.005` Mark-of-the-Web bypass findable).

Matched techniques join `matchedDetails` formatted as `T1204.002 — Malicious File (Prevent)`. Update the empty-state hint text (currently around line 121) to include an ATT&CK example, e.g. `'T1059'`.

`ImplementationStep` has no reference to `ATTACKMappingData`, so put the lookup in the extension in `GlobalSearchView.swift`, not in the model type. Keep `EssentialControl.swift` free of ATT&CK imports.

**GATE-BUILD.**

---

## Step 10 — Tests

**File:** `Essential_8_Knowledge_BaseTests.swift` (extend, matching the existing test style).

**Data integrity — these are the ones that matter.** A wrong mapping is a defect, so the suite must make transcription errors impossible to merge:

1. `testEveryMappingReferencesAKnownTechnique` — every `ATTACKMapping.techniqueID` resolves in `ATTACKCatalogue.byID`.
2. `testEveryMappingReferencesARealStep` — every `ATTACKMapping.stepID` matches an `ImplementationStep.id` in `EssentialControlsData`.
3. `testNoOrphanTechniques` — every technique in the catalogue is referenced by at least one mapping (catches a technique added but never used).
4. `testCatalogueHasNoDuplicateIDs` and `testMappingsHaveNoDuplicateStepTechniquePairs`.
5. `testDeliberatelyUnmappedSteps` — asserts `2-1-2` and `6-1-2` have zero mappings, so a future well-meaning addition has to consciously delete the test.
6. `testMappingCoverageIsComplete` — all 67 steps minus those 2 have at least one mapping; assert the exact expected count of mapped steps (65) so a dropped table row fails loudly.
7. `testNoRevokedTechniqueIDs` — assert `T1562` and `T1562.001` appear nowhere in the catalogue or mappings.
8. `testEveryTechniqueHasAtLeastOneTactic`.
8b. `testCopyrightYearMatchesPinnedRelease` — `attackVersionReleased` ends with `attackCopyrightYear`. Guards against a partial version bump leaving the MITRE attribution year behind.

**Coverage maths:**

9. `testCoverageIgnoresSupportOnlyMappings` — a technique reachable only via `Support` reports `.indirect` and a nil fraction.
10. `testNotApplicableStepsLeaveTheDenominator` — mark one of two contributing steps N/A and implement the other; expect `.covered`, not 50%.
11. `testAllContributingStepsNotApplicableReportsNotApplicable`.
12. `testCoverageRespectsTargetMaturityLevel` — a technique mapped only from ML3 steps is absent at an ML1 target.
13. `testCoverageRespectsOSScopeFilter`.
14. `testCoverageIsProfileScoped` — implementing a step in profile A does not move coverage in profile B (guards the v1.7 profile isolation).
15. `testPartialCoverageReportsCorrectFraction`.

**UI tests** (`Essential_8_Knowledge_BaseUITests.swift`):

16. Coverage screen is reachable from Home and lists tactic sections.
17. Coverage entry points disappear when Reference Only Mode is on, on both Home and the control detail screen.
18. Tapping a technique capsule on a maturity-level page presents the detail sheet.

**GATE-TEST.**

---

## Step 11 — Splash and version bump

**Files:** `SplashView.swift`, `project.pbxproj`.

**11a.** Replace the "What's New in Version 1.7" block with **"What's New in Version 1.8"** and exactly two feature rows (the file's existing `featureRow` helper, unchanged):

```swift
featureRow(
    icon: "shield.checkerboard",
    color: .purple,
    title: "MITRE ATT&CK® Mapping",
    description: "Every implementation step now shows the adversary techniques it acts against, with the ATT&CK relationship — prevent, detect, recover or support."
)

featureRow(
    icon: "chart.bar.doc.horizontal",
    color: .blue,
    title: "Threat Coverage",
    description: "See which ATT&CK techniques your implemented steps actually cover, grouped by tactic and scoped to your target maturity level."
)
```

Remove the v1.7 rows entirely — the splash shows only the current release, per the v1.6 and v1.7 precedent.

**11b.** Set `MARKETING_VERSION = 1.8` and `CURRENT_PROJECT_VERSION = 9` in **all six** build-configuration blocks in `project.pbxproj`. `AppInformation.versionDisplay` reads these from the bundle, so no other version string needs touching.

**GATE-BUILD**, then **GATE-TEST**.

---

## Step 12 — Documentation

**Files:** `CHANGELOG.md`, `ROADMAP.md`, `README.md`.

- **CHANGELOG.md** — add a `## 1.8 — 2026-07-26` entry above 1.7, in the established voice: the mapping itself, the coverage screen, the search extension, the disclaimer, the splash and version bump, the test coverage.
- **ROADMAP.md** — move candidate 3 into "Shipped" with the implementation date, and note explicitly that it shipped **per-step rather than per-control**, mapped against **ATT&CK v19.1**, and must be re-verified on each ATT&CK major version bump. Remove candidate 3 from the "Candidates — v1.7+" list.
- **README.md** — add ATT&CK to the feature list and reproduce `attackAttribution` verbatim. First reference in the file must be "MITRE ATT&CK®".

**App Store metadata — David's to write, not Codex's, but the constraints are the same.** Flagging here so it is not missed at submission:

- The app name, subtitle and any in-app purchase names **must not contain ATT&CK** (MITRE branding rule 4). "Essential 8 Knowledge Base" is fine; something like "Essential 8 — ATT&CK Edition" would not be.
- Description and release notes may say the app *includes* or *maps to* MITRE ATT&CK®, with the first mention carrying the full form and ®. They must not phrase it in a way that implies MITRE endorses, certifies or partners with the app.
- Reproducing `attackAttribution` in the App Store description is not required by MITRE — the in-app About screen satisfies the Terms of Use — but it costs nothing and pre-empts a reviewer question.

**GATE-BUILD.**

---

## Out of scope for v1.8

Do not build these, even if they seem natural:

- ATT&CK Navigator layer export, or any other export — that is roadmap candidate 1.
- Groups, software, campaigns, mitigations or data-component objects from ATT&CK. Techniques only.
- Any network fetch of ATT&CK data. The catalogue is static and compiled in; the app remains fully offline apart from user-initiated `Link` taps to attack.mitre.org.
- Sub-technique tree navigation (parent → children browsing). `parentID` exists for search matching only.
- ICS or Mobile matrices. Enterprise only — and note the Defense Evasion split is Enterprise-only, so Mobile/ICS terminology would not match.
- Changing `BackupFile`, `PersistedSettingsKey` or anything else in the persistence layer. If you find yourself editing those files, stop — you have misread locked decision 3.
