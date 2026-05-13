import Foundation

struct PlantsResponse: Decodable {
    let total: Int
    let plants: [PlantGalleryItem]
}
