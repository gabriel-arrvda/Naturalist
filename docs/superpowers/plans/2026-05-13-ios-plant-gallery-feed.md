# iOS Plant Gallery Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernizar a UI do scanner do Naturalist e adicionar uma tela de plantas salvas que carrega `GET /plants` com foto, nome comum e resumo em um visual de app atual.

**Architecture:** O backend vai expor uma thumbnail utilizável da última imagem enviada por planta, porque a UI precisa renderizar a foto no feed. No iOS, um `TabView` vai separar Scanner e Plantas, com cada tela tendo seu próprio view model e o client de API isolando rede e decodificação.

**Tech Stack:** FastAPI, Firestore, Pillow, SwiftUI, URLSession, PhotosUI, iOS 18+

---

### Task 1: Persistir thumbnail da última foto no backend

**Files:**
- Modify: `src/app.py`

- [ ] **Step 1: Add thumbnail helpers and base64 encoding**

```python
from base64 import b64encode
from PIL import Image

def make_thumbnail_base64(image_bytes: bytes, max_size: tuple[int, int] = (512, 512)) -> str:
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    image.thumbnail(max_size)

    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=82, optimize=True)
    return b64encode(buffer.getvalue()).decode("utf-8")
```

- [ ] **Step 2: Store the thumbnail alongside each plant document in `/predict`**

```python
thumbnail_base64 = make_thumbnail_base64(image_bytes)
image_metadata = {
    "filename": file.filename,
    "content_type": file.content_type,
    "size_bytes": len(image_bytes),
    "uploaded_at": datetime.now(timezone.utc).isoformat(),
    "thumbnail_base64": thumbnail_base64,
}

if not doc.exists:
    plant_ref.set({
        "name": best_match,
        "created_at": firestore.SERVER_TIMESTAMP,
        "summary": summary,
        "common": results[0].get("species", {}).get("commonNames", []) if results else [],
        "confidence": results[0].get("score") if results else None,
        "sent_images": [image_metadata],
        "thumbnail_base64": thumbnail_base64,
    })
else:
    plant_ref.update({
        "sent_images": firestore.ArrayUnion([image_metadata]),
        "thumbnail_base64": thumbnail_base64,
        "updated_at": firestore.SERVER_TIMESTAMP,
    })
```

- [ ] **Step 3: Return the thumbnail in `GET /plants`**

```python
@app.get("/plants")
def list_saved_plants():
    docs = db.collection("plants").stream()

    plants: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        sent_images = data.get("sent_images", [])
        latest_image = sent_images[-1] if sent_images else {}

        plants.append({
            "id": doc.id,
            "name": data.get("name"),
            "summary": data.get("summary"),
            "common": data.get("common", []),
            "confidence": data.get("confidence"),
            "created_at": str(data.get("created_at")) if data.get("created_at") else None,
            "updated_at": str(data.get("updated_at")) if data.get("updated_at") else None,
            "sent_images": sent_images,
            "thumbnail_base64": latest_image.get("thumbnail_base64") or data.get("thumbnail_base64"),
        })

    return {"total": len(plants), "plants": plants}
```

- [ ] **Step 4: Smoke test the API response shape**

Run:
```bash
python3 -m py_compile src/app.py && curl -s http://127.0.0.1:8000/plants | python3 -m json.tool
```
Expected: `src/app.py` compiles and `/plants` returns `total` plus a `plants` array with `thumbnail_base64`.

- [ ] **Step 5: Commit**

```bash
git add src/app.py
git commit -m "feat(api): expose plant thumbnails in saved plants feed"
```

### Task 2: Add iOS models and API fetch for saved plants

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/Models/PlantGalleryItem.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Models/PlantsResponse.swift`
- Modify: `ios/NaturalistApp/NaturalistApp/Services/PlantService.swift`
- Modify: `ios/NaturalistApp/NaturalistApp/Services/PlantAPIClient.swift`

- [ ] **Step 1: Define gallery models**

```swift
import Foundation

struct PlantsResponse: Decodable {
    let total: Int
    let plants: [PlantGalleryItem]
}

struct PlantGalleryItem: Decodable, Identifiable {
    let id: String
    let name: String?
    let summary: String?
    let common: [String]
    let confidence: Double?
    let thumbnailBase64: String?

    var thumbnailData: Data? {
        guard let thumbnailBase64 else { return nil }
        return Data(base64Encoded: thumbnailBase64)
    }

    var commonName: String {
        common.first ?? name ?? "Planta sem nome"
    }
}
```

- [ ] **Step 2: Extend the service protocol**

```swift
protocol PlantService {
    func identifyPlant(imageData: Data, filename: String) async throws -> PlantResponse
    func fetchSavedPlants() async throws -> PlantsResponse
}
```

- [ ] **Step 3: Add `GET /plants` decoding to `PlantAPIClient`**

```swift
func fetchSavedPlants() async throws -> PlantsResponse {
    let endpoint = baseURL.appending(path: "plants")
    let (data, response) = try await session.data(from: endpoint)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw PlantAPIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        let message = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
        throw PlantAPIError.serverError(httpResponse.statusCode, message)
    }

    return try JSONDecoder().decode(PlantsResponse.self, from: data)
}
```

- [ ] **Step 4: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/Models/PlantGalleryItem.swift ios/NaturalistApp/NaturalistApp/Models/PlantsResponse.swift ios/NaturalistApp/NaturalistApp/Services/PlantService.swift ios/NaturalistApp/NaturalistApp/Services/PlantAPIClient.swift
git commit -m "feat(ios): add saved plants API models"
```

### Task 3: Build the new Plants screen

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryViewModel.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryView.swift`

- [ ] **Step 1: Write the gallery view model**

```swift
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
```

- [ ] **Step 2: Write the feed UI**

```swift
import SwiftUI
import UIKit

struct PlantGalleryView: View {
    @StateObject private var viewModel: PlantGalleryViewModel

    init(viewModel: PlantGalleryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    header
                    stateContent
                }
                .padding()
            }
            .refreshable {
                await viewModel.loadPlants()
            }
            .navigationTitle("Plantas")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.loadPlants()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plantas salvas")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.darkGreen)
            Text("Últimas buscas com foto e resumo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Carregando plantas salvas...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        case .loaded:
            if viewModel.plants.isEmpty {
                EmptyStateView()
            } else {
                ForEach(viewModel.plants) { plant in
                    PlantCardView(plant: plant)
                }
            }
        case .error:
            Text(viewModel.errorMessage)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

- [ ] **Step 3: Render thumbnail, common name and summary in the card**

```swift
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.primaryGreen)
            Text("Nenhuma planta salva ainda.")
                .font(.headline)
            Text("As plantas buscadas aparecem aqui com a última foto enviada.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct PlantCardView: View {
    let plant: PlantGalleryItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 8) {
                Text(plant.commonName)
                    .font(.headline)
                if let name = plant.name {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(SummaryFormatter.cleaned(plant.summary))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = plant.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .frame(width: 84, height: 84)
                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryViewModel.swift ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryView.swift
git commit -m "feat(ios): add saved plants gallery screen"
```

### Task 4: Modernize the scanner and app shell

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift`
- Modify: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift`
- Modify: `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift`

- [ ] **Step 1: Add richer theme tokens**

```swift
import SwiftUI

enum Theme {
    static let primaryGreen = Color(red: 0.18, green: 0.62, blue: 0.34)
    static let darkGreen = Color(red: 0.08, green: 0.28, blue: 0.16)
    static let surface = Color(red: 0.96, green: 0.98, blue: 0.96)
    static let cardBackground = Color.white
    static let cardBorder = Color(red: 0.86, green: 0.92, blue: 0.86)
}
```

- [ ] **Step 2: Wrap scanner and gallery in a TabView**

```swift
import SwiftUI

@main
struct NaturalistApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                PlantScannerView(
                    viewModel: PlantScannerViewModel(
                        service: PlantAPIClient(baseURL: URL(string: "http://127.0.0.1:8000")!)
                    )
                )
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }

                PlantGalleryView(
                    viewModel: PlantGalleryViewModel(
                        service: PlantAPIClient(baseURL: URL(string: "http://127.0.0.1:8000")!)
                    )
                )
                .tabItem {
                    Label("Plantas", systemImage: "leaf")
                }
            }
            .tint(Theme.primaryGreen)
        }
    }
}
```

- [ ] **Step 3: Restyle the scanner as a premium landing screen**

```swift
import SwiftUI
import PhotosUI
import UIKit

var body: some View {
    NavigationStack {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                actionsCard
                previewCard
                resultCard
            }
            .padding()
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Naturalist")
    }
}

private var heroCard: some View {
    VStack(alignment: .leading, spacing: 10) {
        Text("Naturalist")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.primaryGreen)
        Text("Identifique e salve suas plantas com um visual mais elegante.")
            .font(.title.bold())
            .foregroundStyle(Theme.darkGreen)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
}

private var actionsCard: some View {
    HStack(spacing: 12) {
        Button("Fotografar planta") { }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

        PhotosPicker(selection: $pickerItem, matching: .images) {
            Text("Escolher da galeria")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

private var previewCard: some View {
    Group {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .frame(height: 240)
                .overlay(Text("Pré-visualização da planta").foregroundStyle(.secondary))
        }
    }
}

@ViewBuilder
private var resultCard: some View {
    switch viewModel.state {
    case .idle:
        Text("Tire uma foto ou escolha da galeria para identificar a planta.")
    case .loading:
        ProgressView("Analisando sua planta...")
    case .success:
        PlantSummaryCard(title: viewModel.bestMatchTitle, summary: viewModel.summaryText)
    case .error:
        Text(viewModel.errorMessage)
            .foregroundStyle(.red)
    }
}

private struct PlantSummaryCard: View {
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Melhor correspondência")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.primaryGreen)
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Theme.darkGreen)
            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
```

- [ ] **Step 4: Keep the scanner states visually polished**

```swift
switch viewModel.state {
case .idle:
    Text("Tire uma foto ou escolha da galeria para identificar a planta.")
case .loading:
    ProgressView("Analisando sua planta...")
case .success:
    PlantSummaryCard(title: viewModel.bestMatchTitle, summary: viewModel.summaryText)
case .error:
    Text(viewModel.errorMessage)
        .foregroundStyle(.red)
}
```

- [ ] **Step 5: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift
git commit -m "feat(ios): modernize scanner and add tab navigation"
```

### Task 5: Update docs and verify the app build

**Files:**
- Modify: `README.MD`

- [ ] **Step 1: Document the new Plants tab and API behavior**

```markdown
## App iOS (SwiftUI)

O app agora tem duas abas:
- **Scanner**: captura ou escolhe uma imagem e identifica a planta
- **Plantas**: lista as plantas já buscadas com foto, nome comum e resumo

O endpoint `GET /plants` precisa devolver a última imagem salva de cada planta para que a tela consiga renderizar a thumbnail.
```

- [ ] **Step 2: Run the iOS build**

Run:
```bash
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit the docs**

```bash
git add README.MD
git commit -m "docs: describe plant gallery tab"
```

## Self-review

1. **Spec coverage:** The plan covers the modern scanner redesign, the new plants screen, the `/plants` contract, thumbnail storage, and documentation.
2. **Placeholder scan:** No TBD/TODO/placeholder steps remain; every task has exact files and commands.
3. **Type consistency:** `PlantsResponse`, `PlantGalleryItem`, `PlantGalleryViewModel`, and `fetchSavedPlants()` are named consistently across the backend and iOS tasks.
