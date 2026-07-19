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

/// Every UserDefaults settings key the app persists.
///
/// ── RULE FOR ALL FUTURE VERSIONS ─────────────────────────────────────
/// Any new feature that persists data MUST add its key here AND extend
/// BackupSettings + exportBackup()/importBackup(). The
/// testBackupCoversAllPersistedKeys unit test fails if the registry and
/// BackupSettings drift apart. Step progress (e8kb.stepProgressDict) is
/// handled separately as the stepProgress payload.
/// ─────────────────────────────────────────────────────────────────────
enum PersistedSettingsKey: String, CaseIterable {
    case microsoft365LicenseMode
    case targetMaturityLevel
    case showSplashOnStartup
    case referenceOnlyMode
    case osScopeFilter
}

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    private let legacyKey = "e8kb.stepProgress"
    private let key = "e8kb.stepProgressDict"
    private let defaults: UserDefaults

    @Published private(set) var statuses: [String: StepStatus] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: StepStatus].self, from: data) {
            self.statuses = decoded
        } else {
            // Check legacy and migrate
            let savedLegacy = defaults.stringArray(forKey: legacyKey) ?? []
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
            defaults.set(encoded, forKey: key)
        }
        objectWillChange.send()
    }

    func resetAll() {
        statuses.removeAll()
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyKey)
        PersistedSettingsKey.allCases.forEach { defaults.removeObject(forKey: $0.rawValue) }
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

    func isControlComplete(_ control: EssentialControl, upTo target: MaturityLevel, scope: OSScope) -> Bool {
        let allSteps = control.steps(upTo: target, scope: scope)
        if allSteps.isEmpty { return false }
        return allSteps.allSatisfy { step in
            let st = status(for: step.id).state
            return st == .implemented || st == .notApplicable
        }
    }

    func exportBackup() throws -> BackupFile {
        BackupFile(
            schemaVersion: BackupFile.currentSchemaVersion,
            appVersion: AppInformation.marketingVersion,
            exportedAt: Date(),
            stepProgress: statuses,
            settings: BackupSettings(
                microsoft365LicenseMode: defaults.string(forKey: PersistedSettingsKey.microsoft365LicenseMode.rawValue),
                targetMaturityLevel: defaults.object(forKey: PersistedSettingsKey.targetMaturityLevel.rawValue) as? Int,
                showSplashOnStartup: defaults.object(forKey: PersistedSettingsKey.showSplashOnStartup.rawValue) as? Bool,
                referenceOnlyMode: defaults.object(forKey: PersistedSettingsKey.referenceOnlyMode.rawValue) as? Bool,
                osScopeFilter: defaults.string(forKey: PersistedSettingsKey.osScopeFilter.rawValue)
            )
        )
    }

    func importBackup(_ backup: BackupFile) {
        statuses = backup.stepProgress
        PersistedSettingsKey.allCases.forEach { defaults.removeObject(forKey: $0.rawValue) }
        set(backup.settings.microsoft365LicenseMode, for: .microsoft365LicenseMode)
        set(backup.settings.targetMaturityLevel, for: .targetMaturityLevel)
        set(backup.settings.showSplashOnStartup, for: .showSplashOnStartup)
        set(backup.settings.referenceOnlyMode, for: .referenceOnlyMode)
        set(backup.settings.osScopeFilter, for: .osScopeFilter)
        save()
    }

    private func set(_ value: Any?, for key: PersistedSettingsKey) {
        if let value {
            defaults.set(value, forKey: key.rawValue)
        }
    }
}
