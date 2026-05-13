import Foundation
import Combine

protocol PlantService {
    func identifyPlant(imageData: Data, filename: String) async throws -> PlantResponse
}

@MainActor
final class PlantScannerViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case success
        case error
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var bestMatchTitle: String = ""
    @Published private(set) var summaryText: String = ""
    @Published private(set) var errorMessage: String = ""

    private let service: PlantService

    init(service: PlantService) {
        self.service = service
    }

    func analyze(imageData: Data?, filename: String) async {
        guard let imageData else {
            bestMatchTitle = ""
            summaryText = ""
            errorMessage = "Selecione uma imagem antes de analisar."
            state = .error
            return
        }

        state = .loading
        errorMessage = ""

        do {
            let response = try await service.identifyPlant(imageData: imageData, filename: filename)
            bestMatchTitle = response.bestMatch
            summaryText = SummaryFormatter.cleaned(response.summary)
            state = .success
        } catch {
            bestMatchTitle = ""
            summaryText = ""
            errorMessage = "Não foi possível identificar a planta. Tente novamente."
            state = .error
        }
    }
}
