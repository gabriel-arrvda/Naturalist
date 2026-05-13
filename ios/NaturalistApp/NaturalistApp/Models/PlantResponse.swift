import Foundation

struct PlantResponse: Decodable {
    let bestMatch: String
    let summary: String?

    private enum CodingKeys: String, CodingKey {
        case bestMatch = "melhor_correspondencia"
        case summary = "resumo_planta"
    }
}
