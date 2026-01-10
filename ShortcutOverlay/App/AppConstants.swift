import Foundation

/// Centralized app constants derived from bundle configuration
enum AppConstants {
    /// App display name from Info.plist (CFBundleName)
    static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "HotKeyOwl"

    /// Bundle identifier from Info.plist
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.docketai.HotKeyOwl"

    /// App Support directory name (used for data storage)
    static let appSupportDirectoryName = "HotKeyOwl"
}
