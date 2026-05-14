import SwiftUI
import PhotosUI
import UIKit

struct PlantScannerView: View {
    @StateObject private var viewModel: PlantScannerViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var selectedFilename: String = "planta.jpg"
    @State private var showCamera: Bool = false
    @State private var showCameraUnavailableAlert: Bool = false
    @State private var analysisPresentation: AnalysisPresentation?

    init(viewModel: PlantScannerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                    actionsCard
                    previewCard
                    analyzeButton
                    resultCard
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Theme.premiumSurface, Theme.surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Naturalist")
        }
        .tint(Theme.primaryGreen)
            .overlay(
                Group {
                    if viewModel.state == .loading {
                        ZStack {
                            Color.black.opacity(0.28).ignoresSafeArea()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.primaryGreen))
                                    .scaleEffect(1.2)
                                Text("Analisando imagem...")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding(18)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .transition(.opacity)
                    }
                }
            )
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { capturedImage in
                imageData = normalizedJPEGData(from: capturedImage)
                if imageData != nil {
                    selectedFilename = "camera.jpg"
                }
            }
            .ignoresSafeArea()
        }
        .alert("Câmera indisponível", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use a galeria para selecionar uma imagem.")
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                let loadedData = try? await newItem.loadTransferable(type: Data.self)
                await MainActor.run {
                    imageData = normalizedJPEGData(from: loadedData)
                    if imageData != nil {
                        selectedFilename = "galeria.jpg"
                    }
                }
            }
        }
        .fullScreenCover(item: $analysisPresentation) { presentation in
            AnalysisResultView(presentation: presentation)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scanner editorial")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(Theme.primaryGreen)
            Text("Identifique plantas com uma experiência mais elegante.")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.darkGreen)
            Text("Fotografe ou escolha da galeria e veja um resumo limpo, bonito e pronto para salvar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Theme.cardBackground, Theme.premiumSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Theme.premiumShadow, radius: 18, x: 0, y: 10)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var actionsCard: some View {
        HStack(spacing: 12) {
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    showCameraUnavailableAlert = true
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.headline)
                    Text("Fotografar")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.headline)
                    Text("Galeria")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Theme.premiumShadow, radius: 14, x: 0, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prévia")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.primaryGreen)

            Group {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    if uiImage.size.width > uiImage.size.height * 1.3 {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                    } else {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Theme.primaryGreen)
                            .padding(16)
                            .background(Theme.surface)
                            .clipShape(Circle())
                        Text("Escolha uma planta para analisar")
                            .font(.headline)
                            .foregroundStyle(Theme.darkGreen)
                        Text("A imagem aparece aqui antes do envio.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Theme.cardBackground, Theme.premiumSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Theme.premiumShadow, radius: 18, x: 0, y: 10)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.analyze(imageData: imageData, filename: selectedFilename)
                await MainActor.run {
                    guard viewModel.state == .success, let imageData else { return }
                    analysisPresentation = AnalysisPresentation(
                        imageData: imageData,
                        title: viewModel.bestMatchTitle,
                        summary: viewModel.summaryText
                    )

                    // Post a notification so other views (Plants) can show a snackbar/banner
                    NotificationCenter.default.post(name: Notification.Name("PlantSavedNotification"), object: nil, userInfo: [
                        "imageData": imageData,
                        "title": viewModel.bestMatchTitle ?? "",
                        "summary": viewModel.summaryText ?? ""
                    ])
                }
            }
        } label: {
            Label("Analisar planta", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(imageData == nil)
        .opacity(imageData == nil ? 0.6 : 1)
        .shadow(color: Theme.premiumShadow, radius: 12, x: 0, y: 8)
    }

    @ViewBuilder
    private var resultCard: some View {
        switch viewModel.state {
        case .idle:
            PlantSummaryCard(
                title: "Pronto para analisar",
                summary: "Tire uma foto ou escolha da galeria para identificar a planta."
            )
        case .loading:
            PlantSummaryCard(
                title: "Analisando",
                summary: "Estamos consultando a API para encontrar a melhor correspondência."
            )
        case .success:
            PlantSummaryCard(title: viewModel.bestMatchTitle, summary: viewModel.summaryText)
        case .error:
            PlantSummaryCard(title: "Erro na análise", summary: viewModel.errorMessage)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                )
        }
    }

    private func normalizedJPEGData(from image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.9)
    }

    private func normalizedJPEGData(from data: Data?) -> Data? {
        guard let data, let image = UIImage(data: data) else {
            return nil
        }
        return normalizedJPEGData(from: image)
    }
}

private struct AnalysisPresentation: Identifiable {
    let id = UUID()
    let imageData: Data
    let title: String
    let summary: String
}

private struct AnalysisResultView: View {
    let presentation: AnalysisPresentation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroImage
                    summaryCard
                }
                .padding()
            }
                    .background(
                        LinearGradient(
                            colors: [Theme.premiumSurface, Theme.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fechar") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Resultado")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            if let uiImage = UIImage(data: presentation.imageData) {
                if uiImage.size.width > uiImage.size.height * 1.3 {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .clipped()
                } else {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .clipped()
                }
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.surface)
                    .frame(height: 360)
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(Theme.primaryGreen))
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.58)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Identificação concluída")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(presentation.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.premiumShadow, radius: 18, x: 0, y: 10)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.primaryGreen)
            Text(presentation.summary)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                dismiss()
            } label: {
                Label("Fechar", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(20)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Theme.premiumShadow, radius: 14, x: 0, y: 8)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview("PlantScanner - Mock") {
    // Use um view model de mock para o preview
    PlantScannerView(
        viewModel: PlantScannerViewModel(
            service: PlantAPIClient(
                baseURL: URL(string: "http://127.0.0.1:8000")!
            )
        )
    )
}
