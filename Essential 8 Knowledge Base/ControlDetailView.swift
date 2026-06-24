//
//  ControlDetailView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct ControlDetailView: View {
    let control: EssentialControl

    @EnvironmentObject private var progressStore: ProgressStore

    private var allSteps: [ImplementationStep] {
        MaturityLevel.allCases.flatMap { control.content(for: $0).steps }
    }

    private var completedCount: Int {
        progressStore.completedCount(for: allSteps)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: control.iconSystemName)
                            .font(.title)
                            .foregroundStyle(.tint)
                        Text(control.name)
                            .font(.title2.weight(.semibold))
                    }
                    Text(control.overview)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Overview")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ML0 — No controls implemented")
                        .font(.headline)
                    Text(EssentialControlsData.ml0GenericDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(control.ml0Description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Baseline")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: Double(completedCount), total: Double(allSteps.count))
                        .tint(completedCount == allSteps.count ? .green : .accentColor)
                    HStack {
                        Text("\(completedCount) of \(allSteps.count) steps complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if completedCount == allSteps.count {
                            Label("All steps complete", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                                .labelStyle(.iconOnly)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Implementation Progress")
            }

            Section {
                maturityButton(level: .ml1, content: control.ml1)
                maturityButton(level: .ml2, content: control.ml2)
                maturityButton(level: .ml3, content: control.ml3)
            } header: {
                Text("Maturity Levels")
            } footer: {
                Text("Select a maturity level to see the specific configuration changes required.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Mitigation \(control.id)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MaturityLevelDestination.self) { destination in
            MaturityLevelView(
                controlID: control.id,
                controlName: control.name,
                level: destination.level,
                content: destination.content
            )
        }
    }

    @ViewBuilder
    private func maturityButton(level: MaturityLevel, content: MaturityLevelContent) -> some View {
        let doneCount = progressStore.completedCount(for: content.steps)
        let totalCount = content.steps.count

        NavigationLink(value: MaturityLevelDestination(level: level, content: content)) {
            HStack(alignment: .top, spacing: 12) {
                Text(level.shortName)
                    .font(.headline)
                    .frame(width: 44, alignment: .leading)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(content.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
                Text("\(doneCount)/\(totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct MaturityLevelDestination: Hashable {
    let level: MaturityLevel
    let content: MaturityLevelContent
}

#Preview {
    NavigationStack {
        ControlDetailView(control: EssentialControlsData.applicationControl)
    }
    .environmentObject(ProgressStore.shared)
}
