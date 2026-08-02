//
//  ATTACKCoverage.swift
//  Essential 8 Knowledge Base
//

struct TechniqueCoverage: Identifiable, Hashable {
    let technique: ATTACKTechnique
    let contributingTotal: Int
    let contributingImplemented: Int
    let supportingTotal: Int
    let isIndirectOnly: Bool
    let isNotApplicable: Bool

    var id: String { technique.id }

    var fraction: Double? {
        guard contributingTotal > 0 else { return nil }
        return Double(contributingImplemented) / Double(contributingTotal)
    }

    var status: CoverageStatus {
        if isIndirectOnly { return .indirect }
        if isNotApplicable { return .notApplicable }
        if contributingImplemented == contributingTotal { return .covered }
        if contributingImplemented > 0 { return .partial }
        return .notCovered
    }
}

enum CoverageStatus: Hashable {
    case covered
    case partial
    case notCovered
    case indirect
    case notApplicable
}

enum ATTACKCoverageCalculator {
    /// Every step ID in scope for the store's target maturity level and OS scope.
    /// Hoisted out of `coverage(for:store:)` so a whole-catalogue pass builds it once
    /// instead of once per technique.
    private static func inScopeStepIDs(store: ProgressStore) -> Set<String> {
        Set(
            EssentialControlsData.all.flatMap {
                $0.steps(upTo: store.targetMaturityLevel, scope: store.osScope)
            }.map(\.id)
        )
    }

    static func coverage(for technique: ATTACKTechnique, store: ProgressStore) -> TechniqueCoverage? {
        coverage(for: technique, store: store, inScopeStepIDs: inScopeStepIDs(store: store))
    }

    private static func coverage(
        for technique: ATTACKTechnique, store: ProgressStore, inScopeStepIDs: Set<String>
    ) -> TechniqueCoverage? {
        let mappings = ATTACKMappingData.mappings(forTechnique: technique.id)
        let inScopeMappings = mappings.filter { inScopeStepIDs.contains($0.stepID) }
        guard !inScopeMappings.isEmpty else { return nil }

        let contributingIDs = Set(
            inScopeMappings.filter { $0.relationships.contains(where: \.countsTowardCoverage) }.map(\.stepID)
        )
        let supportingIDs = Set(
            inScopeMappings.filter { $0.relationships.contains(.support) }.map(\.stepID)
        )
        let applicableContributing = contributingIDs.filter { !store.isNotApplicable($0) }
        let applicableSupporting = supportingIDs.filter { !store.isNotApplicable($0) }

        return TechniqueCoverage(
            technique: technique,
            contributingTotal: applicableContributing.count,
            contributingImplemented: applicableContributing.filter { store.isCompleted($0) }.count,
            supportingTotal: applicableSupporting.count,
            isIndirectOnly: contributingIDs.isEmpty,
            isNotApplicable: !contributingIDs.isEmpty && applicableContributing.isEmpty
        )
    }

    static func allCoverage(store: ProgressStore) -> [TechniqueCoverage] {
        let stepIDs = inScopeStepIDs(store: store)
        return ATTACKCatalogue.all.compactMap {
            coverage(for: $0, store: store, inScopeStepIDs: stepIDs)
        }
    }

    static func techniques(forControl controlID: Int, store: ProgressStore) -> [ATTACKTechnique] {
        guard let control = EssentialControlsData.all.first(where: { $0.id == controlID }) else { return [] }
        let stepIDs = Set(control.steps(upTo: store.targetMaturityLevel, scope: store.osScope).map(\.id))
        let techniqueIDs = Set(
            ATTACKMappingData.all.filter { stepIDs.contains($0.stepID) }.map(\.techniqueID)
        )
        return ATTACKCatalogue.all.filter { techniqueIDs.contains($0.id) }
    }

    static func grouped(
        store: ProgressStore
    ) -> [(tactic: ATTACKTactic, coverage: [TechniqueCoverage])] {
        grouped(from: allCoverage(store: store))
    }

    static func grouped(
        store: ProgressStore, controlFilter: Int?
    ) -> [(tactic: ATTACKTactic, coverage: [TechniqueCoverage])] {
        guard let controlFilter else { return grouped(store: store) }
        let allowed = Set(techniques(forControl: controlFilter, store: store).map(\.id))
        return grouped(from: allCoverage(store: store).filter { allowed.contains($0.id) })
    }

    private static func grouped(
        from coverage: [TechniqueCoverage]
    ) -> [(tactic: ATTACKTactic, coverage: [TechniqueCoverage])] {
        ATTACKTactic.allCases.compactMap { tactic in
            let matches = coverage.filter { $0.technique.tactics.contains(tactic) }
            return matches.isEmpty ? nil : (tactic, matches)
        }
    }
}
