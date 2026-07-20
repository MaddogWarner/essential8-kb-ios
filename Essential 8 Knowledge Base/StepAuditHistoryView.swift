import SwiftUI

struct StepAuditHistoryView: View {
    let stepTitle: String
    let entries: [AuditEntry]

    var body: some View {
        List(entries) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.previousState.rawValue) → \(entry.newState.rawValue)")
                    .font(.subheadline.weight(.semibold))
                Text(Self.dateFormatter.string(from: entry.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(for: entry))
        }
        .navigationTitle(stepTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func accessibilityLabel(for entry: AuditEntry) -> String {
        let date = Self.dateFormatter.string(from: entry.timestamp)
        return "\(date), changed from \(entry.previousState.rawValue) to \(entry.newState.rawValue), note: \(entry.note ?? "no note")"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter
    }()
}
