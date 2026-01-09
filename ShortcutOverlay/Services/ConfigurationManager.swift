import Foundation

/// Manages import and export of shortcuts configuration in JSON format
class ConfigurationManager {
    // MARK: - Data Structures

    struct ExportConfiguration: Codable {
        let version: String
        let exportDate: Date
        let apps: [AppShortcuts]
    }

    enum MergeStrategy {
        case replace  // Replace all shortcuts
        case merge    // Merge by app, keep existing for unlisted apps
        case append   // Add to existing, keep duplicates
    }

    // MARK: - Export Methods

    /// Export all shortcuts to a JSON file
    func exportAll(shortcuts: [String: AppShortcuts], to url: URL) throws {
        let apps = Array(shortcuts.values).sorted { $0.appName < $1.appName }
        let config = ExportConfiguration(
            version: "1.0",
            exportDate: Date(),
            apps: apps
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(config)
        try data.write(to: url)

        print("✅ Exported \(apps.count) app(s) to \(url.path)")
    }

    /// Export shortcuts for a single app
    func exportApp(_ appShortcuts: AppShortcuts, to url: URL) throws {
        let config = ExportConfiguration(
            version: "1.0",
            exportDate: Date(),
            apps: [appShortcuts]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(config)
        try data.write(to: url)

        print("✅ Exported shortcuts for \(appShortcuts.appName) to \(url.path)")
    }

    // MARK: - Import Methods

    /// Import configuration from a JSON file
    func importConfiguration(from url: URL, mergeStrategy: MergeStrategy) throws -> [String: AppShortcuts] {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let config = try decoder.decode(ExportConfiguration.self, from: data)

        // Validate version
        guard config.version == "1.0" else {
            throw ConfigurationError.incompatibleVersion(config.version)
        }

        // Convert to dictionary
        var result: [String: AppShortcuts] = [:]
        for app in config.apps {
            result[app.bundleIdentifier] = app
        }

        print("✅ Imported \(result.count) app(s) from \(url.path)")
        return result
    }

    /// Merge imported shortcuts with existing ones
    func merge(
        imported: [String: AppShortcuts],
        existing: [String: AppShortcuts],
        strategy: MergeStrategy
    ) -> [String: AppShortcuts] {
        switch strategy {
        case .replace:
            // Replace all with imported
            return imported

        case .merge:
            // Merge: Keep existing apps not in imported, replace apps that are in imported
            var result = existing
            for (bundleId, appShortcuts) in imported {
                result[bundleId] = appShortcuts
            }
            return result

        case .append:
            // Append: Add imported shortcuts to existing ones, creating app entry if needed
            var result = existing

            for (bundleId, importedApp) in imported {
                if var existingApp = result[bundleId] {
                    // App exists, append shortcuts
                    var combinedShortcuts = existingApp.shortcuts
                    combinedShortcuts.append(contentsOf: importedApp.shortcuts)
                    existingApp.shortcuts = combinedShortcuts
                    existingApp.lastModified = Date()
                    result[bundleId] = existingApp
                } else {
                    // New app, add directly
                    result[bundleId] = importedApp
                }
            }

            return result
        }
    }

    /// Export to clipboard as JSON string
    func exportToClipboard(shortcuts: [String: AppShortcuts]) throws -> String {
        let apps = Array(shortcuts.values).sorted { $0.appName < $1.appName }
        let config = ExportConfiguration(
            version: "1.0",
            exportDate: Date(),
            apps: apps
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(config)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw ConfigurationError.encodingFailed
        }

        return jsonString
    }

    /// Import from clipboard JSON string
    func importFromClipboard(_ jsonString: String) throws -> [String: AppShortcuts] {
        guard let data = jsonString.data(using: .utf8) else {
            throw ConfigurationError.invalidJSON
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let config = try decoder.decode(ExportConfiguration.self, from: data)

        // Validate version
        guard config.version == "1.0" else {
            throw ConfigurationError.incompatibleVersion(config.version)
        }

        // Convert to dictionary
        var result: [String: AppShortcuts] = [:]
        for app in config.apps {
            result[app.bundleIdentifier] = app
        }

        return result
    }

    // MARK: - Errors

    enum ConfigurationError: LocalizedError {
        case incompatibleVersion(String)
        case invalidJSON
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .incompatibleVersion(let version):
                return "Incompatible configuration version: \(version). Expected version 1.0."
            case .invalidJSON:
                return "Invalid JSON format."
            case .encodingFailed:
                return "Failed to encode configuration to JSON."
            }
        }
    }
}
