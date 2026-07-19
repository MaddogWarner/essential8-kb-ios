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
            return "The selected backup is larger than the 1 MB safety limit."
        case .unsupportedSchema(let version):
            return "This backup uses schema version \(version). Update the app before importing it."
        case .invalidFile:
            return "The selected file is not a valid Essential 8 backup."
        }
    }
}

/// Versioned on-disk format for full app-state backup. Bump `schemaVersion`
/// only on breaking changes; additive fields decode as optionals.
struct BackupFile: Codable {
    static let currentSchemaVersion = 1
    static let maximumFileSize = 1_048_576

    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let stepProgress: [String: StepStatus]
    let settings: BackupSettings

    static func encode(_ backup: BackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        guard data.count <= maximumFileSize else { throw BackupError.fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let backup = try decoder.decode(BackupFile.self, from: data)
            guard backup.schemaVersion == currentSchemaVersion else {
                throw BackupError.unsupportedSchema(backup.schemaVersion)
            }
            return backup
        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.invalidFile
        }
    }
}

struct BackupSettings: Codable {
    let microsoft365LicenseMode: String?
    let targetMaturityLevel: Int?
    let showSplashOnStartup: Bool?
    let referenceOnlyMode: Bool?
    let osScopeFilter: String?

    enum CodingKeys: String, CodingKey, CaseIterable {
        case microsoft365LicenseMode
        case targetMaturityLevel
        case showSplashOnStartup
        case referenceOnlyMode
        case osScopeFilter
    }

    init(
        microsoft365LicenseMode: String? = nil,
        targetMaturityLevel: Int? = nil,
        showSplashOnStartup: Bool? = nil,
        referenceOnlyMode: Bool? = nil,
        osScopeFilter: String? = nil
    ) {
        self.microsoft365LicenseMode = microsoft365LicenseMode.flatMap { Microsoft365LicenseMode(rawValue: $0)?.rawValue }
        self.targetMaturityLevel = targetMaturityLevel.flatMap { MaturityLevel(rawValue: $0)?.rawValue }
        self.showSplashOnStartup = showSplashOnStartup
        self.referenceOnlyMode = referenceOnlyMode
        self.osScopeFilter = osScopeFilter.flatMap { OSScope(rawValue: $0)?.rawValue }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            microsoft365LicenseMode: try container.decodeIfPresent(String.self, forKey: .microsoft365LicenseMode),
            targetMaturityLevel: try container.decodeIfPresent(Int.self, forKey: .targetMaturityLevel),
            showSplashOnStartup: try container.decodeIfPresent(Bool.self, forKey: .showSplashOnStartup),
            referenceOnlyMode: try container.decodeIfPresent(Bool.self, forKey: .referenceOnlyMode),
            osScopeFilter: try container.decodeIfPresent(String.self, forKey: .osScopeFilter)
        )
    }
}
