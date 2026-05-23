import SwiftUI
import PhotosUI
import Observation

@Observable
final class GeneratorViewModel {
    var faceImage: UIImage?
    var resultImage: UIImage?
    var isGenerating = false
    var errorMessage: String?
    var customPrompt = ""

    var canGenerate: Bool { faceImage != nil && !isGenerating }
    var showError: Bool { errorMessage != nil }

    func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            faceImage = image
            resultImage = nil
        }
    }

    func generate() async {
        guard let faceImage else { return }
        await MainActor.run { isGenerating = true; errorMessage = nil }
        defer { Task { await MainActor.run { self.isGenerating = false } } }

        do {
            let prompt = customPrompt.isEmpty ? nil : customPrompt
            let result = try await APIClient.shared.generateFullBody(
                faceImage: faceImage,
                prompt: prompt
            )
            await MainActor.run { resultImage = result }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
