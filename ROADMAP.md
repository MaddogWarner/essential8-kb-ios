# Roadmap

Forward-looking feature plan for the Essential 8 Knowledge Base app. Shipped history lives in `CHANGELOG.md`; the active build spec lives in `codex-plan.md`.

## In flight — v1.4

Target Maturity Level + ISM control mapping. Spec: `codex-plan.md`. Code approved; ISM identifiers populated from `reference/e8-ism-mapping-oct2024.pdf` and verified against the source (05/07/2026, 64/67 steps mapped — see `reference/e8-ism-mapping-summary.md`). Awaiting App Store release.

## Candidates — v1.5

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

1. Essential Eight requirement → ISM control, via the official ASD mapping (already in the app once v1.4 ships).
2. ISM control → NIST SP 800-53 equivalent → ATT&CK technique, via CTID's maintained 800-53 → ATT&CK mapping (<https://center-for-threat-informed-defense.github.io/mappings-explorer/>).

The chain is lossy, so every derived technique tag needs manual curation and review before it goes in the data file — same rule as ISM identifiers: an absent tag is correct, a wrong tag is a defect. Record the ATT&CK version used (e.g. v16.1) in the data file header, as tags must be re-checked when ATT&CK versions bump.

**Why:** connects the compliance view to adversary behaviour — answers "what attacks does this control actually stop". No competing app has a sourced E8 → ATT&CK layer.

**Depends on:** v1.4 ISM mapping shipping (step 1 of the derivation chain).
