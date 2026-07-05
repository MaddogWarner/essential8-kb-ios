//
//  ProgressStore.swift
//  Essential 8 Knowledge Base
//

import Combine
import Foundation

enum StepState: String, Codable, CaseIterable {
    case notImplemented = "Not Implemented"
    case implemented = "Implemented"
    case notApplicable = "Not Applicable"
}

struct StepStatus: Codable, Equatable, Hashable {
    var state: StepState
    var reason: String?
}

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    private let legacyKey = "e8kb.stepProgress"
    private let key = "e8kb.stepProgressDict"

    @Published private(set) var statuses: [String: StepStatus] = [:]

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: StepStatus].self, from: data) {
            self.statuses = decoded
        } else {
            // Check legacy and migrate
            let savedLegacy = UserDefaults.standard.stringArray(forKey: legacyKey) ?? []
            var migrated: [String: StepStatus] = [:]
            for id in savedLegacy {
                migrated[id] = StepStatus(state: .implemented, reason: nil)
            }
            self.statuses = migrated
            if !migrated.isEmpty {
                save()
            }
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(statuses) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
        objectWillChange.send()
    }

    func resetAll() {
        statuses.removeAll()
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
        UserDefaults.standard.removeObject(forKey: "microsoft365LicenseMode")
        UserDefaults.standard.removeObject(forKey: "targetMaturityLevel")
        UserDefaults.standard.removeObject(forKey: "showSplashOnStartup")
        UserDefaults.standard.removeObject(forKey: "referenceOnlyMode")
        save()
    }

    func status(for stepID: String) -> StepStatus {
        statuses[stepID] ?? StepStatus(state: .notImplemented, reason: nil)
    }

    func setStatus(_ state: StepState, reason: String?, for stepID: String) {
        if state == .notImplemented {
            statuses.removeValue(forKey: stepID)
        } else {
            statuses[stepID] = StepStatus(state: state, reason: reason)
        }
        save()
    }

    func toggle(_ stepID: String) {
        if isCompleted(stepID) {
            setStatus(.notImplemented, reason: nil, for: stepID)
        } else {
            setStatus(.implemented, reason: nil, for: stepID)
        }
    }

    func isCompleted(_ stepID: String) -> Bool {
        status(for: stepID).state == .implemented
    }

    func isNotApplicable(_ stepID: String) -> Bool {
        status(for: stepID).state == .notApplicable
    }

    func completedCount(for steps: [ImplementationStep]) -> Int {
        steps.filter { isCompleted($0.id) }.count
    }

    func notApplicableCount(for steps: [ImplementationStep]) -> Int {
        steps.filter { isNotApplicable($0.id) }.count
    }

    func compliancePercentage(for steps: [ImplementationStep]) -> Double {
        let total = steps.count
        if total == 0 { return 100.0 }
        let na = notApplicableCount(for: steps)
        let comp = completedCount(for: steps)
        let denom = total - na
        if denom <= 0 { return 100.0 }
        return Double(comp) / Double(denom) * 100.0
    }

    func isControlComplete(_ control: EssentialControl, upTo target: MaturityLevel) -> Bool {
        let allSteps = control.steps(upTo: target)
        if allSteps.isEmpty { return false }
        return allSteps.allSatisfy { step in
            let st = status(for: step.id).state
            return st == .implemented || st == .notApplicable
        }
    }
}
