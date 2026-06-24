//
//  AboutView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

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
}
