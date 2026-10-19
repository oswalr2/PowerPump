import Foundation
import UIKit
import os

/// Histories that keep growing (runs with their GPS routes, gym workouts,
/// food logs, sport sessions) live in files instead of UserDefaults.
/// UserDefaults keeps its whole plist in memory and rewrites it on every
/// change, so months of routes slowed down launch and every save.
///
/// Files go to Application Support/History, are written atomically and stay
/// readable while the phone is locked after the first unlock, so a run
/// finished with the screen off is still saved.
enum DiskStore {
    private static let queue = DispatchQueue(label: "sb.diskstore", qos: .utility)
    private static let log = Logger(subsystem: "com.oswaldo.powerpump", category: "persistence")

    static let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("History", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func url(_ name: String) -> URL {
        directory.appendingPathComponent(name + ".json")
    }

    /// The stored bytes for `name`. The first time, data still kept in
    /// UserDefaults under `legacyKey` is moved into the file; the old key is
    /// removed only once the file reads back identical.
    static func data(_ name: String, legacyKey: String? = nil) -> Data? {
        queue.sync {
            let file = url(name)
            if let stored = try? Data(contentsOf: file) { return stored }
            guard let legacyKey,
                  let legacy = UserDefaults.standard.data(forKey: legacyKey) else { return nil }
            do {
                try write(legacy, to: file)
                if (try? Data(contentsOf: file)) == legacy {
                    UserDefaults.standard.removeObject(forKey: legacyKey)
                }
            } catch {
                log.error("Moving \(legacyKey, privacy: .public) to disk failed: \(error.localizedDescription, privacy: .public)")
            }
            return legacy
        }
    }

    /// Encodes and writes on a background queue, in order, so saving a long
    /// history never blocks the UI. iOS is asked for a little extra time so a
    /// save made right before the app goes to the background still lands.
    static func save<T: Encodable>(_ value: T, as name: String) {
        let task = UIApplication.shared.beginBackgroundTask(withName: "save \(name)")
        queue.async {
            defer { DispatchQueue.main.async { UIApplication.shared.endBackgroundTask(task) } }
            do {
                try write(try JSONEncoder().encode(value), to: url(name))
            } catch {
                log.error("Saving \(name, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Deletes the file, after any save still queued for it.
    static func remove(_ name: String) {
        queue.async { try? FileManager.default.removeItem(at: url(name)) }
    }

    /// Blocks until every pending save has been written.
    static func flush() {
        queue.sync {}
    }

    private static func write(_ data: Data, to file: URL) throws {
        try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
