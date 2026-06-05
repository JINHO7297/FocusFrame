import Foundation

enum FileManagerHelper {
    static func temporaryURL(fileExtension: String) -> URL {
        let normalizedExtension = fileExtension.isEmpty ? "mov" : fileExtension
        return FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(normalizedExtension)
    }

    static func exportURL(fileExtension: String = "mp4") -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("FocusFrameExports", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
            .appendingPathComponent("focusframe-\(UUID().uuidString)")
            .appendingPathExtension(fileExtension)
    }

    static func replaceItemIfNeeded(from source: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }
}

