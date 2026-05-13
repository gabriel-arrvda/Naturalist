import Foundation

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
    private var latestRequestToken: UUID?

    init(service: PlantService) {
        self.service = service
    }

    func analyze(imageData: Data?, filename: String) async {
        let requestToken = UUID()
        latestRequestToken = requestToken

        guard let imageData else {
            guard latestRequestToken == requestToken else { return }
            latestRequestToken = nil
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
            guard latestRequestToken == requestToken else { return }
            latestRequestToken = nil
            bestMatchTitle = response.bestMatch
            summaryText = SummaryFormatter.cleaned(response.summary)
            state = .success
        } catch {
            guard latestRequestToken == requestToken else { return }
            latestRequestToken = nil
            bestMatchTitle = ""
            summaryText = ""
            errorMessage = "Não foi possível identificar a planta. Tente novamente."
            state = .error
        }
    }
}
