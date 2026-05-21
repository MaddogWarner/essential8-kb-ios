//
//  AppInformation.swift
//  Essential 8 Knowledge Base
//

import Foundation

enum AppInformation {
    static let aboutTitle = "About Essential 8"

    static let aboutDescription = "Essential 8 Knowledge Base is designed to give administrators just the technical details they need for each Essential Eight control as a quick reference."

    static let contentScope = "The guidance is scoped to practical Windows administration details and should be checked against the current ASD Essential Eight Maturity Model before implementation."

    static let aboutMeTitle = "About Me"

    static let aboutMeDescription = "MadDogWarner is not affiliated with ASD or Microsoft in any way. This project is a passion project built to provide a clear, easy to understand security tool that helps technical teams uplift Essential Eight practices to the masses."

    static let authorLinks: [ReferenceLink] = [
        ReferenceLink(
            title: "MadDogWarner website",
            url: referenceURL("https://maddogwarner.com")
        ),
        ReferenceLink(
            title: "MadDogWarner GitHub",
            url: referenceURL("https://github.com/MadDogWarner")
        )
    ]

    static let privacyTitle = "Privacy Policy"

    static let privacyPolicy = "Essential 8 Knowledge Base does not collect, record, store, transmit, or share any user data. The app does not require account access and does not request access to the microphone, camera, location services, contacts, photos, or other device sensors."

    static let referenceLinks: [ReferenceLink] = [
        ReferenceLink(
            title: "ASD Essential Eight maturity model",
            url: referenceURL("https://www.cyber.gov.au/business-government/asds-cyber-security-frameworks/essential-eight/essential-eight-maturity-model")
        ),
        ReferenceLink(
            title: "ASD Information Security Manual",
            url: referenceURL("https://www.cyber.gov.au/resources-business-and-government/essential-cyber-security/ism")
        ),
        ReferenceLink(
            title: "Microsoft Defender for Endpoint plans",
            url: referenceURL("https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/defender-endpoint-plan-1-2")
        ),
        ReferenceLink(
            title: "Microsoft Defender service description",
            url: referenceURL("https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-defender-service-description")
        ),
        ReferenceLink(
            title: "Microsoft Entra Conditional Access",
            url: referenceURL("https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview")
        ),
        ReferenceLink(
            title: "Microsoft Entra MFA licensing",
            url: referenceURL("https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mfa-licensing")
        )
    ]

    private static func referenceURL(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid reference URL: \(string)")
        }

        return url
    }
}

struct ReferenceLink: Identifiable, Hashable {
    var id: URL { url }
    var hostDisplayName: String { url.host() ?? url.absoluteString }

    let title: String
    let url: URL
}
