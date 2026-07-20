import SwiftUI

struct ProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressStore: ProgressStore
    @State private var showingCreate = false
    @State private var profileName = ""
    @State private var profileToRename: Profile?
    @State private var profileToDelete: Profile?

    var body: some View {
        List {
            ForEach(progressStore.profiles) { profile in
                Button {
                    progressStore.switchProfile(to: profile.id)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name).foregroundStyle(.primary)
                            Text(Self.dateFormatter.string(from: profile.createdAt)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if profile.id == progressStore.activeProfileID { Image(systemName: "checkmark").foregroundStyle(.tint) }
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Rename") { profileName = profile.name; profileToRename = profile }.tint(.blue)
                }
                .swipeActions(edge: .trailing) {
                    if progressStore.profiles.count > 1 {
                        Button("Delete", role: .destructive) { profileToDelete = profile }
                    }
                }
            }
        }
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { profileName = ""; showingCreate = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add Profile")
            }
        }
        .alert("Create Profile", isPresented: $showingCreate) {
            TextField("Profile name", text: $profileName)
            Button("Create") { let id = progressStore.createProfile(named: profileName); progressStore.switchProfile(to: id) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename Profile", isPresented: Binding(get: { profileToRename != nil }, set: { if !$0 { profileToRename = nil } })) {
            TextField("Profile name", text: $profileName)
            Button("Save") { if let profileToRename { progressStore.renameProfile(profileToRename.id, to: profileName) }; profileToRename = nil }
            Button("Cancel", role: .cancel) { profileToRename = nil }
        }
        .alert("Delete profile?", isPresented: Binding(get: { profileToDelete != nil }, set: { if !$0 { profileToDelete = nil } }), presenting: profileToDelete) { profile in
            Button("Delete", role: .destructive) { progressStore.deleteProfile(profile.id); profileToDelete = nil }
            Button("Cancel", role: .cancel) { profileToDelete = nil }
        } message: { profile in
            Text("Delete profile '\(profile.name)'? Its progress and audit history are permanently removed.")
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_AU"); formatter.dateFormat = "dd/MM/yyyy"; return formatter
    }()
}
