//
//  HomeView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct HomeView: View {
    private let controls = EssentialControlsData.all
    @State private var isShowingAbout = false

    var body: some View {
        List {
            Section {
                ForEach(controls) { control in
                    NavigationLink(value: control) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(control.name)
                                    .font(.headline)
                                Text("Mitigation \(control.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: control.iconSystemName)
                                .foregroundStyle(.tint)
                                .imageScale(.large)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("ASD Essential Eight")
            } footer: {
                Text("Content is scoped to controls achievable using built-in Windows OS tooling. Verify against the current ASD Essential Eight Maturity Model before implementation.")
                    .font(.footnote)
            }

            Section {
                NavigationLink {
                    Microsoft365SettingsView()
                } label: {
                    Label("M365 Additional Controls", systemImage: "gearshape.2")
                }

                Button {
                    isShowingAbout = true
                } label: {
                    Label("About & Privacy", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Essential 8 Knowledge Base")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Essential 8 Knowledge Base")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .navigationDestination(for: EssentialControl.self) { control in
            ControlDetailView(control: control)
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
