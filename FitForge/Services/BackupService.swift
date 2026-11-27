import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Backs up and restores everything FitForge stores.
///
/// Automatic backups go to a folder the user picks once (ideally in iCloud Drive), so they survive
/// even if the app is removed. One file per day ("FitForge Backup 2026-11-26.json"), rewritten each
/// time the app goes to the background that day, keeping the last 30 days.
@MainActor
enum BackupService {
    enum Keys {
        static let bookmark = "backup.folderBookmark"
        static let folderName = "backup.folderName"
        /// Seconds since 1970 of the last successful backup (0 = never).
        static let lastBackup = "backup.lastDate"
        /// Why the last automatic backup failed ("" when it worked).
        static let lastError = "backup.lastError"
    }

    static let keepDailyBackups = 30
    private static let dailyPrefix = "FitForge Backup "
    private static let defaults = UserDefaults.standard

    // MARK: - Making and reading backups

    static func snapshot(of context: ModelContext) throws -> BackupFile {
        var file = BackupFile()
        file.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        file.profiles = try context.fetch(FetchDescriptor<UserProfile>()).map { ProfileRecord($0) }
        file.weighIns = try context.fetch(FetchDescriptor<BodyMeasurement>(sortBy: [SortDescriptor(\.date)])).map { WeighInRecord($0) }
        file.tapeMeasurements = try context.fetch(FetchDescriptor<TapeMeasurement>(sortBy: [SortDescriptor(\.date)])).map { TapeRecord($0) }
        file.workouts = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startDate)])).map { WorkoutRecord($0) }
        return file
    }

    static func encode(_ file: BackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file: BackupFile
        do {
            file = try decoder.decode(BackupFile.self, from: data)
        } catch {
            throw BackupError.unreadable
        }
        guard file.version <= BackupFile.currentVersion else { throw BackupError.newerVersion }
        return file
    }

    /// Reads a backup file the user picked (e.g. from Files).
    static func read(from url: URL) throws -> BackupFile {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        var coordinatorError: NSError?
        var result: Result<Data, Error> = .failure(BackupError.unreadable)
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinatorError) { readURL in
            result = Result { try Data(contentsOf: readURL) }
        }
        if coordinatorError != nil { throw BackupError.unreadable }
        return try decode(result.get())
    }

    // MARK: - Backup folder

    static var hasFolder: Bool { defaults.data(forKey: Keys.bookmark) != nil }

    /// Remembers the folder the user picked, so backups can be written there later.
    static func setFolder(_ url: URL) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        defaults.set(bookmark, forKey: Keys.bookmark)
        defaults.set(url.lastPathComponent, forKey: Keys.folderName)
        defaults.set("", forKey: Keys.lastError)
    }

    private static func folderURL() throws -> URL {
        guard let bookmark = defaults.data(forKey: Keys.bookmark) else { throw BackupError.noFolder }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            throw BackupError.folderUnavailable
        }
        if isStale { try? setFolder(url) }
        return url
    }

    // MARK: - Backing up

    /// Writes today's backup to the backup folder. Returns the file name.
    @discardableResult
    static func backUpNow(_ context: ModelContext) throws -> String {
        do {
            let file = try snapshot(of: context)
            let name = dailyPrefix + dayStamp(.now) + ".json"
            try write(encode(file), named: name)
            prune()
            defaults.set(Date.now.timeIntervalSince1970, forKey: Keys.lastBackup)
            defaults.set("", forKey: Keys.lastError)
            return name
        } catch {
            defaults.set(error.localizedDescription, forKey: Keys.lastError)
            throw error
        }
    }

    /// Backs up quietly if a folder is set. Called when the app opens and goes to the background.
    static func autoBackup(_ context: ModelContext) {
        guard hasFolder else { return }
        // Never overwrite a backup with an app that hasn't been set up yet.
        guard let profiles = try? context.fetchCount(FetchDescriptor<UserProfile>()), profiles > 0 else { return }
        _ = try? backUpNow(context)
    }

    private static func write(_ data: Data, named name: String) throws {
        let folder = try folderURL()
        let accessing = folder.startAccessingSecurityScopedResource()
        defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

        let target = folder.appending(path: name)
        var coordinatorError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: target, options: .forReplacing, error: &coordinatorError) { writeURL in
            do { try data.write(to: writeURL, options: .atomic) } catch { writeError = error }
        }
        if coordinatorError != nil || writeError != nil { throw BackupError.folderUnavailable }
    }

    /// Keeps only the newest daily backups.
    private static func prune() {
        guard let folder = try? folderURL() else { return }
        let accessing = folder.startAccessingSecurityScopedResource()
        defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))) ?? []
        let daily = names.filter { $0.hasPrefix(dailyPrefix) && $0.hasSuffix(".json") }.sorted()
        for name in daily.dropLast(keepDailyBackups) {
            let url = folder.appending(path: name)
            var coordinatorError: NSError?
            NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorError) { deleteURL in
                try? FileManager.default.removeItem(at: deleteURL)
            }
        }
    }

    // MARK: - Restoring

    /// Replaces everything in the app with the backup. A copy of the current data is saved first.
    /// Returns where that copy went, or nil if there was nothing to save.
    @discardableResult
    static func restore(_ file: BackupFile, into context: ModelContext) throws -> String? {
        let safetyCopy = try saveSafetyCopy(context)
        do {
            try deleteEverything(in: context)
            file.profiles.forEach { $0.insert(into: context) }
            file.weighIns.forEach { context.insert($0.makeModel()) }
            file.tapeMeasurements.forEach { context.insert($0.makeModel()) }
            file.workouts.forEach { $0.insert(into: context) }
            try context.save()
        } catch {
            context.rollback()
            throw BackupError.restoreFailed
        }
        return safetyCopy
    }

    /// Saves what's in the app right now, in case a restore was a mistake.
    private static func saveSafetyCopy(_ context: ModelContext) throws -> String? {
        let current = try snapshot(of: context)
        let isEmpty = current.profiles.isEmpty && current.workouts.isEmpty
            && current.weighIns.isEmpty && current.tapeMeasurements.isEmpty
        guard !isEmpty else { return nil }

        let data = try encode(current)
        let name = "FitForge Before Restore \(timeStamp(.now)).json"
        if hasFolder, (try? write(data, named: name)) != nil {
            let folder = defaults.string(forKey: Keys.folderName) ?? "your backup folder"
            return "\(folder) › \(name)"
        }
        try data.write(to: URL.documentsDirectory.appending(path: name), options: .atomic)
        return "FitForge's own storage (\(name))"
    }

    private static func deleteEverything(in context: ModelContext) throws {
        try context.fetch(FetchDescriptor<SetLog>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<WorkoutSession>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<EquipmentItem>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<UserProfile>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<BodyMeasurement>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<TapeMeasurement>()).forEach { context.delete($0) }
    }

    // MARK: - Names

    /// e.g. "2026-11-26", in local time.
    private static func dayStamp(_ date: Date) -> String {
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day().format(date)
    }

    /// e.g. "2026-11-26 19.42" (no colons — they aren't allowed in file names).
    private static func timeStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm"
        return formatter.string(from: date)
    }
}

enum BackupError: LocalizedError {
    case noFolder, folderUnavailable, unreadable, newerVersion, restoreFailed

    var errorDescription: String? {
        switch self {
        case .noFolder: "No backup folder chosen yet."
        case .folderUnavailable: "Couldn't reach the backup folder. Try choosing it again."
        case .unreadable: "That file isn't a FitForge backup, or it's damaged."
        case .newerVersion: "That backup was made by a newer version of FitForge. Update the app first."
        case .restoreFailed: "The restore didn't finish, so nothing was changed."
        }
    }
}

/// A backup file for "Save a copy…".
nonisolated struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Restores a backup from anywhere in the app (handled by RootView, which swaps the screens
/// out while the data is replaced). Call it like a function: `restoreBackup(file)`.
struct RestoreBackupAction {
    var perform: (BackupFile) -> Void = { _ in }

    func callAsFunction(_ file: BackupFile) {
        perform(file)
    }
}

extension EnvironmentValues {
    @Entry var restoreBackup = RestoreBackupAction()
}
