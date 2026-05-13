import Foundation

@MainActor
final class PlantGalleryViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded
        case error
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var plants: [PlantGalleryItem] = []
    @Published private(set) var errorMessage: String = ""

    private let service: PlantService

    init(service: PlantService) {
        self.service = service
    }

    func loadPlants() async {
        state = .loading
        errorMessage = ""

        do {
            let response = try await service.fetchSavedPlants()
            plants = response.plants
            state = .loaded
        } catch {
            plants = []
            errorMessage = "Não foi possível carregar as plantas salvas."
            state = .error
        }
    }
}
