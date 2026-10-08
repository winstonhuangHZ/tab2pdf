import Foundation

struct ConversionRequest {
    var input: URL
    var output: URL
    var style: ScoreStyle
    var density: ScoreDensity
    /// 1-based track number, 0 exports every track.
    var track: Int
    var lilypondVersion = "2.26.0"
}

enum ConversionError: LocalizedError {
    case missingPipeline
    case missingJava
    case missingLilyPond
    case unreadableInput
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingPipeline:
            return "The bundled gp2pdf.jar is missing, so this build is incomplete."
        case .missingJava:
            return "No Java runtime found. Install a JDK and reopen the app."
        case .missingLilyPond:
            return "LilyPond was not found. Point the app at it with the LilyPond field."
        case .unreadableInput:
            return "That file is not a Guitar Pro or MIDI file."
        case .failed(let message):
            return message
        }
    }
}

enum Converter {

    /// The TuxGuitar-derived reader plus LilyPond writer, packaged as one jar.
    static var pipelineURL: URL? {
        Bundle.module.url(forResource: "gp2pdf", withExtension: "jar")
    }

    static func resolveJava() -> String? {
        let fileManager = FileManager.default
        if let home = try? output("/usr/libexec/java_home", []) {
            let candidate = home.trimmingCharacters(in: .whitespacesAndNewlines) + "/bin/java"
            if fileManager.isExecutableFile(atPath: candidate) { return candidate }
        }
        for candidate in ["/usr/local/bin/java", "/opt/homebrew/bin/java", "/usr/bin/java"] {
            if fileManager.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    static func resolveLilyPond() -> String? {
        let fileManager = FileManager.default
        var candidates: [String] = []
        if let fromEnvironment = ProcessInfo.processInfo.environment["LILYPOND"] {
            candidates.append(fromEnvironment)
        }
        candidates.append(contentsOf: [
            NSHomeDirectory() + "/tools/lilypond-2.26.0/bin/lilypond",
            "/Applications/LilyPond.app/Contents/Resources/bin/lilypond",
            "/usr/local/bin/lilypond",
            "/opt/homebrew/bin/lilypond"
        ])
        return candidates.first { fileManager.isExecutableFile(atPath: $0) }
    }

    /// Reads the Guitar Pro file into LilyPond source, then engraves it to PDF.
    static func convert(
        _ request: ConversionRequest,
        java: String,
        lilypond: String,
        log: (String) -> Void
    ) throws {
        guard ScoreFormat.canRead(request.input) else { throw ConversionError.unreadableInput }
        guard let pipeline = pipelineURL else { throw ConversionError.missingPipeline }

        let fileManager = FileManager.default
        let work = fileManager.temporaryDirectory
            .appendingPathComponent("tab2pdf-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: work) }

        let source = work.appendingPathComponent("score.ly")

        log("Reading \(request.input.lastPathComponent)")
        let generate = try run(java, [
            "-jar", pipeline.path,
            request.input.path,
            source.path,
            request.lilypondVersion,
            request.style.rawValue,
            request.density.rawValue,
            String(request.track)
        ])
        append(generate.output, to: log)
        guard generate.status == 0 else {
            throw ConversionError.failed(
                "Could not read \(request.input.lastPathComponent).\n\n\(generate.output)")
        }

        log("Engraving with LilyPond")
        let engraved = work.appendingPathComponent("score")
        let engrave = try run(lilypond, ["-dno-point-and-click", "-o", engraved.path, source.path])
        append(engrave.output, to: log)

        let produced = work.appendingPathComponent("score.pdf")
        guard fileManager.fileExists(atPath: produced.path) else {
            throw ConversionError.failed("LilyPond did not produce a PDF.\n\n\(engrave.output)")
        }

        if fileManager.fileExists(atPath: request.output.path) {
            try fileManager.removeItem(at: request.output)
        }
        try fileManager.moveItem(at: produced, to: request.output)
        log("Wrote \(request.output.path)")
    }

    private static func append(_ text: String, to log: (String) -> Void) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { log(trimmed) }
    }

    @discardableResult
    static func run(_ launchPath: String, _ arguments: [String]) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = FileHandle.nullDevice

        try process.run()
        // Draining before waiting avoids filling the pipe buffer on chatty runs.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }

    private static func output(_ launchPath: String, _ arguments: [String]) throws -> String {
        try run(launchPath, arguments).output
    }
}
