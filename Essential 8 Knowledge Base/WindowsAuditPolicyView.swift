//
//  WindowsAuditPolicyView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct WindowsAuditPolicyView: View {
    private var categories: [String] {
        WindowsAuditPolicyData.entries.reduce(into: []) { result, entry in
            if !result.contains(entry.category) {
                result.append(entry.category)
            }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ASD Recommended Minimum Audit Policy")
                        .font(.headline)
                    Text(WindowsAuditPolicyData.overview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            ForEach(categories, id: \.self) { category in
                Section(category) {
                    ForEach(entries(for: category)) { entry in
                        AuditPolicyEntryRow(entry: entry)
                    }
                }
            }
        }
        .navigationTitle("Windows Audit Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entries(for category: String) -> [AuditPolicyEntry] {
        WindowsAuditPolicyData.entries.filter { $0.category == category }
    }
}

private struct AuditPolicyEntryRow: View {
    let entry: AuditPolicyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                    Text(entry.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AuditRecommendationBadge(recommendation: entry.recommendation)
            }

            if entry.domainControllerOnly {
                Label("Domain controllers only", systemImage: "server.rack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(entry.considerations)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AuditRecommendationBadge: View {
    let recommendation: AuditRecommendation

    var body: some View {
        Text(recommendation.rawValue)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch recommendation {
        case .both:
            return .blue
        case .success:
            return .green
        case .failure:
            return .orange
        case .notRecommended:
            return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        WindowsAuditPolicyView()
    }
}
