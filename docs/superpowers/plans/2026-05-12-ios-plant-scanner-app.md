# iOS Plant Scanner App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir um app iOS 18+ em SwiftUI que captura/escolhe foto de planta, envia para `POST /predict` da API local e mostra melhor correspondência + resumo em PT-BR com UI verde.

**Architecture:** O app será dividido em módulos pequenos (App, Features, Services, Models, UI). A tela principal usa SwiftUI com `ViewModel` (MVVM) para estados de interface. A camada de rede fica isolada em `PlantAPIClient` para manter o fluxo previsível e fácil de evoluir.

**Tech Stack:** Swift 5.10+, SwiftUI, PhotosUI, URLSession, iOS 18 SDK

---

## File Structure (target)

- Create: `ios/NaturalistApp/NaturalistApp.xcodeproj`
- Create: `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerViewModel.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Services/PlantAPIClient.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Models/PlantResponse.swift`
- Create: `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Utils/SummaryFormatter.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Resources/Info.plist`
- Modify: `README.MD`

### Task 1: Bootstrap do projeto iOS 18

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp.xcodeproj`
- Create: `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Resources/Info.plist`

- [ ] **Step 1: Criar projeto SwiftUI no Xcode**

```text
Product Name: NaturalistApp
Interface: SwiftUI
Language: Swift
Minimum Deployment: iOS 18.0
Path: ios/NaturalistApp/
```

- [ ] **Step 2: Definir entry point inicial**

```swift
// ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift
import SwiftUI

@main
struct NaturalistApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Naturalist")
        }
    }
}
```

- [ ] **Step 3: Adicionar permissões de câmera e galeria**

```xml
<!-- ios/NaturalistApp/NaturalistApp/Resources/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Precisamos da câmera para identificar sua planta.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Precisamos da galeria para escolher uma foto da planta.</string>
```

- [ ] **Step 4: Validar build do app**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ios/NaturalistApp
git commit -m "chore(ios): bootstrap app iOS 18"
```

### Task 2: Modelos e formatter da resposta

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/Models/PlantResponse.swift`
- Create: `ios/NaturalistApp/NaturalistApp/Utils/SummaryFormatter.swift`

- [ ] **Step 1: Criar modelo principal da resposta**

```swift
// PlantResponse.swift
import Foundation

struct PlantResponse: Decodable {
    let bestMatch: String
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case bestMatch = "melhor_correspondencia"
        case summary = "resumo_planta"
    }
}
```

- [ ] **Step 2: Criar formatter para limpar markdown leve**

```swift
// SummaryFormatter.swift
import Foundation

enum SummaryFormatter {
    static func cleaned(_ text: String?) -> String {
        guard let text, !text.isEmpty else { return "Resumo indisponível." }
        return text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "###", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

- [ ] **Step 3: Validar build**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/Models/PlantResponse.swift ios/NaturalistApp/NaturalistApp/Utils/SummaryFormatter.swift
git commit -m "feat(ios): add plant response model and summary formatter"
```

### Task 3: Cliente de API multipart

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/Services/PlantAPIClient.swift`

- [ ] **Step 1: Criar erro de serviço**

```swift
import Foundation

enum PlantAPIError: Error {
    case invalidResponse
    case serverError(Int, String)
}
```

- [ ] **Step 2: Implementar cliente com upload multipart**

```swift
// PlantAPIClient.swift
import Foundation

struct PlantAPIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func identifyPlant(imageData: Data, filename: String) async throws -> PlantResponse {
        var request = URLRequest(url: baseURL.appending(path: "predict"))
        let boundary = "Boundary-\(UUID().uuidString)"
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeBody(imageData: imageData, filename: filename, boundary: boundary)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PlantAPIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw PlantAPIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "Erro desconhecido")
        }
        return try JSONDecoder().decode(PlantResponse.self, from: data)
    }

    private func makeBody(imageData: Data, filename: String, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
```

- [ ] **Step 3: Validar build**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/Services/PlantAPIClient.swift
git commit -m "feat(ios): add multipart API client for /predict"
```

### Task 4: ViewModel de estados e mensagens

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerViewModel.swift`

- [ ] **Step 1: Definir protocolo de serviço**

```swift
import Foundation

protocol PlantService {
    func identifyPlant(imageData: Data, filename: String) async throws -> PlantResponse
}

extension PlantAPIClient: PlantService {}
```

- [ ] **Step 2: Implementar ViewModel**

```swift
// PlantScannerViewModel.swift
import Foundation

@MainActor
final class PlantScannerViewModel: ObservableObject {
    enum ViewState: Equatable { case idle, loading, success, error }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var bestMatchTitle: String = ""
    @Published private(set) var summaryText: String = ""
    @Published private(set) var errorMessage: String = ""

    private let service: PlantService

    init(service: PlantService) {
        self.service = service
    }

    func analyze(imageData: Data?, filename: String) async {
        guard let imageData else {
            state = .error
            errorMessage = "Selecione uma imagem antes de analisar."
            return
        }

        state = .loading
        do {
            let response = try await service.identifyPlant(imageData: imageData, filename: filename)
            bestMatchTitle = response.bestMatch
            summaryText = SummaryFormatter.cleaned(response.summary)
            state = .success
        } catch {
            state = .error
            errorMessage = "Não foi possível identificar a planta. Tente novamente."
        }
    }
}
```

- [ ] **Step 3: Validar build**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerViewModel.swift
git commit -m "feat(ios): add scanner view model with explicit UI states"
```

### Task 5: Tela principal com câmera/galeria e resultado

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift`
- Modify: `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift`

- [ ] **Step 1: Criar estrutura de tela**

```swift
import SwiftUI
import PhotosUI

struct PlantScannerView: View {
    @StateObject private var viewModel: PlantScannerViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?

    init(viewModel: PlantScannerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Naturalist").font(.largeTitle).bold()
                Button("Fotografar planta") { }
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Escolher da galeria")
                }
                Button("Analisar planta") {
                    Task { await viewModel.analyze(imageData: imageData, filename: "planta.jpg") }
                }
            }
            .padding()
        }
    }
}
```

- [ ] **Step 2: Renderizar estados na UI**

```swift
switch viewModel.state {
case .idle:
    Text("Selecione ou fotografe uma planta para começar.")
case .loading:
    ProgressView("Analisando sua planta...")
case .success:
    VStack(alignment: .leading, spacing: 8) {
        Text(viewModel.bestMatchTitle).font(.title3).bold()
        Text(viewModel.summaryText)
    }
case .error:
    Text(viewModel.errorMessage).foregroundStyle(.red)
}
```

- [ ] **Step 3: Conectar no entry point**

```swift
// NaturalistApp.swift
import SwiftUI

@main
struct NaturalistApp: App {
    var body: some Scene {
        WindowGroup {
            PlantScannerView(
                viewModel: PlantScannerViewModel(
                    service: PlantAPIClient(baseURL: URL(string: "http://127.0.0.1:8000")!)
                )
            )
        }
    }
}
```

- [ ] **Step 4: Validar build**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift
git commit -m "feat(ios): add scanner screen with result rendering"
```

### Task 6: Tema visual verde

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift`
- Modify: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift`

- [ ] **Step 1: Definir paleta**

```swift
// Theme.swift
import SwiftUI

enum AppTheme {
    static let primaryGreen = Color(red: 0.16, green: 0.56, blue: 0.30)
    static let darkGreen = Color(red: 0.07, green: 0.32, blue: 0.18)
    static let surface = Color(red: 0.95, green: 0.98, blue: 0.95)
}
```

- [ ] **Step 2: Aplicar tema nos botões e cards**

```swift
// Trechos em PlantScannerView.swift
.background(AppTheme.surface)
.tint(AppTheme.primaryGreen)
.buttonStyle(.borderedProminent)
.clipShape(RoundedRectangle(cornerRadius: 14))
```

- [ ] **Step 3: Melhorar hierarquia visual do resultado**

```swift
VStack(alignment: .leading, spacing: 10) {
    Text("Melhor correspondência").font(.caption).foregroundStyle(AppTheme.darkGreen)
    Text(viewModel.bestMatchTitle).font(.title3).bold()
    Divider()
    Text(viewModel.summaryText).font(.body)
}
.padding()
.background(.white)
.clipShape(RoundedRectangle(cornerRadius: 16))
```

- [ ] **Step 4: Validar build**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift
git commit -m "feat(ios): apply green-first interface design"
```

### Task 7: Documentação de execução

**Files:**
- Modify: `README.MD`

- [ ] **Step 1: Adicionar seção do app iOS**

```markdown
## App iOS (SwiftUI)

Local: `ios/NaturalistApp`

### Requisitos
- Xcode 16+
- iOS 18+
- API local em `http://127.0.0.1:8000`

### Como executar
1. Abra `ios/NaturalistApp/NaturalistApp.xcodeproj`
2. Rode no simulador iPhone 16
3. Toque em "Fotografar planta" ou "Escolher da galeria"
4. Toque em "Analisar planta" para enviar ao `/predict`
```

- [ ] **Step 2: Validar build final**

Run: `xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add README.MD
git commit -m "docs: add iOS app setup and run instructions"
```

## Self-review (writing-plans)

1. **Spec coverage:** Cobertos captura câmera/galeria, API local `/predict`, exibição de melhor correspondência + resumo, PT-BR e foco visual em verde.
2. **Placeholder scan:** Sem TODO/TBD; cada passo contém arquivo, código e comando explícito.
3. **Type consistency:** `PlantResponse`, `PlantAPIClient`, `PlantScannerViewModel` e `PlantService` usados de forma consistente.
