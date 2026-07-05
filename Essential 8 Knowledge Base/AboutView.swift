//
//  AboutView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressStore: ProgressStore
    @AppStorage("referenceOnlyMode") private var referenceOnlyMode = false
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        Text(AppInformation.aboutDescription)
                            .font(.body)
                    } icon: {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(.tint)
                    }
                    Text(AppInformation.contentScope)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Purpose")
                }

                Section {
                    Text(AppInformation.aboutMeDescription)
                        .font(.body)

                    ForEach(AppInformation.authorLinks) { reference in
                        Link(destination: reference.url) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reference.title)
                                        .font(.body)
                                    Text(reference.hostDisplayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "person.crop.circle")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .accessibilityLabel("\(reference.title), \(reference.hostDisplayName)")
                    }
                } header: {
                    Text(AppInformation.aboutMeTitle)
                }

                Section {
                    Text(AppInformation.privacyPolicy)
                        .font(.body)

                    Link(destination: AppInformation.privacyPolicyLink.url) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppInformation.privacyPolicyLink.title)
                                    .font(.body)
                                Text(AppInformation.privacyPolicyLink.hostDisplayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "hand.raised")
                                .foregroundStyle(.tint)
                        }
                    }
                    .accessibilityLabel("\(AppInformation.privacyPolicyLink.title), \(AppInformation.privacyPolicyLink.hostDisplayName)")
                } header: {
                    Text(AppInformation.privacyTitle)
                }

                Section {
                    Link(destination: AppInformation.reviewURL) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate the App")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text("Write a star rating review on the App Store")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.tint)
                        }
                    }

                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label {
                            Text("Reset App Data")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                } header: {
                    Text("Tools & Feedback")
                }

                Section {
                    Toggle("Reference Only Mode", isOn: $referenceOnlyMode)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Hides the compliance dashboard on the home screen.")
                }

                Section {
                    ForEach(AppInformation.referenceLinks) { reference in
                        Link(destination: reference.url) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reference.title)
                                        .font(.body)
                                    Text(reference.hostDisplayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "link")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .accessibilityLabel("\(reference.title), \(reference.hostDisplayName)")
                    }
                } header: {
                    Text("References")
                } footer: {
                    Text("External links open outside the app and should be used to verify current ASD and Microsoft guidance before implementation.")
                        .font(.footnote)
                }
            }
            .navigationTitle(AppInformation.aboutTitle)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset App Data", isPresented: $showingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    progressStore.resetAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all mitigation statuses and Microsoft 365 licensing settings back to defaults. This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AboutView()
        .environmentObject(ProgressStore.shared)
}
