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

struct AuditEntry: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let timestamp: Date
    let previousState: StepState
    let newState: StepState
    let note: String?
}

struct Profile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    let createdAt: Date
    var stepProgress: [String: StepStatus]
    var auditTrail: [String: [AuditEntry]]
    var targetMaturityLevelRaw: Int
    var osScopeFilterRaw: String
    var microsoft365LicenseModeRaw: String

    static func newDefault(name: String = "Default") -> Profile {
        Profile(
            id: UUID(),
            name: name,
            createdAt: Date(),
            stepProgress: [:],
            auditTrail: [:],
            targetMaturityLevelRaw: MaturityLevel.ml3.rawValue,
            osScopeFilterRaw: OSScope.both.rawValue,
            microsoft365LicenseModeRaw: Microsoft365LicenseMode.none.rawValue
        )
    }
}

let auditEntriesPerStepCap = 200

/// Device-level UserDefaults keys shared across all profiles.
///
/// Any new global persisted setting must be added here and to
/// `GlobalSettingsBackup`. Profile assessment context belongs on `Profile`.
enum GlobalSettingsKey: String, CaseIterable {
    case showSplashOnStartup
    case referenceOnlyMode
    case deepAuditEnabled
    case multiProfileEnabled
}

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    private let legacyProgressKey = "e8kb.stepProgress"
    private let progressDictionaryKey = "e8kb.stepProgressDict"
    private let profilesKey = "e8kb.profiles"
    private let activeProfileKey = "e8kb.activeProfileID"
    private let defaults: UserDefaults

    @Published private(set) var profiles: [Profile]
    @Published private(set) var activeProfileID: UUID

    var activeProfile: Profile { profiles[activeIndex()] }
    var statuses: [String: StepStatus] { activeProfile.stepProgress }

    var targetMaturityLevel: MaturityLevel {
        get { MaturityLevel(rawValue: activeProfile.targetMaturityLevelRaw) ?? .ml3 }
        set { mutateActiveProfile { $0.targetMaturityLevelRaw = newValue.rawValue } }
    }

    var osScope: OSScope {
        get { OSScope(rawValue: activeProfile.osScopeFilterRaw) ?? .both }
        set { mutateActiveProfile { $0.osScopeFilterRaw = newValue.rawValue } }
    }

    var licenseMode: Microsoft365LicenseMode {
        get { Microsoft365LicenseMode(rawValue: activeProfile.microsoft365LicenseModeRaw) ?? .none }
        set { mutateActiveProfile { $0.microsoft365LicenseModeRaw = newValue.rawValue } }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([Profile].self, from: data),
           !decoded.isEmpty,
           Set(decoded.map(\.id)).count == decoded.count {
            profiles = decoded
            let storedID = defaults.string(forKey: activeProfileKey).flatMap(UUID.init(uuidString:))
            activeProfileID = storedID.flatMap { id in decoded.contains { $0.id == id } ? id : nil } ?? decoded[0].id
            persist()
            return
        }

        var profile = Profile.newDefault()
        if let data = defaults.data(forKey: progressDictionaryKey),
           let decoded = try? JSONDecoder().decode([String: StepStatus].self, from: data) {
            profile.stepProgress = decoded
        } else {
            for id in defaults.stringArray(forKey: legacyProgressKey) ?? [] {
                profile.stepProgress[id] = StepStatus(state: .implemented, reason: nil)
            }
        }
        if let raw = defaults.object(forKey: "targetMaturityLevel") as? Int,
           MaturityLevel(rawValue: raw) != nil {
            profile.targetMaturityLevelRaw = raw
        }
        if let raw = defaults.string(forKey: "osScopeFilter"), OSScope(rawValue: raw) != nil {
            profile.osScopeFilterRaw = raw
        }
        if let raw = defaults.string(forKey: "microsoft365LicenseMode"),
           Microsoft365LicenseMode(rawValue: raw) != nil {
            profile.microsoft365LicenseModeRaw = raw
        }
        profiles = [profile]
        activeProfileID = profile.id
        persist()
    }

    private func activeIndex() -> Int {
        profiles.firstIndex { $0.id == activeProfileID } ?? 0
    }

    private func mutateActiveProfile(_ mutation: (inout Profile) -> Void) {
        mutation(&profiles[activeIndex()])
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            defaults.set(encoded, forKey: profilesKey)
        }
        defaults.set(activeProfileID.uuidString, forKey: activeProfileKey)
    }

    func resetAll() {
        let profile = Profile.newDefault()
        profiles = [profile]
        activeProfileID = profile.id
        defaults.removeObject(forKey: profilesKey)
        defaults.removeObject(forKey: activeProfileKey)
        defaults.removeObject(forKey: progressDictionaryKey)
        defaults.removeObject(forKey: legacyProgressKey)
        GlobalSettingsKey.allCases.forEach { defaults.removeObject(forKey: $0.rawValue) }
        ["targetMaturityLevel", "osScopeFilter", "microsoft365LicenseMode"].forEach {
            defaults.removeObject(forKey: $0)
        }
        persist()
    }

    func switchProfile(to id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileID = id
        persist()
    }

    @discardableResult
    func createProfile(named name: String) -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = Profile.newDefault(name: trimmed.isEmpty ? "New Profile" : trimmed)
        profiles.append(profile)
        persist()
        return profile.id
    }

    func renameProfile(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = trimmed
        persist()
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles.remove(at: index)
        if activeProfileID == id {
            activeProfileID = profiles[0].id
        }
        persist()
    }

    func status(for stepID: String) -> StepStatus {
        activeProfile.stepProgress[stepID] ?? StepStatus(state: .notImplemented, reason: nil)
    }

    func setStatus(_ state: StepState, reason: String?, for stepID: String) {
        setStatus(state, reason: reason, note: nil, for: stepID)
    }

    func setStatus(_ state: StepState, reason: String?, note: String?, for stepID: String) {
        let previous = status(for: stepID).state
        mutateActiveProfile { profile in
            if state == .notImplemented {
                profile.stepProgress.removeValue(forKey: stepID)
            } else {
                profile.stepProgress[stepID] = StepStatus(state: state, reason: reason)
            }

            guard defaults.bool(forKey: GlobalSettingsKey.deepAuditEnabled.rawValue), state != previous else { return }
            let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
            let effectiveNote = state == .notApplicable ? (trimmedNote ?? reason) : trimmedNote
            let storedNote = effectiveNote.flatMap { $0.isEmpty ? nil : $0 }
            profile.auditTrail[stepID, default: []].append(
                AuditEntry(
                    id: UUID(),
                    timestamp: Date(),
                    previousState: previous,
                    newState: state,
                    note: storedNote
                )
            )
            if let count = profile.auditTrail[stepID]?.count, count > auditEntriesPerStepCap {
                profile.auditTrail[stepID]?.removeFirst(count - auditEntriesPerStepCap)
            }
        }
    }

    func auditEntries(for stepID: String) -> [AuditEntry] {
        Array((activeProfile.auditTrail[stepID] ?? []).reversed())
    }

    func toggle(_ stepID: String) {
        setStatus(isCompleted(stepID) ? .notImplemented : .implemented, reason: nil, for: stepID)
    }

    func isCompleted(_ stepID: String) -> Bool { status(for: stepID).state == .implemented }
    func isNotApplicable(_ stepID: String) -> Bool { status(for: stepID).state == .notApplicable }
    func completedCount(for steps: [ImplementationStep]) -> Int { steps.filter { isCompleted($0.id) }.count }
    func notApplicableCount(for steps: [ImplementationStep]) -> Int { steps.filter { isNotApplicable($0.id) }.count }

    func compliancePercentage(for steps: [ImplementationStep]) -> Double {
        guard !steps.isEmpty else { return 100 }
        let denominator = steps.count - notApplicableCount(for: steps)
        guard denominator > 0 else { return 100 }
        return Double(completedCount(for: steps)) / Double(denominator) * 100
    }

    func isControlComplete(_ control: EssentialControl, upTo target: MaturityLevel, scope: OSScope) -> Bool {
        let steps = control.steps(upTo: target, scope: scope)
        guard !steps.isEmpty else { return false }
        return steps.allSatisfy {
            let state = status(for: $0.id).state
            return state == .implemented || state == .notApplicable
        }
    }

    func exportActiveProfile() throws -> BackupFile {
        BackupFile(
            schemaVersion: BackupFile.currentSchemaVersion,
            appVersion: AppInformation.marketingVersion,
            exportedAt: Date(),
            profiles: [activeProfile],
            globalSettings: nil
        )
    }

    func exportAllProfiles() throws -> BackupFile {
        BackupFile(
            schemaVersion: BackupFile.currentSchemaVersion,
            appVersion: AppInformation.marketingVersion,
            exportedAt: Date(),
            profiles: profiles,
            globalSettings: GlobalSettingsBackup(
                showSplashOnStartup: defaults.object(forKey: GlobalSettingsKey.showSplashOnStartup.rawValue) as? Bool,
                referenceOnlyMode: defaults.object(forKey: GlobalSettingsKey.referenceOnlyMode.rawValue) as? Bool,
                deepAuditEnabled: defaults.object(forKey: GlobalSettingsKey.deepAuditEnabled.rawValue) as? Bool,
                multiProfileEnabled: defaults.object(forKey: GlobalSettingsKey.multiProfileEnabled.rawValue) as? Bool
            )
        )
    }

    func importAsNewProfile(_ backup: BackupFile) {
        guard !backup.profiles.isEmpty else { return }
        let existingNames = Set(profiles.map(\.name))
        let imported = backup.profiles.map { source in
            var name = source.name
            if existingNames.contains(name) { name += " (imported)" }
            return Profile(
                id: UUID(), name: name, createdAt: source.createdAt,
                stepProgress: source.stepProgress, auditTrail: source.auditTrail,
                targetMaturityLevelRaw: source.targetMaturityLevelRaw,
                osScopeFilterRaw: source.osScopeFilterRaw,
                microsoft365LicenseModeRaw: source.microsoft365LicenseModeRaw
            )
        }
        profiles.append(contentsOf: imported)
        activeProfileID = imported[0].id
        if profiles.count > 1 {
            defaults.set(true, forKey: GlobalSettingsKey.multiProfileEnabled.rawValue)
        }
        persist()
    }

    func importFullDevice(_ backup: BackupFile) {
        guard !backup.profiles.isEmpty, Set(backup.profiles.map(\.id)).count == backup.profiles.count else { return }
        profiles = backup.profiles
        activeProfileID = profiles[0].id
        if let settings = backup.globalSettings {
            apply(settings.showSplashOnStartup, key: .showSplashOnStartup)
            apply(settings.referenceOnlyMode, key: .referenceOnlyMode)
            apply(settings.deepAuditEnabled, key: .deepAuditEnabled)
            apply(settings.multiProfileEnabled, key: .multiProfileEnabled)
        }
        if profiles.count > 1 {
            defaults.set(true, forKey: GlobalSettingsKey.multiProfileEnabled.rawValue)
        }
        persist()
    }

    private func apply(_ value: Bool?, key: GlobalSettingsKey) {
        if let value { defaults.set(value, forKey: key.rawValue) }
        else { defaults.removeObject(forKey: key.rawValue) }
    }
}
