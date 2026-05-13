import SwiftUI

@main
struct NaturalistApp: App {
    var body: some Scene {
        WindowGroup {
            PlantScannerView(
                viewModel: PlantScannerViewModel(
                    service: PlantAPIClient(
                        baseURL: URL(string: "http://127.0.0.1:8000")!
                    )
                )
            )
        }
    }
}
