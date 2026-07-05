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

    /// All steps in scope when targeting `level` (cumulative).
    func steps(upTo level: MaturityLevel) -> [ImplementationStep] {
        level.cumulativeLevels.flatMap { content(for: $0).steps }
    }
}

enum MaturityLevel: Int, CaseIterable, Hashable, Identifiable {
    case ml1 = 1
    case ml2 = 2
    case ml3 = 3

    var id: Int { rawValue }
    var shortName: String { "ML\(rawValue)" }
    var displayName: String { "Maturity Level \(rawValue)" }

    /// Levels included when this level is the target (cumulative: ML1...self).
    var cumulativeLevels: [MaturityLevel] {
        MaturityLevel.allCases.filter { $0.rawValue <= rawValue }
    }
}

struct MaturityLevelContent: Hashable {
    let summary: String
    let steps: [ImplementationStep]
    /// Non-nil when parts of this level cannot be met using Windows built-in tooling alone.
    let gapNote: String?
}

struct ImplementationStep: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    /// ISM control identifiers this step maps to (e.g. "ISM-1490"), from the
    /// ASD Essential Eight maturity model and ISM mapping (October 2024). Empty
    /// when no confident mapping exists.
    let ismControls: [String]
    /// Specific technical artefacts: GPO paths, registry keys, PowerShell, CMD.
    let technicalDetails: [String]

    init(
        id: String,
        title: String,
        description: String,
        ismControls: [String] = [],
        technicalDetails: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.ismControls = ismControls
        self.technicalDetails = technicalDetails
    }
}
