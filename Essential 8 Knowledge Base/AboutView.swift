//
//  AboutView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI
import UniformTypeIdentifiers

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressStore: ProgressStore
    @AppStorage("referenceOnlyMode") private var referenceOnlyMode = false
    @AppStorage("osScopeFilter") private var osScopeRawValue = OSScope.both.rawValue
    @State private var showingResetConfirmation = false
    @State private var showingImporter = false
    @State private var pendingImport: BackupFile?
    @State private var showingImportConfirmation = false
    @State private var backupErrorMessage: String?
    @State private var exportURL: URL?
    @State private var showingExportSheet = false

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
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup & Restore")
                } footer: {
                    Text("Backups are plain JSON containing your step statuses, N/A reasons and app settings. They never leave your device unless you share them. Importing replaces all current data.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OS Scope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("OS scope", selection: $osScopeRawValue) {
                            Text("Workstation").tag(OSScope.workstation.rawValue)
                            Text("Server").tag(OSScope.server.rawValue)
                            Text("Both").tag(OSScope.both.rawValue)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("OS scope")
                    }
                    Toggle("Reference Only Mode", isOn: $referenceOnlyMode)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("OS scope hides implementation steps that don't apply to the selected environment and recalculates compliance over the remaining steps. Reference Only Mode hides the compliance dashboard on the home screen.")
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

                Section {
                    Text(AppInformation.versionDisplay)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
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
            .alert("Replace all app data?", isPresented: $showingImportConfirmation, presenting: pendingImport) { backup in
                Button("Replace", role: .destructive) {
                    progressStore.importBackup(backup)
                    pendingImport = nil
                }
                Button("Cancel", role: .cancel) { pendingImport = nil }
            } message: { backup in
                Text("This will replace all step statuses and settings with the backup from \(importDate(backup.exportedAt)) (app version \(backup.appVersion)). This cannot be undone.")
            }
            .alert("Backup Error", isPresented: Binding(
                get: { backupErrorMessage != nil },
                set: { if !$0 { backupErrorMessage = nil } }
            )) {
                Button("OK") { backupErrorMessage = nil }
            } message: {
                Text(backupErrorMessage ?? "An unknown error occurred.")
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showingExportSheet, onDismiss: cleanUpExport) {
                if let exportURL {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.badge.arrow.up")
                                .font(.system(size: 48))
                                .foregroundStyle(.tint)
                            Text("Backup ready to share")
                                .font(.headline)
                            ShareLink(item: exportURL) {
                                Label("Share Backup", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingExportSheet = false }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
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

    private func prepareExport() {
        do {
            let backup = try progressStore.exportBackup()
            let data = try BackupFile.encode(backup)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Essential8-Backup-\(formatter.string(from: backup.exportedAt)).json")
            try data.write(to: url, options: .atomic)
            exportURL = url
            showingExportSheet = true
        } catch {
            backupErrorMessage = error.localizedDescription
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = values.fileSize, fileSize > BackupFile.maximumFileSize {
                throw BackupError.fileTooLarge
            }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: BackupFile.maximumFileSize + 1) ?? Data()
            pendingImport = try BackupFile.decode(data)
            showingImportConfirmation = true
        } catch {
            backupErrorMessage = (error as? LocalizedError)?.errorDescription ?? "The selected backup could not be read."
        }
    }

    private func cleanUpExport() {
        if let exportURL {
            try? FileManager.default.removeItem(at: exportURL)
        }
        exportURL = nil
    }

    private func importDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    AboutView()
        .environmentObject(ProgressStore.shared)
}
