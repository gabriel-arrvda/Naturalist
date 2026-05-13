import SwiftUI
import UIKit

extension Notification.Name {
    static let plantSaved = Notification.Name("PlantSavedNotification")
}

struct PlantGalleryView: View {
    @StateObject private var viewModel: PlantGalleryViewModel
    @State private var showPlantSavedAlert: Bool = false
    @State private var plantSavedTitle: String = ""
    @State private var plantSavedSummary: String = ""
    @State private var plantSavedImageData: Data? = nil
    @State private var showSavedModal: Bool = false
    @State private var selectedPlant: PlantGalleryItem? = nil


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
            .background(Theme.surface.ignoresSafeArea())
            .refreshable {
                await viewModel.loadPlants()
            }
            .navigationTitle("Plantas")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.loadPlants()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .plantSaved)) { note in
                if let info = note.userInfo {
                    plantSavedTitle = info["title"] as? String ?? ""
                    plantSavedSummary = info["summary"] as? String ?? ""
                    plantSavedImageData = info["imageData"] as? Data
                    // Show snackbar
                    showPlantSavedAlert = true
                    // Reload plants list to reflect new item
                    Task {
                        await viewModel.loadPlants()
                    }
                }
            }
            .fullScreenCover(isPresented: $showSavedModal) {
                if let data = plantSavedImageData {
                    SavedAnalysisModalView(imageData: data, title: plantSavedTitle, summary: plantSavedSummary)
                } else {
                    EmptyView()
                }
            }
            .overlay(alignment: .bottom) {
                if showPlantSavedAlert {
                    HStack(spacing: 12) {
                        if let data = plantSavedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plantSavedTitle).font(.subheadline).bold().foregroundStyle(Theme.darkGreen).lineLimit(1)
                            Text(plantSavedSummary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        Spacer()
                        Button {
                            showSavedModal = true
                        } label: {
                            Text("Abrir")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(12)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .shadow(radius: 6)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation {
                                showPlantSavedAlert = false
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(item: $selectedPlant) { plant in
                PlantDetailModalView(plant: plant)
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
                    Button {
                        selectedPlant = plant
                    } label: {
                        PlantCardView(plant: plant)
                    }
                    .buttonStyle(.plain)
                }
            }
        case .error:
            Text(viewModel.errorMessage)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SavedAnalysisModalView: View {
    let imageData: Data
    let title: String
    let summary: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.title.bold()).foregroundStyle(Theme.darkGreen)
                        Text(summary).font(.body).foregroundStyle(.primary)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Resultado")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

private struct PlantDetailModalView: View {
    let plant: PlantGalleryItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let url = plant.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.surface)
                                    .frame(height: 360)
                                    .overlay(ProgressView())
                            case .success(let image):
                                image.resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                if let data = plant.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 360)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12).fill(Theme.surface).frame(height: 360)
                                }
                            @unknown default:
                                RoundedRectangle(cornerRadius: 12).fill(Theme.surface).frame(height: 360)
                            }
                        }
                    } else if let data = plant.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12).fill(Theme.surface).frame(height: 360)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(plant.commonName).font(.title.bold()).foregroundStyle(Theme.darkGreen)
                        if let s = plant.summary {
                            Text(s).font(.body).foregroundStyle(.primary)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Detalhes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

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

private struct PlantCardView: View {
    let plant: PlantGalleryItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(plant.commonName)
                        .font(.headline)
                        .foregroundStyle(Theme.darkGreen)

                    if let confidence = plant.confidence {
                        Text(confidenceLabel(confidence))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.primaryGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.surface)
                            .clipShape(Capsule())
                    }
                }

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
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = plant.thumbnailURL {
            // AsyncImage will fetch and cache the thumbnail from Storage URL
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.surface)
                        .frame(width: 84, height: 84)
                        .overlay(ProgressView().scaleEffect(0.8))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                case .failure:
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.surface)
                        .frame(width: 84, height: 84)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                @unknown default:
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.surface)
                        .frame(width: 84, height: 84)
                }
            }
        } else if let data = plant.thumbnailData, let uiImage = UIImage(data: data) {
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

    private func confidenceLabel(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)%"
    }
}
