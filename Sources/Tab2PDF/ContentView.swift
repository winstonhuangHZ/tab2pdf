import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = ExportModel()

    @State private var input: URL?
    @State private var style: ScoreStyle = .modernCM
    @State private var density: ScoreDensity = .airy
    @State private var track = 0
    @State private var isDropTarget = false

    @AppStorage("lilypondPath") private var lilypondPath = Converter.resolveLilyPond() ?? ""

    private var javaPath: String? { Converter.resolveJava() }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            dropArea
            options
            logArea
            footer
        }
        .padding(16)
        .frame(minWidth: 620, minHeight: 520)
    }

    // MARK: - File

    private var dropArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: input == nil ? "square.and.arrow.down" : "music.note.list")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(input?.lastPathComponent ?? "Drop a Guitar Pro or MIDI file here")
                        .font(.headline)
                    Text(input.map { $0.deletingLastPathComponent().path } ?? "gp3 · gp4 · gp5 · gpx · mid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button("Choose…") { chooseInput() }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDropTarget ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isDropTarget ? Color.accentColor : Color.secondary.opacity(0.25),
                                  style: StrokeStyle(lineWidth: 1, dash: input == nil ? [5] : []))
            )
            .onDrop(of: [.fileURL], isTargeted: $isDropTarget, perform: handleDrop)
        }
    }

    // MARK: - Options

    private var options: some View {
        GroupBox("Engraving") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Style").gridColumnAlignment(.trailing).foregroundStyle(.secondary)
                    Picker("", selection: $style) {
                        ForEach(ScoreStyle.allCases) { Text($0.label).tag($0) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 260)
                }
                GridRow {
                    Text("Spacing").gridColumnAlignment(.trailing).foregroundStyle(.secondary)
                    Picker("", selection: $density) {
                        ForEach(ScoreDensity.allCases) { Text($0.label).tag($0) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 260)
                }
                GridRow {
                    Text("Track").gridColumnAlignment(.trailing).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        TextField("0", value: $track, format: .number)
                            .frame(width: 56)
                        Text(track == 0 ? "all tracks" : "only track \(track)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                GridRow {
                    Text("LilyPond").gridColumnAlignment(.trailing).foregroundStyle(.secondary)
                    TextField("/path/to/lilypond", text: $lilypondPath)
                        .font(.system(.caption, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(6)
        }
    }

    // MARK: - Log

    private var logArea: some View {
        GroupBox("Log") {
            ScrollView {
                Text(model.log.isEmpty ? "Nothing exported yet." : model.log)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 120)
            .padding(6)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            if let problem = blockingProblem {
                Label(problem, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Spacer()
            if let output = model.lastOutput {
                Button("Reveal") { NSWorkspace.shared.activateFileViewerSelecting([output]) }
            }
            if model.isRunning {
                ProgressView().controlSize(.small)
            }
            Button("Export PDF…", action: export)
                .keyboardShortcut(.defaultAction)
                .disabled(input == nil || model.isRunning)
        }
    }

    private var blockingProblem: String? {
        if Converter.pipelineURL == nil { return "Pipeline jar missing" }
        if javaPath == nil { return "Java not found" }
        if !FileManager.default.isExecutableFile(atPath: lilypondPath) { return "LilyPond not found" }
        return nil
    }

    // MARK: - Actions

    private func chooseInput() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Guitar Pro or MIDI file"
        if panel.runModal() == .OK { input = panel.url }
    }

    private func export() {
        guard let input, let java = javaPath else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = input.deletingPathExtension().lastPathComponent + ".pdf"
        panel.message = "Where should the PDF go?"
        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let request = ConversionRequest(
            input: input,
            output: destination,
            style: style,
            density: density,
            track: track
        )
        model.start(request, java: java, lilypond: lilypondPath)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url, ScoreFormat.canRead(url) else { return }
            DispatchQueue.main.async { input = url }
        }
        return true
    }
}
