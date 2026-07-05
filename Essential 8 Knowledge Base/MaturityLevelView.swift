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

    @EnvironmentObject private var progressStore: ProgressStore
    @AppStorage("microsoft365LicenseMode") private var selectedLicenseRawValue = Microsoft365LicenseMode.none.rawValue

    private var selectedLicenseMode: Microsoft365LicenseMode {
        Microsoft365LicenseMode(rawValue: selectedLicenseRawValue) ?? .none
    }

    private var microsoft365Protections: [Microsoft365AdditionalProtection] {
        Microsoft365AdditionalControlsData.protections(for: controlID, level: level, licenseMode: selectedLicenseMode)
    }

    @State private var activeStepIDForNA: String? = nil
    @State private var showingNAReasonAlert = false
    @State private var naReasonText = ""

    private var completedCount: Int {
        progressStore.completedCount(for: content.steps)
    }

    private var notApplicableCount: Int {
        progressStore.notApplicableCount(for: content.steps)
    }

    private var headerProgressText: String {
        let naCount = notApplicableCount
        if naCount > 0 {
            return "\(completedCount) of \(content.steps.count) steps complete (\(naCount) not applicable)"
        } else {
            return "\(completedCount) of \(content.steps.count) steps complete"
        }
    }

    var body: some View {
        List {
            Section {
                Text(content.summary)
                    .font(.body)
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("What \(level.shortName) requires")
                    Text(headerProgressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }

            ForEach(Array(content.steps.enumerated()), id: \.element.id) { index, step in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Menu {
                                Button {
                                    progressStore.setStatus(.implemented, reason: nil, for: step.id)
                                } label: {
                                    Label("Implemented", systemImage: "checkmark.circle.fill")
                                }
                                Button {
                                    activeStepIDForNA = step.id
                                    naReasonText = progressStore.status(for: step.id).reason ?? ""
                                    showingNAReasonAlert = true
                                } label: {
                                    Label("Not Applicable", systemImage: "slash.circle.fill")
                                }
                                Button {
                                    progressStore.setStatus(.notImplemented, reason: nil, for: step.id)
                                } label: {
                                    Label("Not Implemented", systemImage: "circle")
                                }
                            } label: {
                                statusIcon(for: step.id)
                            }
                            .buttonStyle(.plain)

                            Text(step.title)
                                .font(.headline)
                        }
                        
                        if progressStore.isNotApplicable(step.id) {
                            let reason = progressStore.status(for: step.id).reason ?? ""
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.orange)
                                Text(reason.isEmpty ? "Not Applicable (No reason provided)" : "Not Applicable: \(reason)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        }

                        ISMControlsCapsules(controls: step.ismControls)

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
        .alert("Not Applicable Reason", isPresented: $showingNAReasonAlert) {
            TextField("Enter reason (optional)", text: $naReasonText)
            Button("Save") {
                if let stepID = activeStepIDForNA {
                    progressStore.setStatus(.notApplicable, reason: naReasonText.trimmingCharacters(in: .whitespacesAndNewlines), for: stepID)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Provide a reason why this step is not applicable in your environment.")
        }
    }

    @ViewBuilder
    private func statusIcon(for stepID: String) -> some View {
        let status = progressStore.status(for: stepID)
        switch status.state {
        case .implemented:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
                .accessibilityLabel("Implemented")
        case .notApplicable:
            Image(systemName: "slash.circle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
                .accessibilityLabel("Not Applicable")
        case .notImplemented:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .font(.title3)
                .accessibilityLabel("Not Implemented")
        }
    }
}

struct ISMControlsCapsules: View {
    let controls: [String]

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 72), spacing: 6, alignment: .leading)]
    }

    var body: some View {
        if !controls.isEmpty {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                ForEach(controls, id: \.self) { control in
                    Text(control)
                        .font(.system(.caption2, design: .monospaced).bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                        .textSelection(.enabled)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("ISM controls: \(controls.joined(separator: ", "))")
        }
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
    .environmentObject(ProgressStore.shared)
}
