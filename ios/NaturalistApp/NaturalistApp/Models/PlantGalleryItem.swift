import Foundation

struct PlantGalleryItem: Decodable, Identifiable {
    let id: String
    let name: String?
    let summary: String?
    let common: [String]
    let confidence: Double?
    let thumbnailBase64: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case common
        case confidence
        case thumbnailBase64 = "thumbnail_base64"
    }

    var thumbnailData: Data? {
        guard let thumbnailBase64 else { return nil }
        return Data(base64Encoded: thumbnailBase64)
    }

    var commonName: String {
        common.first ?? name ?? "Planta sem nome"
    }
}
