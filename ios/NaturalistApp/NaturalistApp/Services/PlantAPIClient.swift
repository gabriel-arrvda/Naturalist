import Foundation

enum PlantAPIError: Error {
    case invalidResponse
    case serverError(Int, String)
}

struct PlantAPIClient {
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
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
