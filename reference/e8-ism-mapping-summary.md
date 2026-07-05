# Essential Eight ISM Mapping Summary

Source: ASD Essential Eight maturity model and ISM mapping, October 2024 (`reference/e8-ism-mapping-oct2024.pdf`).

## Application Control

- Enable the Application Identity service: ISM-0843, ISM-1870, ISM-1657
- Create AppLocker default rules: ISM-0843, ISM-1657
- Block execution from user-writable locations: ISM-1870, ISM-1657
- Log block events: empty - the ASD row is for centrally logged allowed and blocked application control events; this step only enables local AppLocker event generation.
- Extend AppLocker enforcement to servers: ISM-1490, ISM-1870, ISM-1871, ISM-1657
- Deploy Windows Defender Application Control (WDAC): ISM-1490, ISM-1871, ISM-1657
- Forward AppLocker / WDAC events centrally: ISM-1660
- Apply Microsoft's recommended block rules: ISM-1544
- Enable the vulnerable driver blocklist: ISM-1659
- Enforce Memory Integrity (HVCI): ISM-1896

## Patch Applications

- Enable Microsoft Update for Office: ISM-1691
- Enable Microsoft Edge auto-update: ISM-1691
- Inventory installed applications: ISM-1807
- Uninstall unsupported applications: ISM-1704
- Tighten Office and Edge update cadence: ISM-1691
- Enforce restart deadlines: ISM-1691, ISM-1693
- Emergency patch deployment: ISM-1692

> Review correction (Claude, 05/07/2026): removed ISM-1876 and ISM-1690 from the two steps above — those identifiers map to *online services* patching requirements, which endpoint restart-deadline and WSUS/WUfB deployment steps do not serve.

## Configure Microsoft Office Macro Settings

- Block macros from the internet (Mark-of-the-Web): ISM-1488
- Disable VBA macros without notification: ISM-1671
- Lock down the Trust Center: ISM-1489
- Allow only digitally signed macros: ISM-1674, ISM-1675
- Enable AMSI scanning of macros: ISM-1672
- Enable VBA macro logging: empty - the ASD mapping has no Microsoft Office macro execution logging row.
- Require V3 (XML-DSig) signatures: ISM-1891
- Restrict write access to Trusted Locations: ISM-1487

## User Application Hardening

- Disable Internet Explorer 11: ISM-1654
- Block Java in Microsoft Edge: ISM-1486
- Block web advertisements: ISM-1485, ISM-1585
- Enable PowerShell logging: ISM-1623
- Deploy Attack Surface Reduction rules: ISM-1667, ISM-1668, ISM-1669
- Enable command-line process auditing: ISM-1889
- Remove PowerShell v2: ISM-1621
- Enforce Constrained Language Mode: ISM-1622
- Remove legacy .NET Framework: ISM-1655

## Restrict Administrative Privileges

- Remove standard users from local Administrators: ISM-1508
- Deploy Windows LAPS: ISM-1685
- Block internet / email for privileged accounts: ISM-1175, ISM-1883
- Enable Credential Guard: ISM-1686
- Protect LSASS: ISM-1861
- Apply Just Enough Administration (JEA): ISM-1508
- Add privileged accounts to Protected Users: empty - the ASD mapping has rows for related credential protections, but no direct Protected Users group row.
- Privileged Access Workstation (PAW): ISM-1898, ISM-1380, ISM-1689
- Audit privileged account use: ISM-1509, ISM-1650

## Patch Operating Systems

- Configure Windows Update for Business: ISM-1877, ISM-1694, ISM-1695
- Enforce a quality-update deadline: ISM-1877, ISM-1694, ISM-1695
- Inventory OS versions: ISM-1807, ISM-1501
- Tighten deferrals and deadlines: ISM-1877, ISM-1694, ISM-1695
- Include driver updates from Windows Update: ISM-1697
- Expedite critical patches: ISM-1877, ISM-1696
- Stay on N or N-1 Windows feature releases: ISM-1407, ISM-1501

## Multi-factor Authentication

- Enable Windows Hello for Business: ISM-0974, ISM-1401
- Enforce PIN complexity: ISM-1401
- Enable smart-card support for legacy logon: ISM-0974, ISM-1682
- Require MFA for all privileged accounts: ISM-1173, ISM-1401, ISM-1682
- Set SmartcardLogonRequired on admin accounts: ISM-1173, ISM-1682
- Deploy WHfB with certificate trust: ISM-1401, ISM-1682
- Enable FIDO2 security key sign-in: ISM-1682
- Log and forward authentication events: ISM-1683

## Regular Backups

- Install Windows Server Backup: ISM-1511, ISM-1811
- Schedule daily backups: ISM-1511, ISM-1810, ISM-1811
- Restrict access to backup destinations: ISM-1812, ISM-1814
- Enable Volume Shadow Copies for file servers: ISM-1511, ISM-1810
- Separate backup credentials: ISM-1705, ISM-1707
- Restrict user access to their own backups: ISM-1813, ISM-1814
- Use ReFS with integrity streams for backup volumes: ISM-1811
- Lock down with role separation: ISM-1705, ISM-1706, ISM-1707, ISM-1708
- Offline / air-gapped copy: ISM-1811
