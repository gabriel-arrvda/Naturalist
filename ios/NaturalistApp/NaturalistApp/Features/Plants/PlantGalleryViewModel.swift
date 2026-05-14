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
    private var latestLoadToken: UUID?

    init(service: PlantService) {
        self.service = service
    }

    func loadPlants() async {
        let loadToken = UUID()
        latestLoadToken = loadToken
        state = .loading
        errorMessage = ""

        do {
            let response = try await service.fetchSavedPlants()
            guard latestLoadToken == loadToken else { return }
            latestLoadToken = nil
            plants = response.plants
            state = .loaded
        } catch is CancellationError {
            guard latestLoadToken == loadToken else { return }
            latestLoadToken = nil
            state = plants.isEmpty ? .idle : .loaded
        } catch {
            guard latestLoadToken == loadToken else { return }
            latestLoadToken = nil
            errorMessage = "Não foi possível carregar as plantas salvas."
            state = .error
        }
    }
}
