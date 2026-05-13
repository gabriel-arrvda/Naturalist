import Foundation

protocol PlantService {
    func identifyPlant(imageData: Data, filename: String) async throws -> PlantResponse
    func fetchSavedPlants() async throws -> PlantsResponse
}
