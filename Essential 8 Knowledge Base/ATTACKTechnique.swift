//
//  ATTACKTechnique.swift
//  Essential 8 Knowledge Base
//

import Foundation

/// ATT&CK Enterprise tactics, in v19.1 matrix order. Only the tactics reachable
/// from this app's mappings are modelled; `allCases` order is the display order.
enum ATTACKTactic: String, CaseIterable, Codable, Hashable, Identifiable {
    case initialAccess = "Initial Access"
    case execution = "Execution"
    case persistence = "Persistence"
    case privilegeEscalation = "Privilege Escalation"
    case stealth = "Stealth"
    case defenseImpairment = "Defense Impairment"
    case credentialAccess = "Credential Access"
    case lateralMovement = "Lateral Movement"
    case collection = "Collection"
    case impact = "Impact"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

/// How an implementation step relates to an adversary technique.
/// Definitions are binding — see `mitreattacke8.md`.
enum ATTACKRelationship: String, CaseIterable, Codable, Hashable, Identifiable {
    /// Stops the technique succeeding, or removes the capability it depends on.
    case prevent = "Prevent"
    /// Produces the telemetry that reveals the technique. Does not stop it.
    case detect = "Detect"
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
