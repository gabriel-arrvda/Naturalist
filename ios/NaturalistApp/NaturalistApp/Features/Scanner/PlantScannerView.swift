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

    init(viewModel: PlantScannerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Theme.surface
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Naturalist")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(Theme.darkGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Fotografar planta") {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            showCameraUnavailableAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .frame(maxWidth: .infinity)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Text("Escolher da galeria")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 12))

                    Button("Analisar planta") {
                        Task {
                            await viewModel.analyze(imageData: imageData, filename: selectedFilename)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .frame(maxWidth: .infinity)

                    content
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Theme.primaryGreen.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding()
            }
        }
        .tint(Theme.primaryGreen)
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

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Text("Selecione ou fotografe uma planta para começar.")
        case .loading:
            ProgressView("Analisando sua planta...")
        case .success:
            VStack(alignment: .leading, spacing: 8) {
                Text("Melhor correspondência")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.darkGreen.opacity(0.75))
                Text(viewModel.bestMatchTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.darkGreen)
                Text(viewModel.summaryText)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        case .error:
            Text(viewModel.errorMessage)
                .foregroundStyle(.red)
        }
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
