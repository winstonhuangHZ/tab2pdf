import Foundation

/// Engraving presets, mirroring LilypondStyle in the exporter.
enum ScoreStyle: String, CaseIterable, Identifiable {
    case modernCM = "modern-cm"
    case modernSans = "modern-sans"
    case lilypondDefault = "lilypond-default"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .modernCM: return "Modern (Computer Modern)"
        case .modernSans: return "Modern (sans serif)"
        case .lilypondDefault: return "LilyPond default"
        }
    }
}

/// Page spacing presets, mirroring LilypondDensity in the exporter.
enum ScoreDensity: String, CaseIterable, Identifiable {
    case airy
    case compact = "compact"
    case lilypondDefault = "default"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .airy: return "Airy"
        case .compact: return "Compact"
        case .lilypondDefault: return "LilyPond default"
        }
    }
}

enum ScoreFormat {
    /// Guitar Pro and MIDI extensions the pipeline can read.
    static let readableExtensions: Set<String> = ["gp3", "gp4", "gp5", "gpx", "gp", "mid", "midi", "gtp"]

    static func canRead(_ url: URL) -> Bool {
        readableExtensions.contains(url.pathExtension.lowercased())
    }
}
