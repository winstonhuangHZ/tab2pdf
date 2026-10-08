import Foundation

@MainActor
final class ExportModel: ObservableObject {
    @Published var log = ""
    @Published var isRunning = false
    @Published var lastOutput: URL?
    @Published var errorMessage: String?

    func start(_ request: ConversionRequest, java: String, lilypond: String) {
        isRunning = true
        errorMessage = nil
        lastOutput = nil
        log = ""

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try Converter.convert(request, java: java, lilypond: lilypond) { line in
                    DispatchQueue.main.async { self?.append(line) }
                }
                DispatchQueue.main.async {
                    self?.lastOutput = request.output
                    self?.isRunning = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.append(error.localizedDescription)
                    self?.isRunning = false
                }
            }
        }
    }

    private func append(_ line: String) {
        log += line + "\n"
    }
}
