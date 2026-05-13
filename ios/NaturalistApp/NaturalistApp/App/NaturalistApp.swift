import SwiftUI

@main
struct NaturalistApp: App {
    private let plantService = PlantAPIClient(
        baseURL: URL(string: "http://127.0.0.1:8000")!
    )
    private let scannerViewModel: PlantScannerViewModel
    private let galleryViewModel: PlantGalleryViewModel

    init() {
        scannerViewModel = PlantScannerViewModel(service: plantService)
        galleryViewModel = PlantGalleryViewModel(service: plantService)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                PlantScannerView(viewModel: scannerViewModel)
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }

                PlantGalleryView(viewModel: galleryViewModel)
                .tabItem {
                    Label("Plantas", systemImage: "leaf")
                }
            }
            .tint(Theme.primaryGreen)
        }
    }
}
