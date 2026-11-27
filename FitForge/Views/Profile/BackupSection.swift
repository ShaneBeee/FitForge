import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Profile › Backup: pick the backup folder, back up now, save a copy, restore.
struct BackupSection: View {
    @Environment(\.modelContext) private var context
    @AppStorage(BackupService.Keys.lastBackup) private var lastBackup: Double = 0
    @AppStorage(BackupService.Keys.lastError) private var lastError = ""
    @AppStorage(BackupService.Keys.folderName) private var folderName = ""

    @State private var pickerMode: PickerMode = .folder
    @State private var showPicker = false
    @State private var showExporter = false
    @State private var exportDocument: BackupDocument?
    @State private var pendingRestore: BackupFile?
    @State private var message: String?

    private enum PickerMode { case folder, restore }

    private var hasFolder: Bool { !folderName.isEmpty }

    var body: some View {
        Section {
            LabeledContent("Folder", value: hasFolder ? folderName : "Not chosen")
            LabeledContent("Last backup") {
                if lastBackup > 0 {
                    Text(Date(timeIntervalSince1970: lastBackup), format: .relative(presentation: .named))
                } else {
                    Text("Never")
                }
            }
            if hasFolder, !lastError.isEmpty {
                Label(lastError, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            Button(hasFolder ? "Change backup folder" : "Choose backup folder") { pick(.folder) }
            if hasFolder {
                Button("Back up now") { backUpNow() }
            }
            Button("Save a copy somewhere else…") { saveCopy() }
            Button("Restore from a backup…") { pick(.restore) }
                .disabled(!hasFolder)
                .restoreConfirmation($pendingRestore)
        } header: {
            Text("Backup")
        } footer: {
            Text(footerText)
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: pickerMode == .folder ? [.folder] : [.json]
        ) { result in
            handlePick(result)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "FitForge Backup \(Date.now.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day()))"
        ) { result in
            if case .failure(let error) = result { message = error.localizedDescription }
        }
        .alert(
            "Backup",
            isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } }),
            presenting: message
        ) { _ in
            Button("OK") {}
        } message: { text in
            Text(text)
        }
    }

    private var footerText: String {
        if hasFolder {
            return "Backs up automatically every time you leave FitForge: one file per day, keeping the last \(BackupService.keepDailyBackups) days. Restoring replaces everything in the app, after saving a copy of what's there now."
        }
        return "Pick a folder in iCloud Drive (for example, make a folder called “FitForge Backups”) and FitForge will back up there automatically. Backups in iCloud Drive survive even if the app is removed or your phone is lost."
    }

    // MARK: - Actions

    private func pick(_ mode: PickerMode) {
        pickerMode = mode
        showPicker = true
    }

    private func handlePick(_ result: Result<URL, Error>) {
        let url: URL
        switch result {
        case .success(let picked): url = picked
        case .failure(let error):
            message = error.localizedDescription
            return
        }

        switch pickerMode {
        case .folder:
            do {
                try BackupService.setFolder(url)
                try BackupService.backUpNow(context)
                message = "Backups will be saved in “\(url.lastPathComponent)”. The first one is already there."
            } catch {
                message = error.localizedDescription
            }
        case .restore:
            do {
                pendingRestore = try BackupService.read(from: url)
            } catch {
                message = error.localizedDescription
            }
        }
    }

    private func backUpNow() {
        do {
            let name = try BackupService.backUpNow(context)
            message = "Saved “\(name)” in \(folderName)."
        } catch {
            message = error.localizedDescription
        }
    }

    private func saveCopy() {
        do {
            exportDocument = BackupDocument(data: try BackupService.encode(BackupService.snapshot(of: context)))
            showExporter = true
        } catch {
            message = error.localizedDescription
        }
    }
}

/// Setup's first screen: restore a backup instead of starting from scratch.
struct RestoreFromBackupCard: View {
    @State private var showPicker = false
    @State private var pending: BackupFile?
    @State private var errorText: String?

    var body: some View {
        FormCard {
            Label("Coming back?", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(Theme.teal)
            Text("If you have a FitForge backup, restore it to pick up right where you left off.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showPicker = true
            } label: {
                Text("Restore from a backup")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .tint(Theme.teal)
            .alert(
                "Couldn't open that file",
                isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })
            ) {
                Button("OK") {}
            } message: {
                Text(errorText ?? "")
            }
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                do { pending = try BackupService.read(from: url) } catch { errorText = error.localizedDescription }
            case .failure(let error):
                errorText = error.localizedDescription
            }
        }
        .restoreConfirmation($pending)
    }
}

/// "Restore this backup?" — then hands the backup to RootView to do the restore.
private struct RestoreConfirmation: ViewModifier {
    @Binding var pending: BackupFile?
    @Environment(\.restoreBackup) private var restoreBackup

    func body(content: Content) -> some View {
        content.alert(
            "Restore this backup?",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
            presenting: pending
        ) { file in
            Button("Restore") { restoreBackup(file) }
            Button("Cancel", role: .cancel) {}
        } message: { file in
            Text("Backup from \(file.createdAt.formatted(date: .abbreviated, time: .shortened)): \(file.summary).\n\nThis replaces everything in FitForge right now. A copy of what's there now is saved first, in case you change your mind.")
        }
    }
}

extension View {
    fileprivate func restoreConfirmation(_ pending: Binding<BackupFile?>) -> some View {
        modifier(RestoreConfirmation(pending: pending))
    }
}
