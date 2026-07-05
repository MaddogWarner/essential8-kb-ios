//
//  GlobalSearchView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct SearchResult: Identifiable {
    let id = UUID()
    let control: EssentialControl
    let level: MaturityLevel
    let content: MaturityLevelContent
    let step: ImplementationStep
    let stepNumber: Int
    let matchedDetails: [String]
}

struct GlobalSearchView: View {
    @State private var searchText = ""
    
    private var searchResults: [SearchResult] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var results: [SearchResult] = []
        
        for control in EssentialControlsData.all {
            for level in MaturityLevel.allCases {
                let content = control.content(for: level)
                for (index, step) in content.steps.enumerated() {
                    let matchesTitle = step.title.localizedCaseInsensitiveContains(query)
                    let matchesDescription = step.description.localizedCaseInsensitiveContains(query)
                    
                    var matchedTechnicalDetails: [String] = []
                    for detail in step.technicalDetails {
                        if detail.localizedCaseInsensitiveContains(query) {
                            matchedTechnicalDetails.append(detail)
                        }
                    }
                    
                    if matchesTitle || matchesDescription || !matchedTechnicalDetails.isEmpty {
                        results.append(
                            SearchResult(
                                control: control,
                                level: level,
                                content: content,
                                step: step,
                                stepNumber: index,
                                matchedDetails: matchedTechnicalDetails
                            )
                        )
                    }
                }
            }
        }
        return results
    }
    
    // Grouped by control name to clean up the UI
    private var groupedResults: [(control: EssentialControl, results: [SearchResult])] {
        let results = searchResults
        let grouped = Dictionary(grouping: results, by: { $0.control.id })
        
        return EssentialControlsData.all.compactMap { control in
            guard let controlResults = grouped[control.id], !controlResults.isEmpty else {
                return nil
            }
            return (control: control, results: controlResults)
        }
    }
    
    var body: some View {
        VStack {
            if searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                    Text("Search technical details")
                        .font(.headline)
                    Text("Search registry paths, GPO settings, commands, or controls across the entire knowledge base.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else if searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                    Text("No results found")
                        .font(.headline)
                    Text("Try searching for terms like 'HKLM', 'AppLocker', 'Registry', 'sc config', or 'block'.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                List {
                    ForEach(groupedResults, id: \.control.id) { group in
                        Section {
                            ForEach(group.results) { result in
                                NavigationLink {
                                    MaturityLevelView(
                                        controlID: result.control.id,
                                        controlName: result.control.name,
                                        level: result.level,
                                        content: result.content
                                    )
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Step \(result.stepNumber + 1)")
                                                .font(.caption.bold())
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(result.level.shortName)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1), in: Capsule())
                                                .foregroundStyle(.blue)
                                        }
                                        
                                        Text(result.step.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text(result.step.description)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                        
                                        if !result.matchedDetails.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Matching Detail:")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.secondary)
                                                    .padding(.top, 2)
                                                ForEach(result.matchedDetails, id: \.self) { detail in
                                                    Text(detail)
                                                        .font(.system(.caption2, design: .monospaced))
                                                        .foregroundStyle(.primary)
                                                        .textSelection(.enabled)
                                                        .padding(.vertical, 4)
                                                        .padding(.horizontal, 8)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                                        )
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: group.control.iconSystemName)
                                Text(group.control.name)
                            }
                            .font(.subheadline.bold())
                        }
                    }
                }
            }
        }
        .navigationTitle("Global Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search GPOs, registries, commands...")
    }
}

#Preview {
    NavigationStack {
        GlobalSearchView()
    }
}
