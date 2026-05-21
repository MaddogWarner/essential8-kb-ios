//
//  Microsoft365LicenseMode.swift
//  Essential 8 Knowledge Base
//

import Foundation

enum Microsoft365LicenseMode: String, CaseIterable, Identifiable {
    case none
    case e3P1
    case e3P2
    case e5

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .e3P1: return "Microsoft 365 E3 + Entra ID P1"
        case .e3P2: return "Microsoft 365 E3 + Entra ID P2"
        case .e5: return "Microsoft 365 E5"
        }
    }

    var shortName: String {
        switch self {
        case .none: return "None"
        case .e3P1: return "E3 + P1"
        case .e3P2: return "E3 + P2"
        case .e5: return "E5"
        }
    }

    var description: String {
        switch self {
        case .none:
            return "No Microsoft 365 or Defender additions are shown in the control pages."
        case .e3P1:
            return "Shows additional and partial protections commonly available with Microsoft 365 E3, including Entra ID P1, Intune Plan 1 and Defender for Endpoint Plan 1."
        case .e3P2:
            return "Shows Microsoft 365 E3 protections plus Entra ID P2 identity protections such as risk-based Conditional Access and Privileged Identity Management."
        case .e5:
            return "Shows the Microsoft 365 E5 security stack, including Entra ID P2, Defender for Endpoint Plan 2, Defender for Office 365 Plan 2, Defender for Identity and Defender for Cloud Apps."
        }
    }

    var baseSelection: Microsoft365BaseSelection {
        switch self {
        case .none: return .none
        case .e3P1, .e3P2: return .e3
        case .e5: return .e5
        }
    }
}

enum Microsoft365BaseSelection {
    case none
    case e3
    case e5
}
