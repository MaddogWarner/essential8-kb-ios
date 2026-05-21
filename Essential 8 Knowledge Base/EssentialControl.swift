//
//  EssentialControl.swift
//  Essential 8 Knowledge Base
//

import Foundation

struct EssentialControl: Identifiable, Hashable {
    let id: Int
    let name: String
    let iconSystemName: String
    let overview: String
    let ml0Description: String
    let ml1: MaturityLevelContent
    let ml2: MaturityLevelContent
    let ml3: MaturityLevelContent

    func content(for level: MaturityLevel) -> MaturityLevelContent {
        switch level {
        case .ml1: return ml1
        case .ml2: return ml2
        case .ml3: return ml3
        }
    }
}

enum MaturityLevel: Int, CaseIterable, Hashable, Identifiable {
    case ml1 = 1
    case ml2 = 2
    case ml3 = 3

    var id: Int { rawValue }
    var shortName: String { "ML\(rawValue)" }
    var displayName: String { "Maturity Level \(rawValue)" }
}

struct MaturityLevelContent: Hashable {
    let summary: String
    let steps: [ImplementationStep]
    /// Non-nil when parts of this level cannot be met using Windows built-in tooling alone.
    let gapNote: String?
}

struct ImplementationStep: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    /// Specific technical artefacts: GPO paths, registry keys, PowerShell, CMD.
    let technicalDetails: [String]
}
