import SwiftUI

enum TabBarItem: Hashable {
    case plants
    case scanner
    
    var label: String {
        switch self {
        case .plants: return "Plants"
        case .scanner: return "Scanner"
        }
    }
    
    var icon: String {
        switch self {
        case .plants: return "leaf.fill"
        case .scanner: return "camera.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarItem
    @Environment(\.colorScheme) var colorScheme
    
    private let tabItems: [TabBarItem] = [.plants, .scanner]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .frame(height: 1)
                .background(Color(red: 0.933, green: 0.933, blue: 0.933)) // #eeeeee
            
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
            .padding(.bottom, 4) // Minimal bottom margin
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
                    ? Color(red: 0.176, green: 0.618, blue: 0.247) // #2d9e3f
                    : Color(red: 0.976, green: 0.976, blue: 0.976) // #f9f9f9
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
            .scaleEffect(isActive ? 0.98 : 1.0) // Subtle lift via inverse scale
            .offset(y: isActive ? -2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var selected = TabBarItem.plants
    
    VStack {
        Spacer()
        CustomTabBar(selectedTab: $selected)
    }
    .background(Color.white)
    .ignoresSafeArea(edges: .bottom)
}
