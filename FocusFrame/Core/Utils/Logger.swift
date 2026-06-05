import Foundation
import os

enum AppLogger {
    static let processing = Logger(subsystem: "com.jinho.FocusFrame", category: "Processing")
    static let export = Logger(subsystem: "com.jinho.FocusFrame", category: "Export")
}

