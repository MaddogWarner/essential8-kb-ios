//
//  ATTACKCoverageView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct ATTACKCoverageView: View {
    let controlFilter: Int?

    @EnvironmentObject private var progressStore: ProgressStore
    @State private var selectedTechnique: ATTACKTechnique?

    init(controlFilter: Int? = nil) {
        self.controlFilter = controlFilter
    }

    private var title: String {
        guard let controlFilter,
              let control = EssentialControlsData.all.first(where: { $0.id == controlFilter })
        else { return "ATT&CK Coverage" }
        return "\(control.name) — ATT&CK"
    }

    var body: some View {
        // Computed once per render rather than per summary tile — each call walks the
        // whole catalogue against the in-scope step set.
        let groups = ATTACKCoverageCalculator.grouped(store: progressStore, controlFilter: controlFilter)
        let unique = uniqueCoverage(in: groups)
        let untallied = unique.filter { $0.status == .indirect || $0.status == .notApplicable }.count

        List {
            Section {
                HStack {
                    summaryCount("Covered", count: unique.filter { $0.status == .covered }.count, colour: .green)
                    Spacer()
                    summaryCount("Partial", count: unique.filter { $0.status == .partial }.count, colour: .orange)
                    Spacer()
                    summaryCount("Not covered", count: unique.filter { $0.status == .notCovered }.count, colour: .secondary)
                }
                Text("Measured against your target of ML\(progressStore.targetMaturityLevel.rawValue), \(scopeName) scope.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if untallied > 0 {
                    Text("\(untallied) further \(untallied == 1 ? "technique is" : "techniques are") listed below as Indirect or Not applicable and are not counted above.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(AppInformation.attackCoverageCaveat)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Summary")
            }

            ForEach(groups, id: \.tactic.id) { group in
                Section {
                    ForEach(group.coverage) { coverage in
                        Button {
                            selectedTechnique = coverage.technique
                        } label: {
                            coverageRow(coverage)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("\(group.tactic.displayName) (\(group.coverage.count))")
                }
            }

            Section {
                Text("A technique that belongs to several tactics appears under each. Techniques with no steps in your current maturity and OS scope are not listed. \(AppInformation.attackDisclaimerShort)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTechnique) { technique in
            NavigationStack {
                ATTACKTechniqueDetailView(technique: technique)
            }
        }
    }

    private var scopeName: String {
        switch progressStore.osScope {
        case .workstation: return "Workstation"
        case .server: return "Server"
        case .both: return "Both"
        }
    }

    /// A technique in several tactics appears in several groups; count it once.
    private func uniqueCoverage(
        in groups: [(tactic: ATTACKTactic, coverage: [TechniqueCoverage])]
    ) -> [TechniqueCoverage] {
        var seen = Set<String>()
        return groups.flatMap(\.coverage).filter { seen.insert($0.id).inserted }
    }

    @ViewBuilder
    private func summaryCount(_ label: String, count: Int, colour: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(colour)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func coverageRow(_ coverage: TechniqueCoverage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(coverage.technique.id)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(.purple)
                Text(coverage.technique.name).font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                coverageBadge(coverage.status)
                if coverage.contributingTotal > 0 {
                    Text("\(coverage.contributingImplemented) of \(coverage.contributingTotal) steps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func coverageBadge(_ status: CoverageStatus) -> some View {
        let display: (String, Color) = switch status {
        case .covered: ("Covered", .green)
        case .partial: ("Partial", .orange)
        case .notCovered: ("Not covered", .secondary)
        case .indirect: ("Indirect", .secondary)
        case .notApplicable: ("Not applicable", .orange)
        }
        Text(display.0)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(display.1.opacity(0.12), in: Capsule())
            .foregroundStyle(display.1)
    }
}
