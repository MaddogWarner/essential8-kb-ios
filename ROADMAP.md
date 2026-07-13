# Roadmap

Forward-looking feature plan for the Essential 8 Knowledge Base app. Shipped history lives in `CHANGELOG.md`; the active build spec lives in `codex-plan.md`.

## Shipped

- **v1.4 — Target Maturity Level + ISM control mapping.** Merged to `main` 05/07/2026 (PR #8). ISM identifiers populated from `reference/e8-ism-mapping-oct2024.pdf` and verified against the source (64/67 steps mapped — see `reference/e8-ism-mapping-summary.md`).
- **v1.5 — Technical content corrections.** Merged to `main` 05/07/2026 (PR #9). Corrections ported from the Android review (AppLocker deny paths, AppIDSvc caveat, Edge Java/ads guidance, MOTW supported-app list, `wbadmin` credential caution). See `CHANGELOG.md` 1.5. Note: the v1.5 number was taken by these corrections — the feature candidates previously listed under v1.5 moved to v1.6.

## Scoped — v1.6

Agreed 13/07/2026: v1.6 = candidate 6 (OS scope tags) + candidate 7 (progress backup/transfer), plus About-page app-version display. Build spec written in `codex-plan.md`; branch off `main` (contains v1.5 as of PR #9). Locked decisions: scope filter hides steps and recalculates compliance; export captures all persistent state; import replaces after confirmation; tagging is conservative (default `both`); a persisted-state registry + coverage test enforces that future persistent data is included in the backup format.

## Candidates — v1.7+

Unordered; scope and sequencing to be agreed before a build spec is written.

### 1. Exportable compliance report

Generate a PDF or CSV from `ProgressStore` data — per-control compliance, step statuses, N/A reasons — shared via the iOS share sheet.

**Why:** the assessment currently lives only on the phone. Admins doing an Essential Eight uplift almost always need to hand something to a manager, auditor, or client. The export also doubles as a backup of progress, which today cannot leave the device.

### 2. Verification commands per step

Each step currently tells you how to *set* a control. Add a copyable "how to check it's applied" companion per step (`gpresult`, `auditpol /get`, `Get-ItemProperty`, `Get-MpPreference`, etc.).

**Why:** turns the app from a configuration reference into an audit tool. It is what someone marking a step "Implemented" actually needs to justify the tick.

### 3. Multiple environment profiles

A named-profile switcher layered over `ProgressStore`, so one person can track several environments — e.g. production vs DR domain, or multiple clients for MSP/consultant users.

**Why:** that audience is a natural fit for the app and currently has to reset all progress between engagements.

### 4. MITRE ATT&CK technique mapping

Tag each control (per-control, not per-step) with the ATT&CK techniques it mitigates — e.g. Application Control → T1204 User Execution, T1059 Command and Scripting Interpreter; Office Macros → T1566 Phishing.

No canonical Essential Eight → ATT&CK mapping exists (MITRE CTID's Mappings Explorer does not cover the Essential Eight or the ISM; ASD maps the Essential Eight to the ISM only). **Approach: derive the mapping indirectly through maintained authoritative sources at both ends:**

1. Essential Eight requirement → ISM control, via the official ASD mapping (shipped in v1.4).
2. ISM control → NIST SP 800-53 equivalent → ATT&CK technique, via CTID's maintained 800-53 → ATT&CK mapping (<https://center-for-threat-informed-defense.github.io/mappings-explorer/>).

The chain is lossy, so every derived technique tag needs manual curation and review before it goes in the data file — same rule as ISM identifiers: an absent tag is correct, a wrong tag is a defect. Record the ATT&CK version used (e.g. v16.1) in the data file header, as tags must be re-checked when ATT&CK versions bump.

**Why:** connects the compliance view to adversary behaviour — answers "what attacks does this control actually stop". No competing app has a sourced E8 → ATT&CK layer.

### 5. Per-step audit trail — timestamps, notes and evidence

`ProgressStore` records only the current status of each step. Date-stamp every status change, add an optional free-text note per step (ticket number, change record, who did it), and optionally a photo/screenshot attachment.

**Why:** auditors' first two questions are "when was this implemented?" and "show me the evidence" — today the app can answer neither. Also multiplies the value of the compliance report export (candidate 1): a PDF with dates and notes is an assessment artefact; one without is just a checklist.

### 6. OS scope tags — Workstation vs Server filtering

Tag each implementation step with where it applies (Windows 11 client, Windows Server, or both) and let the user filter. A data-model field plus a filter toggle; no new screens.

**Why:** the content already mixes the two — `wbadmin`/Windows Server Backup, Credential Guard, ASR rule availability and Office-related steps differ materially between a workstation fleet and a domain controller. An admin at a server console currently has to mentally skip client-only steps.

### 7. Progress backup and transfer (export/import)

JSON export/import of `ProgressStore` state via the share sheet — AirDrop to a new phone, or file it as a backup. Stays fully offline.

**Why:** all assessment data lives in `UserDefaults` on one device — a lost or replaced phone wipes potentially weeks of assessment work. Honours the no-network privacy posture, and is the natural enabler for environment profiles (candidate 3): a profile is essentially an importable snapshot.

### 8. iPad split-view layout (and a compliance widget)

Adopt `NavigationSplitView` so the controls list sits on the left and step detail on the right, with proper multitasking/Slide Over support. While in that layer, add a small home-screen widget showing the compliance ring (WidgetKit reading the shared store).

**Why:** the app is iPhone-shaped, but the real "next to a console" device is often an iPad beside an RDP session. The widget adds daily glanceability for very little extra code.

### 9. Spotlight and App Intents integration for Global Search

Expose the Global Search index (GPO paths, registry keys, commands, ISM IDs) to the OS via Core Spotlight and App Intents, deep-linking straight to the matched step. Include a "Search Essential 8" Siri shortcut.

**Why:** for a quick-reference app, shaving the launch → navigate → search path down to one system-level search is a genuine speed win. All on-device indexing — no privacy impact.

## Dependencies

- Candidate 4 (ATT&CK) depends on the v1.4 ISM mapping (shipped).
- Candidate 5 (audit trail) and candidate 7 (backup/transfer) both compound with candidate 1 (export report); consider sequencing them together.
- Candidate 7 is groundwork for candidate 3 (profiles).
