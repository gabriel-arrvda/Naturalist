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
            List {
                header
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))

                stateContent
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.white.ignoresSafeArea())
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
                            Text("Planta salva")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.primaryGreen)
                            Text(plantSavedTitle)
                                .font(.subheadline).bold()
                                .foregroundStyle(Theme.darkGreen)
                                .lineLimit(1)
                            Text(plantSavedSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button {
                            showSavedModal = true
                        } label: {
                            Text("Abrir")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.cardBorder.opacity(0.9), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 16)
                    .shadow(color: Theme.premiumShadow, radius: 14, x: 0, y: 8)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Meus Plantas")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.neuTextPrimary)
                    Text("Últimas buscas com foto, nome e resumo.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.neuTextTertiary)
                }
                Spacer()
                Text("\(viewModel.plants.count)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.neuPrimaryGreen)
                    .frame(width: 44, height: 44)
                    .background(Theme.neuWhite)
                    .overlay(
                        Circle()
                            .stroke(Theme.neuCardBorder, lineWidth: 1.5)
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            if viewModel.plants.isEmpty {
                ProgressView("Carregando plantas salvas...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            } else {
                plantsList
            }
        case .loaded:
            if viewModel.plants.isEmpty {
                EmptyStateView()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            } else {
                plantsList
            }
        case .error:
            if viewModel.plants.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                    plantsList
                }
            }
        }
    }

    @ViewBuilder
    private var plantsList: some View {
        ForEach(viewModel.plants) { plant in
            Button {
                selectedPlant = plant
            } label: {
                PlantCardView(plant: plant)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
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
                VStack(alignment: .leading, spacing: 18) {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: Theme.premiumShadow, radius: 18, x: 0, y: 10)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resultado salvo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.primaryGreen)
                        Text(title)
                            .font(.title.bold())
                            .foregroundStyle(Theme.darkGreen)
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(Color.black)
                    }
                    .padding(20)
                    .background(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                VStack(alignment: .leading, spacing: 18) {
                    if let url = plant.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.surface)
                                    .frame(maxHeight: 180)
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 180)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            case .failure:
                                if let data = plant.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 180)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Theme.surface)
                                        .frame(maxHeight: 180)
                                }
                            @unknown default:
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Theme.surface)
                                    .frame(maxHeight: 180)
                            }
                        }
                        .shadow(color: Theme.premiumShadow, radius: 16, x: 0, y: 10)
                    } else if let data = plant.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Theme.premiumShadow, radius: 16, x: 0, y: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.surface)
                            .frame(maxHeight: 180)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detalhes da planta")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.primaryGreen)
                        Text(plant.commonName)
                            .font(.title.bold())
                            .foregroundStyle(Theme.darkGreen)
                        if let s = plant.summary {
                            Text(s)
                                .font(.body)
                                .foregroundStyle(Color.black)
                        }
                    }
                    .padding(20)
                    .background(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        VStack(spacing: 14) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.neuPrimaryGreen)
                .frame(width: 64, height: 64)
            Text("Nenhuma planta salva ainda.")
                .font(.headline)
                .foregroundStyle(Theme.neuTextPrimary)
            Text("As plantas buscadas aparecem aqui com a última foto enviada.")
                .font(.subheadline)
                .foregroundStyle(Theme.neuTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Theme.neuWhite)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.neuCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

private struct PlantCardView: View {
    let plant: PlantGalleryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed height image (140px)
            plantImage
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()

            // Info section
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(plant.commonName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.neuTextPrimary)
                    .lineLimit(1)

                // Summary
                Text(SummaryFormatter.cleaned(plant.summary))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Theme.neuTextTertiary)
                    .lineLimit(2)

                // Detalhes button
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Detalhes")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .foregroundStyle(.white)
                .background(Theme.neuPrimaryGreen)
                .cornerRadius(8)
            }
            .padding(12)
        }
        .background(Theme.neuWhite)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.neuCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var plantImage: some View {
        if let url = plant.thumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Theme.neuCardBackground)
                        .overlay(ProgressView().scaleEffect(0.8))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(Theme.neuCardBackground)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .foregroundStyle(Theme.neuTextDisabled)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Theme.neuCardBackground)
                }
            }
        } else if let data = plant.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Theme.neuCardBackground)
                .overlay(
                    Image(systemName: "photo.fill")
                        .foregroundStyle(Theme.neuTextDisabled)
                )
        }
    }
}
