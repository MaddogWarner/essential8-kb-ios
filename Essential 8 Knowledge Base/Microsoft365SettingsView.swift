//
//  Microsoft365SettingsView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct Microsoft365SettingsView: View {
    @AppStorage("microsoft365LicenseMode") private var selectedLicenseRawValue = Microsoft365LicenseMode.none.rawValue

    private var selectedMode: Microsoft365LicenseMode {
        Microsoft365LicenseMode(rawValue: selectedLicenseRawValue) ?? .none
    }

    private var selectedModeBinding: Binding<Microsoft365LicenseMode> {
        Binding(
            get: { selectedMode },
            set: { selectedLicenseRawValue = $0.rawValue }
        )
    }

    var body: some View {
        List {
            Section {
                Text("Different Microsoft 365 licensing levels provide different identity, endpoint, email and cloud-app protections. These settings add separate M365/MDE sections to the Essential Eight control pages so the core Windows guidance stays distinct from licensed cloud protections.")
                    .font(.body)
            } header: {
                Text("Purpose")
            }

            Section {
                radioButton(title: "None", subtitle: Microsoft365LicenseMode.none.description, isSelected: selectedModeBinding.wrappedValue == .none) {
                    selectedModeBinding.wrappedValue = .none
                }

                radioButton(title: "E3", subtitle: "Microsoft 365 E3 baseline. Choose the Entra ID plan available to the organisation.", isSelected: selectedMode.baseSelection == .e3) {
                    selectedModeBinding.wrappedValue = .e3P1
                }

                if selectedMode.baseSelection == .e3 {
                    VStack(alignment: .leading, spacing: 8) {
                        radioButton(title: "P1", subtitle: "Entra ID P1 with Conditional Access and MFA policy controls.", isSelected: selectedModeBinding.wrappedValue == .e3P1) {
                            selectedModeBinding.wrappedValue = .e3P1
                        }
                        radioButton(title: "P2", subtitle: "Adds Entra ID P2 identity risk and Privileged Identity Management capabilities.", isSelected: selectedModeBinding.wrappedValue == .e3P2) {
                            selectedModeBinding.wrappedValue = .e3P2
                        }
                    }
                    .padding(.leading, 28)
                    .padding(.vertical, 4)
                }

                radioButton(title: "E5", subtitle: Microsoft365LicenseMode.e5.description, isSelected: selectedModeBinding.wrappedValue == .e5) {
                    selectedModeBinding.wrappedValue = .e5
                }
            } header: {
                Text("License Mode")
            } footer: {
                Text("Default is None. The selection is stored locally on this device and does not leave the app.")
                    .font(.footnote)
            }

            if selectedMode != .none {
                Section {
                    Text("Current mode: \(selectedMode.shortName)")
                    Text(selectedMode.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Active Additions")
                }
            }
        }
        .navigationTitle("M365 Additional Controls")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func radioButton(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

#Preview {
    NavigationStack {
        Microsoft365SettingsView()
    }
}
