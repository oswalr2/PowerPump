import Foundation
import os

/// Loading stored history must never silently turn into "no history": the
/// next save() would overwrite the stored data and wipe it for good (e.g.
/// after a model gains a new non-optional field). When the strict decode
/// fails, these helpers keep every element that still decodes and copy the
/// raw data to "<key>_backup" so nothing is lost.
enum SafeDecoding {
    private static let log = Logger(subsystem: "com.oswaldo.powerpump", category: "persistence")

    /// Decodes `[T]`, falling back to element-by-element decoding.
    /// Returns nil only if the data isn't a JSON array at all (raw data is
    /// still backed up in that case).
    static func decodeArray<T: Decodable>(_ type: T.Type, from data: Data, backupKey: String) -> [T]? {
        if let strict = try? JSONDecoder().decode([T].self, from: data) { return strict }
        backup(data, key: backupKey)
        guard let lossy = try? JSONDecoder().decode([Failable<T>].self, from: data) else {
            log.error("Could not decode \(backupKey, privacy: .public); raw data backed up")
            return nil
        }
        let kept = lossy.compactMap(\.value)
        log.error("Lossy decode of \(backupKey, privacy: .public): kept \(kept.count)/\(lossy.count); raw data backed up")
        return kept
    }

    /// Same as `decodeArray`, for stores shaped as `[String: [T]]`.
    static func decodeDictionaryOfArrays<T: Decodable>(_ type: T.Type, from data: Data, backupKey: String) -> [String: [T]]? {
        if let strict = try? JSONDecoder().decode([String: [T]].self, from: data) { return strict }
        backup(data, key: backupKey)
        guard let lossy = try? JSONDecoder().decode([String: [Failable<T>]].self, from: data) else {
            log.error("Could not decode \(backupKey, privacy: .public); raw data backed up")
            return nil
        }
        log.error("Lossy decode of \(backupKey, privacy: .public); raw data backed up")
        return lossy.mapValues { $0.compactMap(\.value) }
    }

    /// Keeps the first backup: a later failure must not replace good data
    /// with data that was already re-saved in lossy form.
    private static func backup(_ data: Data, key: String) {
        let backupKey = "\(key)_backup"
        guard UserDefaults.standard.data(forKey: backupKey) == nil else { return }
        UserDefaults.standard.set(data, forKey: backupKey)
    }

    private struct Failable<T: Decodable>: Decodable {
        let value: T?
        init(from decoder: Decoder) throws {
            value = try? T(from: decoder)
        }
    }
}
