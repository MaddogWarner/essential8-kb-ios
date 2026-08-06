# Essential Eight → MITRE ATT&CK® Technique Mapping

**Status:** curated source of truth for the v1.8 ATT&CK layer. Reviewed and rebased 26/07/2026.

**Sources and methodology**

- Primary standard: ASD *Essential Eight Maturity Model* (November 2023).
- ISM cross-reference: ASD *Essential Eight maturity model and ISM mapping* (October 2024) — already shipped in the app as `ImplementationStep.ismControls` (v1.4).
- ATT&CK version: **Enterprise v19.1**, released 28/04/2026 — <https://attack.mitre.org/versions/v19/>
- Every technique ID, name and tactic in this document was validated against the machine-readable v19.1 STIX bundle (`mitre-attack/attack-stix-data`, collection version 19.1, modified 2026-05-12), not against prose.

**Attribution (required by MITRE's [Terms of Use](https://attack.mitre.org/resources/legal-and-branding/terms-of-use/), verified 30/07/2026)**

© 2026 The MITRE Corporation. This work is reproduced and distributed with the permission of The MITRE Corporation. MITRE ATT&CK® and ATT&CK® are registered trademarks of The MITRE Corporation.

MITRE does not claim ATT&CK enumerates every possible adversary behaviour, and using ATT&CK does not guarantee full defensive coverage.

**Provenance — read this before shipping any of it**

ASD does not publish an Essential Eight → ATT&CK mapping, and MITRE's Mappings Explorer does not cover the Essential Eight or the ISM. **This mapping is derived and author-curated. It is not authoritative and must not be presented as an ASD or MITRE product.** Each row is a considered judgement about which adversary behaviour a specific implementation step acts against, informed by the E8 → ISM mapping at one end and ATT&CK technique descriptions at the other. The app must carry a plain-language disclaimer to that effect.

Curation rule, carried over from the ISM work: **an absent mapping is correct; a wrong mapping is a defect.** Steps with no defensible technique are deliberately left empty rather than padded.

**ATT&CK v19 changes that affect this mapping**

1. The **Defense Evasion** tactic was split into **Stealth (TA0005)** and **Defense Impairment (TA0112)**. No technique in this document carries a "Defense Evasion" label any more.
2. **T1562 Impair Defenses** and **T1562.001 Disable or Modify Tools** were revoked, both replaced by **T1685 Disable or Modify Tools** (Defense Impairment).
3. Several techniques lost Defense Evasion without gaining a replacement: **T1548.002** is now Privilege Escalation only, and **T1550.002 / T1550.003** are now Lateral Movement only.

Re-verify this document whenever ATT&CK bumps a major version (roughly April and October each year).

---

## Relationship taxonomy

Exactly four relationships. These definitions are binding — they are the difference between an honest tool and a marketing claim.

| Relationship | Definition |
| :--- | :--- |
| **Prevent** | The step stops the technique from succeeding, or removes the capability the technique depends on. |
| **Detect** | The step produces the telemetry that reveals the technique. It does not stop it. |
| **Recover** | The step restores the environment after the technique has already succeeded. |
| **Support** | The step is a prerequisite for, or a partial contributor to, coverage delivered elsewhere. On its own it neither stops nor reveals the technique. |

A single step may hold different relationships to different techniques, and more than one relationship to the same technique (AMSI macro scanning both prevents and detects).

---

## Technique catalogue

All 35 techniques referenced below, with canonical v19.1 names and tactics. Names are ATT&CK's own; sub-techniques carry the short name (e.g. `T1204.002` is "Malicious File" under User Execution).

| ID | Name | Tactic(s) | URL |
| :--- | :--- | :--- | :--- |
| `T1003.001` | LSASS Memory | Credential Access | <https://attack.mitre.org/techniques/T1003/001/> |
| `T1021` | Remote Services | Lateral Movement | <https://attack.mitre.org/techniques/T1021/> |
| `T1055` | Process Injection | Stealth, Privilege Escalation | <https://attack.mitre.org/techniques/T1055/> |
| `T1059` | Command and Scripting Interpreter | Execution | <https://attack.mitre.org/techniques/T1059/> |
| `T1059.001` | PowerShell | Execution | <https://attack.mitre.org/techniques/T1059/001/> |
| `T1059.005` | Visual Basic | Execution | <https://attack.mitre.org/techniques/T1059/005/> |
| `T1068` | Exploitation for Privilege Escalation | Privilege Escalation | <https://attack.mitre.org/techniques/T1068/> |
| `T1078` | Valid Accounts | Stealth, Persistence, Privilege Escalation, Initial Access | <https://attack.mitre.org/techniques/T1078/> |
| `T1078.003` | Local Accounts | Stealth, Persistence, Privilege Escalation, Initial Access | <https://attack.mitre.org/techniques/T1078/003/> |
| `T1110` | Brute Force | Credential Access | <https://attack.mitre.org/techniques/T1110/> |
| `T1110.001` | Password Guessing | Credential Access | <https://attack.mitre.org/techniques/T1110/001/> |
| `T1111` | Multi-Factor Authentication Interception | Credential Access | <https://attack.mitre.org/techniques/T1111/> |
| `T1127` | Trusted Developer Utilities Proxy Execution | Stealth, Execution | <https://attack.mitre.org/techniques/T1127/> |
| `T1137.001` | Office Template Macros | Persistence | <https://attack.mitre.org/techniques/T1137/001/> |
| `T1189` | Drive-by Compromise | Initial Access | <https://attack.mitre.org/techniques/T1189/> |
| `T1190` | Exploit Public-Facing Application | Initial Access | <https://attack.mitre.org/techniques/T1190/> |
| `T1203` | Exploitation for Client Execution | Execution | <https://attack.mitre.org/techniques/T1203/> |
| `T1204.002` | Malicious File | Execution | <https://attack.mitre.org/techniques/T1204/002/> |
| `T1216` | System Script Proxy Execution | Stealth | <https://attack.mitre.org/techniques/T1216/> |
| `T1218` | System Binary Proxy Execution | Stealth | <https://attack.mitre.org/techniques/T1218/> |
| `T1485` | Data Destruction | Impact | <https://attack.mitre.org/techniques/T1485/> |
| `T1486` | Data Encrypted for Impact | Impact | <https://attack.mitre.org/techniques/T1486/> |
| `T1490` | Inhibit System Recovery | Impact | <https://attack.mitre.org/techniques/T1490/> |
| `T1543.003` | Windows Service | Persistence, Privilege Escalation | <https://attack.mitre.org/techniques/T1543/003/> |
| `T1548.002` | Bypass User Account Control | Privilege Escalation | <https://attack.mitre.org/techniques/T1548/002/> |
| `T1550.002` | Pass the Hash | Lateral Movement | <https://attack.mitre.org/techniques/T1550/002/> |
| `T1550.003` | Pass the Ticket | Lateral Movement | <https://attack.mitre.org/techniques/T1550/003/> |
| `T1553.002` | Code Signing | Defense Impairment | <https://attack.mitre.org/techniques/T1553/002/> |
| `T1556` | Modify Authentication Process | Defense Impairment, Persistence, Credential Access | <https://attack.mitre.org/techniques/T1556/> |
| `T1557` | Adversary-in-the-Middle | Credential Access, Collection | <https://attack.mitre.org/techniques/T1557/> |
| `T1566` | Phishing | Initial Access | <https://attack.mitre.org/techniques/T1566/> |
| `T1566.001` | Spearphishing Attachment | Initial Access | <https://attack.mitre.org/techniques/T1566/001/> |
| `T1566.002` | Spearphishing Link | Initial Access | <https://attack.mitre.org/techniques/T1566/002/> |
| `T1621` | Multi-Factor Authentication Request Generation | Credential Access | <https://attack.mitre.org/techniques/T1621/> |
| `T1685` | Disable or Modify Tools | Defense Impairment | <https://attack.mitre.org/techniques/T1685/> |

Tactic display order (v19.1 Enterprise matrix): Reconnaissance, Resource Development, Initial Access, Execution, Persistence, Privilege Escalation, **Stealth**, **Defense Impairment**, Credential Access, Discovery, Lateral Movement, Collection, Command and Control, Exfiltration, Impact.

---

## Step mappings

`Step ID` matches `ImplementationStep.id` in `EssentialControlsData.swift` (`control-level-index`, index 0-based). These IDs are the join key — titles are for human reading only.

There is deliberately **no per-row tactic column**: tactics are a property of the technique and live in the catalogue above. Caveats live in the Note column, never inside a technique name.

### 1. Application Control

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `1-1-0` | Enable the Application Identity service | `T1204.002`, `T1059` | Support | AppLocker enforcement depends on this service. Alone it blocks nothing. |
| `1-1-1` | Create AppLocker default rules | `T1204.002`, `T1218` | Prevent | |
| `1-1-2` | Block execution from user-writable locations | `T1204.002`, `T1059.001` | Prevent | Removes the drop-and-run paths most commodity loaders rely on. |
| `1-1-3` | Log block events | `T1204.002`, `T1059`, `T1218` | Detect | |
| `1-2-0` | Extend AppLocker enforcement to servers | `T1059` | Prevent | |
| `1-2-0` | Extend AppLocker enforcement to servers | `T1021` | Support | Constrains what an adversary can run after arriving over a remote service; does not block the remote service itself. |
| `1-2-1` | Deploy Windows Defender Application Control (WDAC) | `T1218`, `T1685` | Prevent | Code integrity blocks the unsigned tooling commonly used to disable security products. |
| `1-2-2` | Forward AppLocker / WDAC events centrally | `T1204.002`, `T1059`, `T1218` | Detect | |
| `1-3-0` | Apply Microsoft's recommended block rules | `T1218`, `T1127`, `T1216` | Prevent | The block list exists specifically to close signed-binary, developer-utility and script-host proxy execution. |
| `1-3-1` | Enable the vulnerable driver blocklist | `T1068` | Prevent | Closes the bring-your-own-vulnerable-driver path. |
| `1-3-1` | Enable the vulnerable driver blocklist | `T1543.003` | Prevent | A vulnerable driver is loaded as a kernel service; blocking the driver blocks that service creation. |
| `1-3-2` | Enforce Memory Integrity (HVCI) | `T1068`, `T1685` | Prevent | HVCI blocks unsigned kernel code, the usual route to tampering with security tooling from the kernel. |

### 2. Patch Applications

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `2-1-0` | Enable Microsoft Update for Office | `T1203` | Prevent | |
| `2-1-1` | Enable Microsoft Edge auto-update | `T1189`, `T1203` | Prevent | |
| `2-1-2` | Inventory installed applications | *(none)* | — | **Deliberately unmapped.** Asset inventory is a defender activity; it does not act against `T1518 Software Discovery`, which describes an adversary enumerating software. Mapping it would be a category error. |
| `2-1-3` | Uninstall unsupported applications | `T1203` | Prevent | |
| `2-1-3` | Uninstall unsupported applications | `T1190` | Prevent | Applies where the removed application was internet-facing. |
| `2-2-0` | Tighten Office and Edge update cadence | `T1203`, `T1189` | Prevent | |
| `2-2-1` | Enforce restart deadlines | `T1203` | Support | Patches only take effect after restart. The deadline closes the exposure window rather than blocking the technique. |
| `2-3-0` | Emergency patch deployment | `T1203`, `T1190` | Prevent | |

### 3. Configure Microsoft Office Macro Settings

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `3-1-0` | Block macros from the internet (Mark-of-the-Web) | `T1566.001`, `T1204.002` | Prevent | Depends on Mark-of-the-Web. Adversaries defeat it with container formats that do not propagate the mark — ISO, IMG, VHD, 7z — which ATT&CK tracks as `T1553.005 Mark-of-the-Web Bypass`. |
| `3-1-1` | Disable VBA macros without notification | `T1059.005` | Prevent | |
| `3-1-2` | Lock down the Trust Center | `T1566.001`, `T1059.005` | Prevent | Stops the user being able to click past the block. |
| `3-2-0` | Allow only digitally signed macros | `T1059.005` | Prevent | |
| `3-2-0` | Allow only digitally signed macros | `T1553.002` | Prevent | Only as strong as publisher scoping — a stolen or abused signing certificate defeats it. |
| `3-2-1` | Enable AMSI scanning of macros | `T1059.005` | Prevent, Detect | Inspects macro content at runtime, so obfuscated payloads are caught after de-obfuscation. |
| `3-2-2` | Enable VBA macro logging | `T1059.005` | Detect | |
| `3-3-0` | Require V3 (XML-DSig) signatures | `T1059.005`, `T1553.002` | Prevent | Stronger signature validation closes downgrade and tampering paths in legacy signature formats. |
| `3-3-1` | Restrict write access to Trusted Locations | `T1059.005` | Prevent | |
| `3-3-1` | Restrict write access to Trusted Locations | `T1137.001` | Prevent | A writable Trusted Location or template path is an Office persistence route, not just an execution one. |

### 4. User Application Hardening

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `4-1-0` | Disable Internet Explorer 11 | `T1189`, `T1203` | Prevent | Removes a legacy engine that no longer receives fixes. |
| `4-1-1` | Block Java in Microsoft Edge | `T1189` | Prevent | |
| `4-1-2` | Block web advertisements | `T1189` | Prevent | Targets malvertising. Edge Tracking Prevention alone is partial coverage — see the ML1 gap note in the app. |
| `4-2-0` | Enable PowerShell logging | `T1059.001` | Detect | |
| `4-2-1` | Deploy Attack Surface Reduction rules | `T1059`, `T1204.002`, `T1218`, `T1055` | Prevent | Coverage depends on which ASR rules are enabled and whether they are in Block or Audit mode. |
| `4-2-2` | Enable command-line process auditing | `T1059`, `T1059.001` | Detect | |
| `4-3-0` | Remove PowerShell v2 | `T1059.001` | Prevent | PowerShell v2 predates ScriptBlock logging and AMSI; removing it closes the downgrade path used to evade both. |
| `4-3-1` | Enforce Constrained Language Mode | `T1059.001` | Prevent | |
| `4-3-2` | Remove legacy .NET Framework | `T1203` | Prevent | |
| `4-3-2` | Remove legacy .NET Framework | `T1127` | Prevent | Legacy .NET ships the signed developer utilities (MSBuild, InstallUtil) used for proxy execution. |

### 5. Restrict Administrative Privileges

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `5-1-0` | Remove standard users from local Administrators | `T1078.003`, `T1548.002` | Prevent | |
| `5-1-1` | Deploy Windows LAPS | `T1078.003` | Prevent | |
| `5-1-1` | Deploy Windows LAPS | `T1550.002` | Prevent | Unique per-machine passwords stop a recovered local admin credential or hash working across the fleet. LAPS does not prevent the credential being dumped in the first place. |
| `5-1-2` | Block internet / email for privileged accounts | `T1566`, `T1078` | Prevent | Breaks the direct path from a phishing click to a privileged session. |
| `5-2-0` | Enable Credential Guard | `T1003.001` | Prevent | |
| `5-2-0` | Enable Credential Guard | `T1550.002` | Prevent | Protects the derived material an attacker would otherwise replay. |
| `5-2-1` | Protect LSASS (RunAsPPL) | `T1003.001` | Prevent | Weaker than Credential Guard; bypassable with a signed vulnerable driver, which is why `1-3-1` matters alongside it. |
| `5-2-2` | Apply Just Enough Administration (JEA) | `T1059.001`, `T1078` | Prevent | Constrains what a compromised privileged session can actually do. |
| `5-3-0` | Add privileged accounts to Protected Users | `T1550.002`, `T1550.003` | Prevent | Blocks NTLM, DES and RC4 for members and disallows delegation. Verify application compatibility first. |
| `5-3-1` | Privileged Access Workstation (PAW) | `T1078`, `T1021` | Prevent | Separates the administration plane from the browsing and email plane. |
| `5-3-2` | Audit privileged account use | `T1078`, `T1078.003` | Detect | |

### 6. Patch Operating Systems

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `6-1-0` | Configure Windows Update for Business | `T1203`, `T1068` | Prevent | |
| `6-1-1` | Enforce a quality-update deadline | `T1203`, `T1068` | Support | Bounds the exposure window; the patch itself does the preventing. |
| `6-1-2` | Inventory OS versions | *(none)* | — | **Deliberately unmapped**, for the same reason as `2-1-2`: `T1082 System Information Discovery` describes adversary enumeration, not defender inventory. |
| `6-2-0` | Tighten deferrals and deadlines | `T1203`, `T1068` | Prevent | |
| `6-2-1` | Include driver updates from Windows Update | `T1068` | Prevent | Driver flaws are a primary kernel privilege-escalation route. |
| `6-3-0` | Expedite critical patches | `T1203`, `T1068` | Prevent | |
| `6-3-0` | Expedite critical patches | `T1190` | Prevent | Applies to internet-facing systems. |
| `6-3-1` | Stay on N or N-1 Windows feature releases | `T1068`, `T1203` | Prevent | Out-of-support builds stop receiving fixes entirely, so every other patching step degrades to nothing. |

### 7. Multi-factor Authentication

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `7-1-0` | Enable Windows Hello for Business | `T1078`, `T1110` | Prevent | |
| `7-1-0` | Enable Windows Hello for Business | `T1111` | Prevent | Phishing-resistant: the credential is bound to the device and cannot be replayed elsewhere. |
| `7-1-1` | Enforce PIN complexity | `T1110.001` | Prevent | The PIN is device-local and TPM-protected, so this resists local guessing rather than remote spraying. |
| `7-1-2` | Enable smart-card support for legacy logon | `T1078`, `T1110` | Prevent | |
| `7-2-0` | Require MFA for all privileged accounts | `T1078`, `T1110` | Prevent | MFA that relies on push approval introduces its own attack surface — `T1621 MFA Request Generation`, or push fatigue. Prefer number matching or a phishing-resistant method. |
| `7-2-1` | Set SmartcardLogonRequired on admin accounts | `T1550.002` | Prevent | Randomises the account's NT hash when set, but does **not** rotate it afterwards. A hash captured later stays valid until rotated, so rotate on a schedule. |
| `7-2-1` | Set SmartcardLogonRequired on admin accounts | `T1550.003` | Support | |
| `7-3-0` | Deploy WHfB with certificate trust | `T1078`, `T1111`, `T1556` | Prevent | |
| `7-3-1` | Enable FIDO2 security key sign-in | `T1111`, `T1557` | Prevent | Origin-bound credentials mean an adversary-in-the-middle proxy cannot relay the authentication. |
| `7-3-1` | Enable FIDO2 security key sign-in | `T1566.002` | Support | Neutralises credential theft via a phishing link. It does not stop the link being sent or clicked. |
| `7-3-2` | Log and forward authentication events | `T1078`, `T1110`, `T1621` | Detect | Repeated denied MFA prompts are the signature of a push-fatigue attempt. |

### 8. Regular Backups

| Step ID | Implementation Step | Technique | Relationship | Note |
| :--- | :--- | :--- | :--- | :--- |
| `8-1-0` | Install Windows Server Backup | `T1490`, `T1486` | Support | Prerequisite only. The capability helps once backups are scheduled (`8-1-1`) and protected (`8-1-2`). |
| `8-1-1` | Schedule daily backups | `T1486`, `T1490`, `T1485` | Recover | |
| `8-1-2` | Restrict access to backup destinations | `T1485`, `T1490` | Prevent | A backup an adversary can reach with the credentials they already hold is not a backup. |
| `8-1-3` | Enable Volume Shadow Copies for file servers | `T1490` | Support | VSS is the first thing ransomware deletes — `vssadmin delete shadows` is squarely `T1490`. Treat shadow copies as user convenience, never as the backup. |
| `8-2-0` | Separate backup credentials | `T1078`, `T1490` | Prevent | |
| `8-2-1` | Restrict user access to their own backups | `T1485`, `T1486` | Prevent | |
| `8-3-0` | Use ReFS with integrity streams for backup volumes | `T1486`, `T1485` | Detect | Detects silent corruption or encryption of backup data. It does not reverse it. |
| `8-3-1` | Lock down with role separation | `T1485`, `T1490`, `T1078` | Prevent | |
| `8-3-2` | Offline / air-gapped copy | `T1486`, `T1490`, `T1485` | Recover | The only copy that reliably survives an adversary holding domain administrator. |

---

## Coverage summary

Derived from the table above by union — **do not hand-maintain this**. The app builds the per-control view the same way.

| Essential Eight Mitigation | Tactics addressed | Techniques |
| :--- | :--- | :--- |
| 1. Application Control | Execution, Stealth, Privilege Escalation, Persistence, Defense Impairment, Lateral Movement | T1204.002, T1059, T1059.001, T1218, T1021, T1685, T1127, T1216, T1068, T1543.003 |
| 2. Patch Applications | Execution, Initial Access | T1203, T1189, T1190 |
| 3. Office Macro Settings | Initial Access, Execution, Defense Impairment, Persistence | T1566.001, T1204.002, T1059.005, T1553.002, T1137.001 |
| 4. User Application Hardening | Initial Access, Execution, Stealth, Privilege Escalation | T1189, T1203, T1059, T1059.001, T1204.002, T1218, T1055, T1127 |
| 5. Restrict Admin Privileges | Stealth, Persistence, Privilege Escalation, Initial Access, Credential Access, Lateral Movement, Execution | T1078, T1078.003, T1548.002, T1550.002, T1550.003, T1566, T1003.001, T1059.001, T1021 |
| 6. Patch Operating Systems | Execution, Privilege Escalation, Initial Access | T1203, T1068, T1190 |
| 7. Multi-factor Authentication | Stealth, Persistence, Privilege Escalation, Initial Access, Credential Access, Lateral Movement, Defense Impairment, Collection | T1078, T1110, T1110.001, T1111, T1550.002, T1550.003, T1556, T1557, T1566.002, T1621 |
| 8. Regular Backups | Impact, Stealth, Persistence, Privilege Escalation, Initial Access | T1486, T1490, T1485, T1078 |

**Unmapped steps (2 of 67):** `2-1-2` Inventory installed applications, `6-1-2` Inventory OS versions. Both are deliberate — see the notes above.

---

## Change log for this document

- **26/07/2026 — rebased to ATT&CK v19.1 and curated for v1.8.**
  - Rebased from v14.1 to v19.1; replaced every Defense Evasion label with Stealth or Defense Impairment; replaced revoked `T1562` / `T1562.001` with `T1685`.
  - Corrected `T1562.001`, which had been captioned "Impair Defenses" (its name was "Disable or Modify Tools" even in v14).
  - Removed `T1518` from `2-1-2` and `T1082` from `6-1-2` — defender inventory is not adversary discovery.
  - Added `T1111`, `T1621`, `T1557` and `T1566.002` to Multi-factor Authentication, and stopped claiming FIDO2 prevents `T1566` Phishing outright.
  - Added `T1127` and `T1216` to `1-3-0`, `T1127` to `4-3-2`, `T1137.001` to `3-3-1`, `T1055` and `T1204.002` to `4-2-1`, `T1553.005` as a documented bypass on `3-1-0`.
  - Replaced the per-row Tactic column with a Note column; tactics now live once, in the technique catalogue.
  - Defined the four relationships precisely and re-applied them (`8-1-0` Support not Recover; `8-3-0` Detect not Support; `2-2-1` and `6-1-1` Support not Prevent).
  - Added `Step ID` join keys, the provenance disclaimer and this change log.
