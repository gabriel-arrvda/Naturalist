import Foundation

enum PlantAPIError: Error {
    case invalidResponse
    case serverError(Int, String)
}

struct PlantAPIClient: PlantService {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func identifyPlant(imageData: Data, filename: String) async throws -> PlantResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        let endpoint = baseURL.appending(path: "predict")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(imageData: imageData, filename: filename, boundary: boundary)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlantAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
            throw PlantAPIError.serverError(httpResponse.statusCode, message)
        }

        return try JSONDecoder().decode(PlantResponse.self, from: data)
    }

    private func makeMultipartBody(imageData: Data, filename: String, boundary: String) -> Data {
        let sanitizedFilename = sanitizeFilenameForHeader(filename)
        let mimeType = mimeType(for: filename)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(sanitizedFilename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func mimeType(for filename: String) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"
        case "webp":
            return "image/webp"
        default:
            return "application/octet-stream"
        }
    }

    private func sanitizeFilenameForHeader(_ filename: String) -> String {
        let dangerousCharacters = CharacterSet(charactersIn: "\"\r\n/\\;")
        let sanitizedScalars = filename.unicodeScalars.map { scalar in
            dangerousCharacters.contains(scalar) ? "_" : Character(scalar)
        }
        let sanitized = String(sanitizedScalars)
        return sanitized.isEmpty ? "upload.bin" : sanitized
    }
}
