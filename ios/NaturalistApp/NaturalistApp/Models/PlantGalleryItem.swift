import Foundation

struct PlantGalleryItem: Decodable, Identifiable {
    let id: String
    let name: String?
    let summary: String?
    let common: [String]
    let confidence: Double?

    // Legacy support for base64 payloads (fallback)
    let imageBase64: String?
    let thumbnailBase64: String?

    // Preferred modern fields returned by the backend
    let imageURLString: String?
    let thumbnailURLString: String?

    // Some backends store urls inside sent_images array; capture that too
    let sentImages: [SentImage]?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case common
        case confidence
        case imageBase64 = "image_base64"
        case thumbnailBase64 = "thumbnail_base64"
        case imageURLString = "image_url"
        case thumbnailURLString = "thumbnail_url"
        case sentImages = "sent_images"
    }

    struct SentImage: Decodable {
        let filename: String?
        let contentType: String?
        let sizeBytes: Int?
        let capturedAt: String?
        let imageURLString: String?
        let thumbnailURLString: String?

        private enum CodingKeys: String, CodingKey {
            case filename
            case contentType = "content_type"
            case sizeBytes = "size_bytes"
            case capturedAt = "captured_at"
            case imageURLString = "image_url"
            case thumbnailURLString = "thumbnail_url"
        }

        var thumbnailURL: URL? {
            if let s = thumbnailURLString { return URL(string: s) }
            return nil
        }

        var imageURL: URL? {
            if let s = imageURLString { return URL(string: s) }
            return nil
        }
    }

    var thumbnailData: Data? {
        if let thumbnailBase64, let data = Data(base64Encoded: thumbnailBase64) {
            return data
        }
        guard let imageBase64 else { return nil }
        return Data(base64Encoded: imageBase64)
    }

    var imageData: Data? {
        guard let imageBase64 else { return nil }
        return Data(base64Encoded: imageBase64)
    }

    var thumbnailURL: URL? {
        if let s = thumbnailURLString { return URL(string: s) }
        if let first = sentImages?.first, let u = first.thumbnailURL { return u }
        return nil
    }

    var imageURL: URL? {
        if let s = imageURLString { return URL(string: s) }
        if let first = sentImages?.first, let u = first.imageURL { return u }
        return nil
    }

    var commonName: String {
        common.first ?? name ?? "Planta sem nome"
    }
}
