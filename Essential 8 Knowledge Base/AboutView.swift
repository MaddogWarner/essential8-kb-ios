import SwiftUI
import UniformTypeIdentifiers

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressStore: ProgressStore
    @AppStorage("referenceOnlyMode") private var referenceOnlyMode = false
    @AppStorage("multiProfileEnabled") private var multiProfileEnabled = false
    @AppStorage("deepAuditEnabled") private var deepAuditEnabled = false
    @State private var showingResetConfirmation = false
    @State private var showingImporter = false
    @State private var pendingImport: BackupFile?
    @State private var showingImportConfirmation = false
    @State private var backupErrorMessage: String?
    @State private var exportURL: URL?
    @State private var showingExportSheet = false
    @State private var showingExportOptions = false

    private var scopeBinding: Binding<String> {
        Binding(
            get: { progressStore.osScope.rawValue },
            set: { progressStore.osScope = OSScope(rawValue: $0) ?? .both }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label { Text(AppInformation.aboutDescription) } icon: {
                        Image(systemName: "shield.lefthalf.filled").foregroundStyle(.tint)
                    }
                    Text(AppInformation.contentScope).font(.footnote).foregroundStyle(.secondary)
                } header: { Text("Purpose") }

                Section {
                    Text(AppInformation.aboutMeDescription)
                    ForEach(AppInformation.authorLinks) { reference in
                        referenceLink(reference, icon: "person.crop.circle")
                    }
                } header: { Text(AppInformation.aboutMeTitle) }

                Section {
                    Text(AppInformation.privacyPolicy)
                    referenceLink(AppInformation.privacyPolicyLink, icon: "hand.raised")
                } header: { Text(AppInformation.privacyTitle) }

                Section {
                    Toggle("Multiple Profiles", isOn: $multiProfileEnabled)
                    Toggle("Deep Audit Mode", isOn: $deepAuditEnabled)
                } header: { Text("Assessment Features") } footer: {
                    Text("Multiple Profiles lets you track separate environments or organisations, each with its own progress, settings and audit history. Deep Audit Mode records a timestamped, optionally-annotated history for every status change in the active profile.")
                }

                if multiProfileEnabled {
                    Section {
                        NavigationLink {
                            ProfilesView()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Profiles")
                                    Text(progressStore.activeProfile.name).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: { Image(systemName: "person.2") }
                        }
                    } footer: {
                        Text("The active profile determines what every screen shows. Switching profiles changes the dashboard, steps and audit history.")
                    }
                }

                Section {
                    Link(destination: AppInformation.reviewURL) {
                        Label("Rate the App", systemImage: "star.fill")
                    }
                    Button(role: .destructive) { showingResetConfirmation = true } label: {
                        Label("Reset App Data", systemImage: "trash")
                    }
                } header: { Text("Tools & Feedback") }

                Section {
                    Button {
                        if progressStore.profiles.count > 1 { showingExportOptions = true }
                        else { prepareExport(allProfiles: false) }
                    } label: { Label("Export Backup", systemImage: "square.and.arrow.up") }
                    Button { showingImporter = true } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                } header: { Text("Backup & Restore") } footer: {
                    Text("Backups are plain JSON containing your profiles — step statuses, N/A reasons, audit history and per-profile settings. Export this profile to share one assessment, or all profiles to move everything to another device. They never leave your device unless you share them.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OS Scope").font(.caption).foregroundStyle(.secondary)
                        Picker("OS scope", selection: scopeBinding) {
                            Text("Workstation").tag(OSScope.workstation.rawValue)
                            Text("Server").tag(OSScope.server.rawValue)
                            Text("Both").tag(OSScope.both.rawValue)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("OS scope")
                    }
                    Toggle("Reference Only Mode", isOn: $referenceOnlyMode)
                } header: { Text("Preferences") } footer: {
                    Text("OS scope hides implementation steps that don't apply to the selected environment and recalculates compliance over the remaining steps. Reference Only Mode hides the compliance dashboard on the home screen.")
                }

                Section {
                    ForEach(AppInformation.referenceLinks) { reference in
                        referenceLink(reference, icon: "link")
                    }
                } header: { Text("References") } footer: {
                    Text("External links open outside the app and should be used to verify current ASD and Microsoft guidance before implementation.")
                }

                Section {
                    Text(AppInformation.versionDisplay)
                        .font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle(AppInformation.aboutTitle)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Export Backup", isPresented: $showingExportOptions) {
                Button("This profile only") { prepareExport(allProfiles: false) }
                Button("All profiles") { prepareExport(allProfiles: true) }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Reset App Data", isPresented: $showingResetConfirmation) {
                Button("Reset", role: .destructive) { progressStore.resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all profiles, progress, audit history and app settings. This action cannot be undone.")
            }
            .alert(importTitle, isPresented: $showingImportConfirmation, presenting: pendingImport) { backup in
                if backup.globalSettings != nil {
                    Button("Replace", role: .destructive) { applyImport(backup) }
                } else {
                    Button("Import") { applyImport(backup) }
                }
                Button("Cancel", role: .cancel) { pendingImport = nil }
            } message: { backup in Text(importMessage(for: backup)) }
            .alert("Backup Error", isPresented: Binding(
                get: { backupErrorMessage != nil },
                set: { if !$0 { backupErrorMessage = nil } }
            )) { Button("OK") { backupErrorMessage = nil } } message: {
                Text(backupErrorMessage ?? "An unknown error occurred.")
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { handleImport($0) }
            .sheet(isPresented: $showingExportSheet, onDismiss: cleanUpExport) {
                if let exportURL {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.badge.arrow.up").font(.system(size: 48)).foregroundStyle(.tint)
                            Text("Backup ready to share").font(.headline)
                            ShareLink(item: exportURL) {
                                Label("Share Backup", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                            }.buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showingExportSheet = false } } }
                    }.presentationDetents([.medium])
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var importTitle: String { pendingImport?.globalSettings == nil ? "Import profile?" : "Replace everything?" }

    @ViewBuilder
    private func referenceLink(_ reference: ReferenceLink, icon: String) -> some View {
        Link(destination: reference.url) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reference.title)
                    Text(reference.hostDisplayName).font(.caption).foregroundStyle(.secondary)
                }
            } icon: { Image(systemName: icon).foregroundStyle(.tint) }
        }
        .accessibilityLabel("\(reference.title), \(reference.hostDisplayName)")
    }

    private func prepareExport(allProfiles: Bool) {
        do {
            let backup = try allProfiles ? progressStore.exportAllProfiles() : progressStore.exportActiveProfile()
            let data = try BackupFile.encode(backup)
            let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
            let prefix = allProfiles ? "AllProfiles" : sanitised(progressStore.activeProfile.name)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Essential8-\(prefix)-\(formatter.string(from: backup.exportedAt)).json")
            try data.write(to: url, options: .atomic)
            exportURL = url
            showingExportSheet = true
        } catch { backupErrorMessage = error.localizedDescription }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > BackupFile.maximumFileSize { throw BackupError.fileTooLarge }
            let handle = try FileHandle(forReadingFrom: url); defer { try? handle.close() }
            pendingImport = try BackupFile.decode(try handle.read(upToCount: BackupFile.maximumFileSize + 1) ?? Data())
            showingImportConfirmation = true
        } catch { backupErrorMessage = (error as? LocalizedError)?.errorDescription ?? "The selected backup could not be read." }
    }

    private func applyImport(_ backup: BackupFile) {
        if backup.globalSettings != nil { progressStore.importFullDevice(backup) }
        else { progressStore.importAsNewProfile(backup) }
        pendingImport = nil
    }

    private func importMessage(for backup: BackupFile) -> String {
        let count = backup.profiles.count
        if backup.globalSettings != nil {
            return "This replaces all profiles and app settings with the backup from \(importDate(backup.exportedAt)) (\(count) profile(s), app version \(backup.appVersion)). This cannot be undone."
        }
        return "This adds \(count) profile(s) from the backup of \(importDate(backup.exportedAt)) (app version \(backup.appVersion)). Your existing profiles are unchanged."
    }

    private func sanitised(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let result = name.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
        return String(result).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func cleanUpExport() { if let exportURL { try? FileManager.default.removeItem(at: exportURL) }; exportURL = nil }
    private func importDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_AU"); formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview { AboutView().environmentObject(ProgressStore.shared) }
