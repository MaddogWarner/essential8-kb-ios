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
}
