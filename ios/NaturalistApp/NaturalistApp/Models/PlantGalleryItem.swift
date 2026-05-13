import Foundation

struct PlantGalleryItem: Decodable, Identifiable {
    let id: String
    let name: String?
    let summary: String?
    let common: [String]
    let confidence: Double?
    let imageBase64: String?
    let thumbnailBase64: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case common
        case confidence
        case imageBase64 = "image_base64"
        case thumbnailBase64 = "thumbnail_base64"
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

    var commonName: String {
        common.first ?? name ?? "Planta sem nome"
    }
}
