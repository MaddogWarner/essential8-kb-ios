# Roadmap

Forward-looking feature plan for the Essential 8 Knowledge Base app. Shipped history lives in `CHANGELOG.md`; the active build spec lives in `codex-plan.md`.

## Shipped

- **v1.4 — Target Maturity Level + ISM control mapping.** Merged to `main` 05/07/2026 (PR #8). ISM identifiers populated from `reference/e8-ism-mapping-oct2024.pdf` and verified against the source (64/67 steps mapped — see `reference/e8-ism-mapping-summary.md`).
- **v1.5 — Technical content corrections.** Merged to `main` 05/07/2026 (PR #9). Corrections ported from the Android review (AppLocker deny paths, AppIDSvc caveat, Edge Java/ads guidance, MOTW supported-app list, `wbadmin` credential caution). See `CHANGELOG.md` 1.5. Note: the v1.5 number was taken by these corrections — the feature candidates previously listed under v1.5 moved to v1.6.
- **v1.6 — OS scope tags + progress backup and transfer.** Implemented 13/07/2026. Adds conservative Workstation/Server filtering with recalculated compliance, full offline JSON backup/restore, persisted-state coverage enforcement and bundle-driven version display.
- **v1.7 — Multiple profiles + deep audit mode.** Implemented 19/07/2026. Adds independent named assessment contexts, timestamped per-step status history with optional notes, and profile-aware schema-v2 backup and restore. Image/screenshot evidence attachment remains parked as a future enhancement on top of the shipped audit trail.
- **v1.8 — MITRE ATT&CK® technique mapping + coverage.** Implemented 26/07/2026. Shipped as curated per-step mappings rather than the originally proposed per-control tags, pinned to ATT&CK Enterprise v19.1. The catalogue and mappings must be re-verified on every ATT&CK major version bump.

## Scoped — v1.6 (implemented)

Agreed 13/07/2026: v1.6 = candidate 6 (OS scope tags) + candidate 7 (progress backup/transfer), plus About-page app-version display. Build spec written in `codex-plan.md`; branch off `main` (contains v1.5 as of PR #9). Locked decisions: scope filter hides steps and recalculates compliance; export captures all persistent state; import replaces after confirmation; tagging is conservative (default `both`); a persisted-state registry + coverage test enforces that future persistent data is included in the backup format.

## Candidates — v1.7+

Unordered; scope and sequencing to be agreed before a build spec is written.

### 1. Exportable compliance report

Generate a PDF or CSV from `ProgressStore` data — per-control compliance, step statuses, N/A reasons — shared via the iOS share sheet.

**Why:** the assessment currently lives only on the phone. Admins doing an Essential Eight uplift almost always need to hand something to a manager, auditor, or client. The export also doubles as a backup of progress, which today cannot leave the device.

### 2. Verification commands per step

Each step currently tells you how to *set* a control. Add a copyable "how to check it's applied" companion per step (`gpresult`, `auditpol /get`, `Get-ItemProperty`, `Get-MpPreference`, etc.).

**Why:** turns the app from a configuration reference into an audit tool. It is what someone marking a step "Implemented" actually needs to justify the tick.

### 3. iPad split-view layout (and a compliance widget)

Adopt `NavigationSplitView` so the controls list sits on the left and step detail on the right, with proper multitasking/Slide Over support. While in that layer, add a small home-screen widget showing the compliance ring (WidgetKit reading the shared store).

**Why:** the app is iPhone-shaped, but the real "next to a console" device is often an iPad beside an RDP session. The widget adds daily glanceability for very little extra code.

### 4. Spotlight and App Intents integration for Global Search

Expose the Global Search index (GPO paths, registry keys, commands, ISM IDs) to the OS via Core Spotlight and App Intents, deep-linking straight to the matched step. Include a "Search Essential 8" Siri shortcut.

**Why:** for a quick-reference app, shaving the launch → navigate → search path down to one system-level search is a genuine speed win. All on-device indexing — no privacy impact.

## Dependencies

- The shipped v1.7 audit trail compounds with candidate 1 (export report).
