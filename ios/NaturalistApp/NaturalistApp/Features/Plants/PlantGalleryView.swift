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

    private func confidenceLabel(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)%"
    }
}
