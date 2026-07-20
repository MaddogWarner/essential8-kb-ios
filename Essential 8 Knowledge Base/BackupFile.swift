//
//  BackupFile.swift
//  Essential 8 Knowledge Base
//

import Foundation

enum BackupError: LocalizedError {
    case fileTooLarge
    case unsupportedSchema(Int)
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "The selected backup is larger than the 5 MB safety limit. Export profiles individually if an all-profiles backup is too large."
        case .unsupportedSchema(let version):
            return "This backup uses schema version \(version). Update the app before importing it."
        case .invalidFile:
            return "The selected file is not a valid Essential 8 backup."
        }
    }
}

struct BackupFile: Codable {
    static let currentSchemaVersion = 2
    static let minimumSupportedSchema = 1
    static let maximumFileSize = 5_242_880

    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let profiles: [Profile]
    let globalSettings: GlobalSettingsBackup?

    static func encode(_ backup: BackupFile) throws -> Data {
        var capped = backup
        capped = BackupFile(
            schemaVersion: capped.schemaVersion,
            appVersion: capped.appVersion,
            exportedAt: capped.exportedAt,
            profiles: capped.profiles.map { profile in
                var copy = profile
                copy.auditTrail = copy.auditTrail.mapValues { Array($0.suffix(auditEntriesPerStepCap)) }
                return copy
            },
            globalSettings: capped.globalSettings
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(capped)
        guard data.count <= maximumFileSize else { throw BackupError.fileTooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> BackupFile {
        guard data.count <= maximumFileSize else { throw BackupError.fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let envelope = try decoder.decode(SchemaEnvelope.self, from: data)
            guard envelope.schemaVersion >= minimumSupportedSchema else { throw BackupError.invalidFile }
            guard envelope.schemaVersion <= currentSchemaVersion else {
                throw BackupError.unsupportedSchema(envelope.schemaVersion)
            }
            let backup: BackupFile
            if envelope.schemaVersion == 1 {
                let legacy = try decoder.decode(LegacyBackupFile.self, from: data)
                var profile = Profile.newDefault(name: "Imported")
                profile.stepProgress = legacy.stepProgress
                profile.targetMaturityLevelRaw = legacy.settings.targetMaturityLevel ?? MaturityLevel.ml3.rawValue
                profile.osScopeFilterRaw = legacy.settings.osScopeFilter ?? OSScope.both.rawValue
                profile.microsoft365LicenseModeRaw = legacy.settings.microsoft365LicenseMode ?? Microsoft365LicenseMode.none.rawValue
                backup = BackupFile(
                    schemaVersion: currentSchemaVersion,
                    appVersion: legacy.appVersion,
                    exportedAt: legacy.exportedAt,
                    profiles: [profile],
                    globalSettings: nil
                )
            } else {
                backup = try decoder.decode(BackupFile.self, from: data)
            }
            guard !backup.profiles.isEmpty,
                  Set(backup.profiles.map(\.id)).count == backup.profiles.count else {
                throw BackupError.invalidFile
            }
            return backup
        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.invalidFile
        }
    }
}

struct GlobalSettingsBackup: Codable {
    let showSplashOnStartup: Bool?
    let referenceOnlyMode: Bool?
    let deepAuditEnabled: Bool?
    let multiProfileEnabled: Bool?

    enum CodingKeys: String, CodingKey, CaseIterable {
        case showSplashOnStartup
        case referenceOnlyMode
        case deepAuditEnabled
        case multiProfileEnabled
    }
}

private struct SchemaEnvelope: Decodable { let schemaVersion: Int }

private struct LegacyBackupFile: Decodable {
    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let stepProgress: [String: StepStatus]
    let settings: LegacyBackupSettings
}

private struct LegacyBackupSettings: Decodable {
    let microsoft365LicenseMode: String?
    let targetMaturityLevel: Int?
    let showSplashOnStartup: Bool?
    let referenceOnlyMode: Bool?
    let osScopeFilter: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let licence = try container.decodeIfPresent(String.self, forKey: .microsoft365LicenseMode)
        let maturity = try container.decodeIfPresent(Int.self, forKey: .targetMaturityLevel)
        let scope = try container.decodeIfPresent(String.self, forKey: .osScopeFilter)
        microsoft365LicenseMode = licence.flatMap { Microsoft365LicenseMode(rawValue: $0)?.rawValue }
        targetMaturityLevel = maturity.flatMap { MaturityLevel(rawValue: $0)?.rawValue }
        showSplashOnStartup = try container.decodeIfPresent(Bool.self, forKey: .showSplashOnStartup)
        referenceOnlyMode = try container.decodeIfPresent(Bool.self, forKey: .referenceOnlyMode)
        osScopeFilter = scope.flatMap { OSScope(rawValue: $0)?.rawValue }
    }

    private enum CodingKeys: String, CodingKey {
        case microsoft365LicenseMode
        case targetMaturityLevel
        case showSplashOnStartup
        case referenceOnlyMode
        case osScopeFilter
    }
}
