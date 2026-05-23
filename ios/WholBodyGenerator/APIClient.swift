import UIKit

enum APIError: LocalizedError {
    case invalidURL
    case imageEncodingFailed
    case serverError(Int, String)
    case invalidResponseData

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Endpoint URL is not configured. Update endpointURL in APIClient.swift."
        case .imageEncodingFailed:  return "Failed to encode the selected photo."
        case .invalidResponseData:  return "Server returned unreadable image data."
        case .serverError(let code, let msg):
            return "Server error \(code): \(msg)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let endpointURL = "https://adelowooluwatimileyin--whole-body-generator-generator-generate.modal.run"

    func generateFullBody(
        faceImage: UIImage,
        prompt: String? = nil,
        seed: Int? = nil,
        numSteps: Int = 30
    ) async throws -> UIImage {
        guard let url = URL(string: endpointURL) else { throw APIError.invalidURL }
        guard let imageData = faceImage.jpegData(compressionQuality: 0.9) else {
            throw APIError.imageEncodingFailed
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var body = Data()
        body.appendFilePart(name: "face_image", filename: "face.jpg", mimeType: "image/jpeg",
                            data: imageData, boundary: boundary)
        body.appendTextPart(name: "num_steps", value: "\(numSteps)", boundary: boundary)
        if let prompt, !prompt.isEmpty {
            body.appendTextPart(name: "prompt", value: prompt, boundary: boundary)
        }
        if let seed {
            body.appendTextPart(name: "seed", value: "\(seed)", boundary: boundary)
        }
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "No detail"
            throw APIError.serverError(statusCode, msg)
        }
        guard let image = UIImage(data: data) else { throw APIError.invalidResponseData }
        return image
    }
}

// MARK: - Multipart helpers

private extension Data {
    mutating func appendFilePart(name: String, filename: String, mimeType: String,
                                 data: Data, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        append("\r\n")
    }

    mutating func appendTextPart(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append(value)
        append("\r\n")
    }

    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}
