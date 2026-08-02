//
//  ATTACKCatalogue.swift
//  Essential 8 Knowledge Base
//
//  MITRE ATT&CK® Enterprise v19.1 (released 28/04/2026).
//  Technique IDs, names and tactics validated against the machine-readable
//  ATT&CK STIX bundle (mitre-attack/attack-stix-data, collection 19.1).
//  Re-verify on every ATT&CK major version bump (roughly April and October).
//  ATT&CK® is a registered trademark of The MITRE Corporation.
//

import Foundation

enum ATTACKCatalogue {
    static let attackVersion = "v19.1"
    static let attackVersionReleased = "28 April 2026"
    /// Publication year of the ATT&CK release reproduced above.
    static let attackCopyrightYear = "2026"

    static let all: [ATTACKTechnique] = [
        entry("T1003.001", "LSASS Memory", [.credentialAccess], "https://attack.mitre.org/techniques/T1003/001/"),
        entry("T1021", "Remote Services", [.lateralMovement], "https://attack.mitre.org/techniques/T1021/"),
        entry("T1055", "Process Injection", [.stealth, .privilegeEscalation], "https://attack.mitre.org/techniques/T1055/"),
        entry("T1059", "Command and Scripting Interpreter", [.execution], "https://attack.mitre.org/techniques/T1059/"),
        entry("T1059.001", "PowerShell", [.execution], "https://attack.mitre.org/techniques/T1059/001/"),
        entry("T1059.005", "Visual Basic", [.execution], "https://attack.mitre.org/techniques/T1059/005/"),
        entry("T1068", "Exploitation for Privilege Escalation", [.privilegeEscalation], "https://attack.mitre.org/techniques/T1068/"),
        entry("T1078", "Valid Accounts", [.stealth, .persistence, .privilegeEscalation, .initialAccess], "https://attack.mitre.org/techniques/T1078/"),
        entry("T1078.003", "Local Accounts", [.stealth, .persistence, .privilegeEscalation, .initialAccess], "https://attack.mitre.org/techniques/T1078/003/"),
        entry("T1110", "Brute Force", [.credentialAccess], "https://attack.mitre.org/techniques/T1110/"),
        entry("T1110.001", "Password Guessing", [.credentialAccess], "https://attack.mitre.org/techniques/T1110/001/"),
        entry("T1111", "Multi-Factor Authentication Interception", [.credentialAccess], "https://attack.mitre.org/techniques/T1111/"),
        entry("T1127", "Trusted Developer Utilities Proxy Execution", [.stealth, .execution], "https://attack.mitre.org/techniques/T1127/"),
        entry("T1137.001", "Office Template Macros", [.persistence], "https://attack.mitre.org/techniques/T1137/001/"),
        entry("T1189", "Drive-by Compromise", [.initialAccess], "https://attack.mitre.org/techniques/T1189/"),
        entry("T1190", "Exploit Public-Facing Application", [.initialAccess], "https://attack.mitre.org/techniques/T1190/"),
        entry("T1203", "Exploitation for Client Execution", [.execution], "https://attack.mitre.org/techniques/T1203/"),
        entry("T1204.002", "Malicious File", [.execution], "https://attack.mitre.org/techniques/T1204/002/"),
        entry("T1216", "System Script Proxy Execution", [.stealth], "https://attack.mitre.org/techniques/T1216/"),
        entry("T1218", "System Binary Proxy Execution", [.stealth], "https://attack.mitre.org/techniques/T1218/"),
        entry("T1485", "Data Destruction", [.impact], "https://attack.mitre.org/techniques/T1485/"),
        entry("T1486", "Data Encrypted for Impact", [.impact], "https://attack.mitre.org/techniques/T1486/"),
        entry("T1490", "Inhibit System Recovery", [.impact], "https://attack.mitre.org/techniques/T1490/"),
        entry("T1543.003", "Windows Service", [.persistence, .privilegeEscalation], "https://attack.mitre.org/techniques/T1543/003/"),
        entry("T1548.002", "Bypass User Account Control", [.privilegeEscalation], "https://attack.mitre.org/techniques/T1548/002/"),
        entry("T1550.002", "Pass the Hash", [.lateralMovement], "https://attack.mitre.org/techniques/T1550/002/"),
        entry("T1550.003", "Pass the Ticket", [.lateralMovement], "https://attack.mitre.org/techniques/T1550/003/"),
        entry("T1553.002", "Code Signing", [.defenseImpairment], "https://attack.mitre.org/techniques/T1553/002/"),
        entry("T1556", "Modify Authentication Process", [.defenseImpairment, .persistence, .credentialAccess], "https://attack.mitre.org/techniques/T1556/"),
        entry("T1557", "Adversary-in-the-Middle", [.credentialAccess, .collection], "https://attack.mitre.org/techniques/T1557/"),
        entry("T1566", "Phishing", [.initialAccess], "https://attack.mitre.org/techniques/T1566/"),
        entry("T1566.001", "Spearphishing Attachment", [.initialAccess], "https://attack.mitre.org/techniques/T1566/001/"),
        entry("T1566.002", "Spearphishing Link", [.initialAccess], "https://attack.mitre.org/techniques/T1566/002/"),
        entry("T1621", "Multi-Factor Authentication Request Generation", [.credentialAccess], "https://attack.mitre.org/techniques/T1621/"),
        entry("T1685", "Disable or Modify Tools", [.defenseImpairment], "https://attack.mitre.org/techniques/T1685/")
    ]

    static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func technique(_ id: String) -> ATTACKTechnique? { byID[id] }

    private static func entry(
        _ id: String, _ name: String, _ tactics: [ATTACKTactic], _ url: String
    ) -> ATTACKTechnique {
        ATTACKTechnique(id: id, name: name, tactics: tactics, url: URL(string: url)!)
    }
}
