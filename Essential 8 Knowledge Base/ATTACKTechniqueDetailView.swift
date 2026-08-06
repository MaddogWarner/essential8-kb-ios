//
//  ATTACKTechniqueDetailView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

private struct ATTACKMappedStep: Identifiable {
    let mapping: ATTACKMapping
    let control: EssentialControl
    let level: MaturityLevel
    let step: ImplementationStep

    var id: String { mapping.id }
}

struct ATTACKTechniqueDetailView: View {
    let technique: ATTACKTechnique

    @EnvironmentObject private var progressStore: ProgressStore
    @Environment(\.dismiss) private var dismiss

    private var mappedSteps: [ATTACKMappedStep] {
        ATTACKMappingData.mappings(forTechnique: technique.id).compactMap { mapping in
            for control in EssentialControlsData.all {
                for level in MaturityLevel.allCases {
                    if let step = control.content(for: level).steps.first(where: { $0.id == mapping.stepID }) {
                        return ATTACKMappedStep(mapping: mapping, control: control, level: level, step: step)
                    }
                }
            }
            return nil
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(technique.id)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.purple)
                    Text(technique.name).font(.title2.bold())
                    FlowLayout(items: technique.tactics.map(\.displayName))
                }
            }

            ForEach(ATTACKRelationship.allCases) { relationship in
                let matches = mappedSteps.filter { $0.mapping.relationships.contains(relationship) }
                if !matches.isEmpty {
                    Section(relationship.rawValue) {
                        ForEach(matches) { item in
                            mappedStepRow(item)
                        }
                    }
                }
            }

            Section {
                Text(AppInformation.attackDisclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Link(destination: technique.url) {
                    Label("View on attack.mitre.org", systemImage: "arrow.up.right.square")
                }
            }
        }
        .navigationTitle("ATT&CK Technique")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func mappedStepRow(_ item: ATTACKMappedStep) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                statusIcon(for: item.step.id)
                Text(item.control.name).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(item.level.shortName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1), in: Capsule())
                    .foregroundStyle(.blue)
            }
            Text(item.step.title).font(.subheadline.weight(.semibold))
            if !isInScope(item) {
                Text("Not in your current scope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let note = item.mapping.note {
                Text(note).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func isInScope(_ item: ATTACKMappedStep) -> Bool {
        item.level.rawValue <= progressStore.targetMaturityLevel.rawValue
            && item.step.matches(scope: progressStore.osScope)
    }

    @ViewBuilder
    private func statusIcon(for stepID: String) -> some View {
        switch progressStore.status(for: stepID).state {
        case .implemented:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .notApplicable:
            Image(systemName: "slash.circle.fill").foregroundStyle(.orange)
        case .notImplemented:
            Image(systemName: "circle").foregroundStyle(.secondary)
        }
    }
}

private struct FlowLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .leading)], alignment: .leading) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.1), in: Capsule())
                    .foregroundStyle(.purple)
            }
        }
    }
}
