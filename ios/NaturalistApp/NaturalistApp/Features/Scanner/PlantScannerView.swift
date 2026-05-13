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
        ScrollView {
            VStack(spacing: 16) {
                Text("Naturalist")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Fotografar planta") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showCameraUnavailableAlert = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Escolher da galeria")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button("Analisar planta") {
                    Task {
                        await viewModel.analyze(imageData: imageData, filename: selectedFilename)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { capturedImage in
                imageData = capturedImage.jpegData(compressionQuality: 0.9) ?? capturedImage.pngData()
                selectedFilename = "camera.jpg"
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
                imageData = try? await newItem.loadTransferable(type: Data.self)
                selectedFilename = "galeria.jpg"
            }
        }
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
                Text(viewModel.bestMatchTitle)
                    .font(.title3)
                    .bold()
                Text(viewModel.summaryText)
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
