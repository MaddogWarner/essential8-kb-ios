//
//  MaturityLevelView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct MaturityLevelView: View {
    let controlID: Int
    let controlName: String
    let level: MaturityLevel
    let content: MaturityLevelContent

    @AppStorage("microsoft365LicenseMode") private var selectedLicenseRawValue = Microsoft365LicenseMode.none.rawValue

    private var selectedLicenseMode: Microsoft365LicenseMode {
        Microsoft365LicenseMode(rawValue: selectedLicenseRawValue) ?? .none
    }

    private var microsoft365Protections: [Microsoft365AdditionalProtection] {
        Microsoft365AdditionalControlsData.protections(for: controlID, level: level, licenseMode: selectedLicenseMode)
    }

    var body: some View {
        List {
            Section {
                Text(content.summary)
                    .font(.body)
            } header: {
                Text("What \(level.shortName) requires")
            }

            ForEach(Array(content.steps.enumerated()), id: \.element.id) { index, step in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.title)
                            .font(.headline)
                        Text(step.description)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        if !step.technicalDetails.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(step.technicalDetails, id: \.self) { detail in
                                    Text(detail)
                                        .font(.system(.footnote, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Step \(index + 1)")
                }
            }

            if let gap = content.gapNote {
                Section {
                    Label {
                        Text(gap)
                            .font(.footnote)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Beyond Windows built-in tooling")
                }
            }

            if !microsoft365Protections.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mode: \(selectedLicenseMode.shortName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(microsoft365Protections) { protection in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(protection.title)
                                    .font(.headline)
                                Text(protection.coverage)
                                    .font(.subheadline)
                                ForEach(protection.basicSettings, id: \.self) { setting in
                                    Text(setting)
                                        .font(.system(.footnote, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("M365 / MDE additions")
                } footer: {
                    Text("These licensed protections are additional or partial supports. They do not replace the core Essential Eight implementation steps above.")
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("\(controlName) — \(level.shortName)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MaturityLevelView(
            controlID: EssentialControlsData.applicationControl.id,
            controlName: EssentialControlsData.applicationControl.name,
            level: .ml1,
            content: EssentialControlsData.applicationControl.ml1
        )
    }
}
