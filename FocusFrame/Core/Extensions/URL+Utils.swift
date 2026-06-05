import Foundation

extension URL {
    var fileDisplayName: String {
        lastPathComponent.isEmpty ? "Untitled video" : lastPathComponent
    }

    var fileSizeInBytes: Int64? {
        (try? resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
    }
}

