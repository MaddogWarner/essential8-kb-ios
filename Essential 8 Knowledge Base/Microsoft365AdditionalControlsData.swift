//
//  Microsoft365AdditionalControlsData.swift
//  Essential 8 Knowledge Base
//

import Foundation

struct Microsoft365AdditionalProtection: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let coverage: String
    let basicSettings: [String]
}

enum Microsoft365AdditionalControlsData {
    /// M365 protections are licensed-product additions that apply across maturity levels;
    /// the level is included so coverage copy can match the page being viewed.
    static func protections(for controlID: Int, level: MaturityLevel, licenseMode: Microsoft365LicenseMode) -> [Microsoft365AdditionalProtection] {
        guard licenseMode != .none else { return [] }

        var protections = e3P1Protections(for: controlID, level: level)

        if licenseMode == .e3P2 || licenseMode == .e5 {
            protections.append(contentsOf: p2IdentityProtections(for: controlID, level: level))
        }

        if licenseMode == .e5 {
            protections.append(contentsOf: e5Protections(for: controlID, level: level))
        }

        return protections
    }

    private static func e3P1Protections(for controlID: Int, level: MaturityLevel) -> [Microsoft365AdditionalProtection] {
        switch controlID {
        case 1:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Endpoint P1 attack surface reduction",
                    coverage: "Partially supports Application Control \(level.shortName) by reducing common execution paths, but it does not replace AppLocker or WDAC allow-listing.",
                    basicSettings: [
                        "Microsoft Defender portal: Endpoints > Configuration management > Attack surface reduction rules",
                        "Enable ASR rules that block executable content from email, webmail and Office child processes",
                        "Use Intune endpoint security policies to deploy Defender Antivirus, firewall and attack surface reduction baselines"
                    ]
                )
            ]
        case 2:
            return [
                Microsoft365AdditionalProtection(
                    title: "Intune app inventory and update deployment",
                    coverage: "Partially supports Patch Applications \(level.shortName) by improving visibility and deployment control for managed apps.",
                    basicSettings: [
                        "Intune admin center: Apps > Monitor > Discovered apps",
                        "Deploy supported Microsoft Store, Win32 and Microsoft 365 Apps updates through Intune",
                        "Use device compliance reports to identify stale or unmanaged endpoints"
                    ]
                )
            ]
        case 3:
            return [
                Microsoft365AdditionalProtection(
                    title: "Cloud-managed Office macro controls",
                    coverage: "Supports Configure Microsoft Office Macros \(level.shortName) by applying Office policy settings through Intune instead of only Group Policy.",
                    basicSettings: [
                        "Intune admin center: Devices > Configuration > Settings catalog > Microsoft Office security settings",
                        "Block macros from running in Office files from the internet",
                        "Disable unsigned VBA macros and require trusted locations to be explicitly controlled"
                    ]
                )
            ]
        case 4:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Endpoint P1 web and network protection",
                    coverage: "Supports User Application Hardening \(level.shortName) by adding managed browser, network and endpoint hardening controls.",
                    basicSettings: [
                        "Microsoft Defender portal: Settings > Endpoints > Advanced features > Network protection = On",
                        "Deploy ASR rules for Office, script and executable abuse paths",
                        "Use Intune security baselines for Microsoft Edge and Defender Antivirus"
                    ]
                )
            ]
        case 5:
            return [
                Microsoft365AdditionalProtection(
                    title: "Entra ID P1 Conditional Access for administrator access",
                    coverage: "Partially supports Restrict Administrative Privileges \(level.shortName) by enforcing access conditions for cloud admin roles; it does not remove local admin rights by itself.",
                    basicSettings: [
                        "Entra admin center: Protection > Conditional Access > New policy",
                        "Require MFA for all administrator roles",
                        "Block legacy authentication and require compliant or hybrid joined devices for admin portals"
                    ]
                )
            ]
        case 6:
            return [
                Microsoft365AdditionalProtection(
                    title: "Intune update rings and compliance reporting",
                    coverage: "Supports Patch Operating Systems \(level.shortName) for enrolled Windows endpoints by managing update cadence and restart behaviour.",
                    basicSettings: [
                        "Intune admin center: Devices > Windows > Update rings for Windows 10 and later",
                        "Set quality update deferrals, deadlines and grace periods",
                        "Use compliance policies to mark devices non-compliant when minimum OS versions are not met"
                    ]
                )
            ]
        case 7:
            return [
                Microsoft365AdditionalProtection(
                    title: "Entra ID P1 Conditional Access MFA",
                    coverage: "Supports Multi-factor Authentication \(level.shortName) for Microsoft 365 and Entra-integrated apps.",
                    basicSettings: [
                        "Entra admin center: Protection > Conditional Access > New policy",
                        "Require MFA for administrators and users accessing Microsoft 365 cloud apps",
                        "Exclude emergency access accounts and monitor sign-in logs during rollout"
                    ]
                )
            ]
        case 8:
            return [
                Microsoft365AdditionalProtection(
                    title: "OneDrive known folder move and cloud retention",
                    coverage: "Partially supports Regular Backups \(level.shortName) for user files stored in Microsoft 365, but it is not a full endpoint or server backup replacement.",
                    basicSettings: [
                        "Intune admin center: Settings catalog > OneDrive > Silently move Windows known folders to OneDrive",
                        "Microsoft Purview portal: Data lifecycle management > Retention policies for SharePoint and OneDrive",
                        "Keep separate backup coverage for servers, line-of-business data and non-synced endpoint paths"
                    ]
                )
            ]
        default:
            return []
        }
    }

    private static func p2IdentityProtections(for controlID: Int, level: MaturityLevel) -> [Microsoft365AdditionalProtection] {
        switch controlID {
        case 5:
            return [
                Microsoft365AdditionalProtection(
                    title: "Entra ID P2 Privileged Identity Management",
                    coverage: "Supports Restrict Administrative Privileges \(level.shortName) for cloud roles by making privileged access just-in-time, time-bound and approval-aware.",
                    basicSettings: [
                        "Entra admin center: Identity governance > Privileged Identity Management",
                        "Make admin role assignments eligible instead of permanent",
                        "Require MFA, justification and approval for high-impact role activation"
                    ]
                )
            ]
        case 7:
            return [
                Microsoft365AdditionalProtection(
                    title: "Entra ID P2 risk-based access controls",
                    coverage: "Supports Multi-factor Authentication \(level.shortName) by adapting MFA and access decisions to user and sign-in risk.",
                    basicSettings: [
                        "Entra admin center: Protection > Conditional Access > User risk and sign-in risk policies",
                        "Require phishing-resistant MFA or password reset for high-risk users",
                        "Monitor Identity Protection risk detections before enforcing tenant-wide policies"
                    ]
                )
            ]
        default:
            return []
        }
    }

    private static func e5Protections(for controlID: Int, level: MaturityLevel) -> [Microsoft365AdditionalProtection] {
        switch controlID {
        case 1:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Endpoint P2 investigation and hunting",
                    coverage: "Adds detection, investigation and response around Application Control \(level.shortName), but WDAC or AppLocker remain the enforcement controls.",
                    basicSettings: [
                        "Microsoft Defender portal: Endpoints > Advanced features > Enable EDR in block mode where appropriate",
                        "Use advanced hunting to find script, LOLBin and unsigned executable activity",
                        "Review device timeline and incidents for blocked or suspicious execution attempts"
                    ]
                )
            ]
        case 2:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender Vulnerability Management core capabilities",
                    coverage: "Supports Patch Applications \(level.shortName) with continuous software inventory, exposure visibility and security recommendations.",
                    basicSettings: [
                        "Microsoft Defender portal: Endpoints > Vulnerability management > Recommendations",
                        "Prioritise exposed applications with known exploited vulnerabilities",
                        "Track remediation status after app updates are deployed"
                    ]
                )
            ]
        case 3:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Office 365 Plan 2 attachment and link protection",
                    coverage: "Adds email and collaboration protection around macro-borne threats for Configure Microsoft Office Macros \(level.shortName).",
                    basicSettings: [
                        "Microsoft Defender portal: Email & collaboration > Policies & rules > Threat policies",
                        "Enable Safe Attachments and Safe Links using Standard or Strict preset security policies",
                        "Use Threat Explorer and AIR to investigate malicious Office documents"
                    ]
                )
            ]
        case 4:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Cloud Apps session and app governance",
                    coverage: "Partially supports User Application Hardening \(level.shortName) by controlling risky cloud app sessions and unsanctioned SaaS usage.",
                    basicSettings: [
                        "Microsoft Defender portal: Cloud Apps > Policies > App discovery policies",
                        "Sanction approved cloud apps and mark risky apps as unsanctioned",
                        "Use Conditional Access App Control for monitored or blocked browser sessions"
                    ]
                )
            ]
        case 5:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Identity privileged account monitoring",
                    coverage: "Adds detection around Restrict Administrative Privileges \(level.shortName) by monitoring identity abuse and lateral movement signals.",
                    basicSettings: [
                        "Microsoft Defender portal: Settings > Identities > Sensors",
                        "Deploy Defender for Identity sensors to domain controllers",
                        "Review identity security posture recommendations for privileged accounts"
                    ]
                )
            ]
        case 6:
            return [
                Microsoft365AdditionalProtection(
                    title: "Defender for Endpoint P2 OS exposure management",
                    coverage: "Supports Patch Operating Systems \(level.shortName) by highlighting missing OS updates and exposed devices.",
                    basicSettings: [
                        "Microsoft Defender portal: Endpoints > Vulnerability management > Weaknesses",
                        "Filter recommendations by operating system and exposed devices",
                        "Use remediation tasks to coordinate patching with endpoint administrators"
                    ]
                )
            ]
        case 7:
            return [
                Microsoft365AdditionalProtection(
                    title: "E5 identity and cloud-app signal integration",
                    coverage: "Enhances Multi-factor Authentication \(level.shortName) with Entra ID P2 risk, Defender for Cloud Apps session controls and Defender XDR incident context.",
                    basicSettings: [
                        "Use Conditional Access policies with sign-in risk, user risk and session controls",
                        "Require phishing-resistant MFA for administrators and high-risk access paths",
                        "Review Defender XDR incidents that combine identity, endpoint and cloud app signals"
                    ]
                )
            ]
        case 8:
            return [
                Microsoft365AdditionalProtection(
                    title: "Purview and audit support for Microsoft 365 data recovery",
                    coverage: "Partially supports Regular Backups \(level.shortName) for Microsoft 365 data governance and investigation, but does not replace immutable backup storage.",
                    basicSettings: [
                        "Microsoft Purview portal: Data lifecycle management > Retention labels and policies",
                        "Enable audit search and review high-impact deletion or exfiltration events",
                        "Use separate backup products or storage controls for immutable recovery requirements"
                    ]
                )
            ]
        default:
            return []
        }
    }
}
