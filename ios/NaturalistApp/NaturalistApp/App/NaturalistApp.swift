import SwiftUI

enum TabBarItem: Hashable {
    case explore
    case favorites
    case scanner
    case profile
    
    var label: String {
        switch self {
        case .explore: return "Explore"
        case .favorites: return "Favorites"
        case .scanner: return "Scanner"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .explore: return "safari"
        case .favorites: return "star.fill"
        case .scanner: return "plus.circle.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

@main
struct NaturalistApp: App {
    @State private var selectedTab: TabBarItem = .explore
    
    private let plantService = PlantAPIClient(
        baseURL: URL(string: "http://187.127.253.190:8000")!
    )
    private let scannerViewModel: PlantScannerViewModel
    private let galleryViewModel: PlantGalleryViewModel

    init() {
        scannerViewModel = PlantScannerViewModel(service: plantService)
        galleryViewModel = PlantGalleryViewModel(service: plantService)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView(selection: $selectedTab) {
                    PlantGalleryView(viewModel: galleryViewModel)
                        .tag(TabBarItem.explore)
                    
                    PlantGalleryView(viewModel: galleryViewModel)
                        .tag(TabBarItem.favorites)
                    
                    PlantScannerView(viewModel: scannerViewModel)
                        .tag(TabBarItem.scanner)
                    
                    PlantGalleryView(viewModel: galleryViewModel)
                        .tag(TabBarItem.profile)
                }
                .ignoresSafeArea(edges: .bottom)
                .safeAreaInset(edge: .bottom) {
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarItem
    @Environment(\.colorScheme) var colorScheme
    
    private let tabItems: [TabBarItem] = [.explore, .favorites, .scanner, .profile]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .frame(height: 1)
                .background(Color(red: 0.933, green: 0.933, blue: 0.933))
            
            HStack(spacing: 12) {
                ForEach(tabItems, id: \.self) { tab in
                    TabBarCard(
                        tab: tab,
                        isActive: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .padding(.bottom, 4)
            .frame(height: 68)
            .background(Color.white)
        }
    }
}

struct TabBarCard: View {
    let tab: TabBarItem
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isActive ? .white : Color(red: 0.6, green: 0.6, blue: 0.6))
                
                Text(tab.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isActive ? .white : Color(red: 0.6, green: 0.6, blue: 0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isActive
                    ? Color(red: 0.176, green: 0.618, blue: 0.247)
                    : Color(red: 0.976, green: 0.976, blue: 0.976)
            )
            .cornerRadius(10)
            .shadow(
                color: isActive
                    ? Color(red: 0.176, green: 0.618, blue: 0.247, opacity: 0.3)
                    : Color.black.opacity(0.06),
                radius: isActive ? 8 : 2,
                x: 0,
                y: isActive ? 4 : 1
            )
            .scaleEffect(isActive ? 0.98 : 1.0)
            .offset(y: isActive ? -2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
