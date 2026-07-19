//
//  Essential_8_Knowledge_BaseTests.swift
//  Essential 8 Knowledge BaseTests
//
//  Created by David Warner on 20/5/2026.
//

import Foundation
import Testing
@testable import Essential_8_Knowledge_Base

struct Essential_8_Knowledge_BaseTests {

    @Test @MainActor func essentialControlsAreComplete() throws {
        let controls = EssentialControlsData.all

        #expect(controls.count == 8)
        #expect(Set(controls.map(\.id)).count == controls.count)

        for control in controls {
            #expect(!control.name.isEmpty)
            #expect(!control.overview.isEmpty)
            #expect(!control.ml0Description.isEmpty)
            for level in MaturityLevel.allCases {
                let content = control.content(for: level)

                #expect(!content.summary.isEmpty)
                #expect(!content.steps.isEmpty)
                #expect(content.steps.allSatisfy { !$0.title.isEmpty && !$0.description.isEmpty })
            }
        }
    }

    @Test func aboutAndPrivacyCopyMatchesAppScope() throws {
        #expect(AppInformation.aboutDescription.contains("administrators"))
        #expect(AppInformation.aboutDescription.contains("quick reference"))
        #expect(AppInformation.privacyPolicy.contains("does not collect"))
        #expect(AppInformation.privacyPolicy.contains("microphone"))
        #expect(AppInformation.privacyPolicy.contains("camera"))
        #expect(AppInformation.privacyPolicy.contains("location services"))
    }

    @Test func referenceLinksIncludeAuthoritativeSources() throws {
        let urls = AppInformation.referenceLinks.map(\.url.absoluteString)

        #expect(urls.contains { $0.contains("cyber.gov.au") && $0.contains("essential-eight") })
        #expect(urls.contains { $0.contains("cyber.gov.au") && $0.contains("ism") })
        #expect(urls.contains { $0.contains("learn.microsoft.com") && $0.contains("defender-endpoint") })
        #expect(urls.contains { $0.contains("learn.microsoft.com") && $0.contains("conditional-access") })
    }

    @Test func referenceLinksAreValid() throws {
        let references = AppInformation.referenceLinks

        #expect(!references.isEmpty)
        #expect(Set(references.map(\.url)).count == references.count)

        for reference in references {
            #expect(!reference.title.isEmpty)
            #expect(reference.url.scheme == "https")
            #expect(reference.url.host() != nil)
            #expect(!reference.hostDisplayName.isEmpty)
        }
    }

    @Test func microsoft365AdditionalProtectionsRespectLicenseMode() throws {
        let none = Microsoft365AdditionalControlsData.protections(for: 7, level: .ml3, licenseMode: .none)
        let e3P1 = Microsoft365AdditionalControlsData.protections(for: 7, level: .ml3, licenseMode: .e3P1)
        let e3P2 = Microsoft365AdditionalControlsData.protections(for: 7, level: .ml3, licenseMode: .e3P2)
        let e5 = Microsoft365AdditionalControlsData.protections(for: 7, level: .ml3, licenseMode: .e5)

        #expect(none.isEmpty)
        #expect(!e3P1.isEmpty)
        #expect(e3P2.count > e3P1.count)
        #expect(e5.count > e3P2.count)
        #expect(e5.contains { $0.title.contains("E5") })
    }

    @Test @MainActor func progressStoreCalculatesComplianceCorrectly() throws {
        let store = ProgressStore.shared
        let steps = [
            ImplementationStep(id: "test-1", title: "Test 1", description: "", technicalDetails: []),
            ImplementationStep(id: "test-2", title: "Test 2", description: "", technicalDetails: []),
            ImplementationStep(id: "test-3", title: "Test 3", description: "", technicalDetails: []),
            ImplementationStep(id: "test-4", title: "Test 4", description: "", technicalDetails: [])
        ]
        
        for step in steps {
            store.setStatus(.notImplemented, reason: nil, for: step.id)
        }
        #expect(store.compliancePercentage(for: steps) == 0.0)
        
        store.setStatus(.implemented, reason: nil, for: "test-1")
        #expect(store.compliancePercentage(for: steps) == 25.0)
        #expect(store.completedCount(for: steps) == 1)
        
        store.setStatus(.notApplicable, reason: "Legacy system", for: "test-2")
        let percentage = store.compliancePercentage(for: steps)
        #expect(abs(percentage - 33.33) < 0.1)
        #expect(store.notApplicableCount(for: steps) == 1)
        
        store.setStatus(.implemented, reason: nil, for: "test-3")
        store.setStatus(.implemented, reason: nil, for: "test-4")
        #expect(store.compliancePercentage(for: steps) == 100.0)
        
        for step in steps {
            store.setStatus(.notImplemented, reason: nil, for: step.id)
        }
    }

    @Test @MainActor func progressStorePersistenceAndStates() throws {
        let store = ProgressStore.shared
        store.setStatus(.notApplicable, reason: "Test reason", for: "persistence-test")
        #expect(store.status(for: "persistence-test").state == .notApplicable)
        #expect(store.status(for: "persistence-test").reason == "Test reason")
        
        store.setStatus(.notImplemented, reason: nil, for: "persistence-test")
        #expect(store.status(for: "persistence-test").state == .notImplemented)
    }

    @Test @MainActor func progressStoreResetAllResetsEverything() throws {
        let store = ProgressStore.shared
        
        store.setStatus(.implemented, reason: nil, for: "reset-test-1")
        store.setStatus(.notApplicable, reason: "Some reason", for: "reset-test-2")
        UserDefaults.standard.set("e5", forKey: "microsoft365LicenseMode")
        UserDefaults.standard.set(MaturityLevel.ml1.rawValue, forKey: "targetMaturityLevel")
        UserDefaults.standard.set(false, forKey: "showSplashOnStartup")
        UserDefaults.standard.set(true, forKey: "referenceOnlyMode")
        UserDefaults.standard.set(OSScope.server.rawValue, forKey: "osScopeFilter")
        
        #expect(store.status(for: "reset-test-1").state == .implemented)
        #expect(store.status(for: "reset-test-2").state == .notApplicable)
        #expect(UserDefaults.standard.string(forKey: "microsoft365LicenseMode") == "e5")
        #expect(UserDefaults.standard.integer(forKey: "targetMaturityLevel") == MaturityLevel.ml1.rawValue)
        #expect(UserDefaults.standard.bool(forKey: "showSplashOnStartup") == false)
        #expect(UserDefaults.standard.bool(forKey: "referenceOnlyMode") == true)
        #expect(UserDefaults.standard.string(forKey: "osScopeFilter") == OSScope.server.rawValue)
        
        store.resetAll()
        
        #expect(store.status(for: "reset-test-1").state == .notImplemented)
        #expect(store.status(for: "reset-test-2").state == .notImplemented)
        #expect(store.status(for: "reset-test-2").reason == nil)
        
        #expect(UserDefaults.standard.object(forKey: "microsoft365LicenseMode") == nil)
        #expect(UserDefaults.standard.object(forKey: "targetMaturityLevel") == nil)
        #expect(UserDefaults.standard.object(forKey: "showSplashOnStartup") == nil)
        #expect(UserDefaults.standard.object(forKey: "referenceOnlyMode") == nil)
        #expect(UserDefaults.standard.object(forKey: "osScopeFilter") == nil)
    }

    @Test func maturityLevelCumulativeLevelsAreOrdered() throws {
        #expect(MaturityLevel.ml1.cumulativeLevels == [.ml1])
        #expect(MaturityLevel.ml3.cumulativeLevels == [.ml1, .ml2, .ml3])
    }

    @Test func controlStepsUpToTargetAreCumulative() throws {
        let control = EssentialControlsData.applicationControl

        #expect(control.steps(upTo: .ml1).count == control.ml1.steps.count)
        #expect(control.steps(upTo: .ml3).count == control.ml1.steps.count + control.ml2.steps.count + control.ml3.steps.count)
    }

    @Test @MainActor func progressStoreCalculatesTargetScopedCompliance() throws {
        let store = ProgressStore.shared
        store.resetAll()

        let control = EssentialControlsData.applicationControl
        for step in control.ml1.steps {
            store.setStatus(.implemented, reason: nil, for: step.id)
        }

        #expect(store.compliancePercentage(for: control.steps(upTo: .ml1)) == 100.0)
        #expect(store.compliancePercentage(for: control.steps(upTo: .ml3)) < 100.0)

        store.resetAll()
    }

    @Test @MainActor func controlCompletionUsesTargetScope() throws {
        let store = ProgressStore.shared
        store.resetAll()

        let control = EssentialControlsData.applicationControl
        for step in control.ml1.steps {
            store.setStatus(.implemented, reason: nil, for: step.id)
        }

        #expect(store.isControlComplete(control, upTo: .ml1, scope: .both))
        #expect(!store.isControlComplete(control, upTo: .ml3, scope: .both))

        store.resetAll()
    }

    @Test func ismControlsUseExpectedIdentifierFormat() throws {
        let pattern = /^ISM-\d{4}$/
        let ismControls = EssentialControlsData.all.flatMap { control in
            MaturityLevel.allCases.flatMap { level in
                control.content(for: level).steps.flatMap(\.ismControls)
            }
        }

        for identifier in ismControls {
            #expect(identifier.wholeMatch(of: pattern) != nil)
        }

        #expect(!ismControls.isEmpty)
    }

    @Test func searchMatchesISMIdentifiers() throws {
        let taggedStep = ImplementationStep(
            id: "test-ism",
            title: "Tagged step",
            description: "Fixture",
            ismControls: ["ISM-1490"],
            technicalDetails: []
        )

        #expect(taggedStep.matchesSearchQuery("ISM-1490"))
        #expect(taggedStep.matchesSearchQuery("1490"))
        #expect(taggedStep.matchesSearchQuery("ism-1490"))
        #expect(taggedStep.matchingDetails(for: "1490") == ["ISM-1490"])
    }

    @Test func osScopeMatchingTruthTable() {
        let workstation = ImplementationStep(id: "w", title: "W", description: "", osScope: .workstation)
        let server = ImplementationStep(id: "s", title: "S", description: "", osScope: .server)
        let both = ImplementationStep(id: "b", title: "B", description: "", osScope: .both)

        #expect(workstation.matches(scope: .workstation))
        #expect(!workstation.matches(scope: .server))
        #expect(workstation.matches(scope: .both))
        #expect(!server.matches(scope: .workstation))
        #expect(server.matches(scope: .server))
        #expect(server.matches(scope: .both))
        #expect(both.matches(scope: .workstation))
        #expect(both.matches(scope: .server))
        #expect(both.matches(scope: .both))
    }

    @Test func scopeFilteredContentIsCumulativeAndTagged() {
        let backups = EssentialControlsData.regularBackups
        #expect(backups.steps(upTo: .ml3, scope: .workstation).count < backups.steps(upTo: .ml3).count)

        for control in EssentialControlsData.all {
            #expect(control.steps(upTo: .ml3, scope: .both) == control.steps(upTo: .ml3))
        }

        let allSteps = EssentialControlsData.all.flatMap { $0.steps(upTo: .ml3) }
        #expect(allSteps.contains { $0.osScope == .workstation })
        #expect(allSteps.contains { $0.osScope == .server })
    }

    @Test @MainActor func scopeFilteredComplianceUsesOnlyMatchingSteps() {
        let (store, defaults) = makeIsolatedStore()
        defer { clear(defaults) }
        let steps = [
            ImplementationStep(id: "scope-w", title: "W", description: "", osScope: .workstation),
            ImplementationStep(id: "scope-b", title: "B", description: "", osScope: .both),
            ImplementationStep(id: "scope-s", title: "S", description: "", osScope: .server)
        ]
        store.setStatus(.implemented, reason: nil, for: "scope-w")
        store.setStatus(.implemented, reason: nil, for: "scope-b")

        #expect(store.compliancePercentage(for: steps.filter { $0.matches(scope: .workstation) }) == 100)
        #expect(store.compliancePercentage(for: steps) < 100)
    }

    @Test @MainActor func backupRoundTripRestoresProgressAndSettings() throws {
        let (source, sourceDefaults) = makeIsolatedStore()
        let (destination, destinationDefaults) = makeIsolatedStore()
        defer {
            clear(sourceDefaults)
            clear(destinationDefaults)
        }

        source.setStatus(.implemented, reason: nil, for: "roundtrip-implemented")
        source.setStatus(.notApplicable, reason: "Approved exception", for: "roundtrip-na")
        sourceDefaults.set(Microsoft365LicenseMode.e5.rawValue, forKey: PersistedSettingsKey.microsoft365LicenseMode.rawValue)
        sourceDefaults.set(MaturityLevel.ml2.rawValue, forKey: PersistedSettingsKey.targetMaturityLevel.rawValue)
        sourceDefaults.set(false, forKey: PersistedSettingsKey.showSplashOnStartup.rawValue)
        sourceDefaults.set(true, forKey: PersistedSettingsKey.referenceOnlyMode.rawValue)
        sourceDefaults.set(OSScope.server.rawValue, forKey: PersistedSettingsKey.osScopeFilter.rawValue)

        let decoded = try BackupFile.decode(BackupFile.encode(try source.exportBackup()))
        destination.importBackup(decoded)

        #expect(destination.statuses == source.statuses)
        #expect(destinationDefaults.string(forKey: PersistedSettingsKey.microsoft365LicenseMode.rawValue) == Microsoft365LicenseMode.e5.rawValue)
        #expect(destinationDefaults.integer(forKey: PersistedSettingsKey.targetMaturityLevel.rawValue) == MaturityLevel.ml2.rawValue)
        #expect(destinationDefaults.bool(forKey: PersistedSettingsKey.showSplashOnStartup.rawValue) == false)
        #expect(destinationDefaults.bool(forKey: PersistedSettingsKey.referenceOnlyMode.rawValue) == true)
        #expect(destinationDefaults.string(forKey: PersistedSettingsKey.osScopeFilter.rawValue) == OSScope.server.rawValue)
    }

    @Test @MainActor func backupValidationRejectsInvalidFilesAndAbsentSettingsResetDefaults() throws {
        let newer = BackupFile(
            schemaVersion: 2,
            appVersion: "2.0",
            exportedAt: Date(),
            stepProgress: [:],
            settings: BackupSettings()
        )
        #expect(throws: BackupError.self) { try BackupFile.decode(BackupFile.encode(newer)) }
        #expect(throws: BackupError.self) { try BackupFile.decode(Data("not json".utf8)) }

        let (store, defaults) = makeIsolatedStore()
        defer { clear(defaults) }
        for key in PersistedSettingsKey.allCases {
            defaults.set("stale", forKey: key.rawValue)
        }
        store.importBackup(BackupFile(
            schemaVersion: 1,
            appVersion: "1.6",
            exportedAt: Date(),
            stepProgress: [:],
            settings: BackupSettings()
        ))
        #expect(PersistedSettingsKey.allCases.allSatisfy { defaults.object(forKey: $0.rawValue) == nil })
    }

    @Test func backupCoversAllPersistedKeys() {
        let registered = PersistedSettingsKey.allCases.map(\.rawValue).sorted()
        let backedUp = BackupSettings.CodingKeys.allCases.map(\.rawValue).sorted()
        #expect(registered == backedUp)
    }

    @MainActor
    private func makeIsolatedStore() -> (ProgressStore, UserDefaults) {
        let suiteName = "Essential8Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (ProgressStore(defaults: defaults), defaults)
    }

    private func clear(_ defaults: UserDefaults) {
        defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
