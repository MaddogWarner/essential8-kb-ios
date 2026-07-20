//
//  ControlDetailView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct ControlDetailView: View {
    let control: EssentialControl

    @EnvironmentObject private var progressStore: ProgressStore
    private var targetLevel: MaturityLevel {
        progressStore.targetMaturityLevel
    }

    private var scopeFilter: OSScope {
        progressStore.osScope
    }

    private var allSteps: [ImplementationStep] {
        control.steps(upTo: targetLevel, scope: scopeFilter)
    }

    private var completedCount: Int {
        progressStore.completedCount(for: allSteps)
    }

    private var notApplicableCount: Int {
        progressStore.notApplicableCount(for: allSteps)
    }

    private var compliancePercentage: Double {
        progressStore.compliancePercentage(for: allSteps)
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
                    ProgressView(value: compliancePercentage, total: 100.0)
                        .tint(compliancePercentage == 100.0 ? .green : .accentColor)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(completedCount) of \(allSteps.count) steps complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if notApplicableCount > 0 {
                                Text("\(notApplicableCount) step(s) not applicable")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Text(String(format: "%.0f%% Compliant", compliancePercentage))
                            .font(.subheadline.bold())
                            .foregroundStyle(compliancePercentage == 100.0 ? .green : .primary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Implementation Progress")
            } footer: {
                Text("Measured against your target of ML\(targetLevel.rawValue). Change the target on the home dashboard.")
                    .font(.footnote)
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
        let scopedSteps = content.steps.filter { $0.matches(scope: scopeFilter) }
        let doneCount = progressStore.completedCount(for: scopedSteps)
        let naCount = progressStore.notApplicableCount(for: scopedSteps)
        let totalCount = scopedSteps.count
        let progressText = naCount > 0 ? "\(doneCount)/\(totalCount) (\(naCount) N/A)" : "\(doneCount)/\(totalCount)"
        let isBeyondTarget = level.rawValue > targetLevel.rawValue

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
                if isBeyondTarget {
                    Text("Beyond target")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)
                } else {
                    Text(progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
