import SwiftUI

struct CredentialEditor: View {
    let title: String
    let detail: String
    let accent: Color
    let load: () throws -> String?
    let save: (String) throws -> Void
    let remove: () throws -> Void
    var onRemove: () -> Void = {}

    @State private var draft = ""
    @State private var hasStoredValue = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text(detail).font(.footnote).foregroundStyle(.secondary)
            SecretEntryField(title: title, value: $draft)
                .frame(maxWidth: 500)
            HStack(spacing: 8) {
                TrendsActionButton(title: "Save", systemImage: "checkmark", tint: .green) {
                    saveDraft()
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if hasStoredValue {
                    TrendsActionButton(title: "Remove", systemImage: "trash", tint: .red,
                                       role: .destructive) {
                        removeStored()
                    }
                }
                Text(hasStoredValue ? "Saved in Keychain" : "Not configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: accent)
        .onAppear { reload() }
        .onDisappear { draft = "" }
    }

    private func reload() {
        do {
            draft = try load() ?? ""
            hasStoredValue = !draft.isEmpty
            message = nil
        } catch {
            draft = ""
            hasStoredValue = false
            message = error.localizedDescription
        }
    }

    private func saveDraft() {
        do {
            try save(draft)
            reload()
            message = "Saved on this device."
        } catch {
            message = error.localizedDescription
        }
    }

    private func removeStored() {
        do {
            try remove()
            draft = ""
            hasStoredValue = false
            message = "Removed from Keychain."
            onRemove()
        } catch {
            message = error.localizedDescription
        }
    }
}
