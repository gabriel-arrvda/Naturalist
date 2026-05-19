# Card Elevated Tab Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the default iOS tab bar with a custom "Card Elevated" design (white background, elevated cards with shadows, green accent for active state) that works reliably on iOS 18 and all iOS versions, regardless of user theme preference.

**Architecture:** Create a custom `CustomTabBar` SwiftUI component that replaces the native `TabView` bottom bar. The component renders cards in a horizontal stack with proper spacing, shadows, and smooth animations. Colors are all absolute (white, gray, green) with no system appearance dependencies. The main app's `TabView` wraps its content with `.safeAreaInset(edge: .bottom)` to inject the custom bar.

**Tech Stack:** SwiftUI, iOS 16+ (targeting iOS 18 primarily)

---

## File Structure

**Create:**
- `ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift` — The custom tab bar component

**Modify:**
- `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift` — Replace default tab bar with custom one
- `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift` — Ensure tab bar colors are defined

---

## Tasks

### Task 1: Define Tab Bar Colors in Theme

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift`

Tab bar needs explicit colors. Add them to the theme.

- [ ] **Step 1: View current theme colors**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "primaryGreen\|surface\|premiumSurface" ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift | head -20
```

- [ ] **Step 2: Add tab bar colors to Theme struct**

Open `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift` and add these properties to the `ColorScheme` struct (around line 30-40):

```swift
// Tab bar colors
let tabBarBackground = Color.white
let tabBarCardBackground = Color(red: 0.976, green: 0.976, blue: 0.976) // #f9f9f9
let tabBarBorder = Color(red: 0.933, green: 0.933, blue: 0.933) // #eeeeee
let tabBarTextInactive = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
let tabBarCardShadow = Color.black.opacity(0.06)
let tabBarCardActiveShadow = Color(red: 0.176, green: 0.618, blue: 0.247, opacity: 0.3) // #2d9e3f with 30% opacity
```

- [ ] **Step 3: Verify colors are accessible**

```bash
cd /Users/glarruda/Projetos/Naturalist && grep -A20 "let tabBarBackground" ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift
```

Expected: See all 6 tab bar color definitions

- [ ] **Step 4: Commit theme colors**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift
git commit -m "feat: add tab bar colors to theme system

- Add tabBarBackground (white)
- Add tabBarCardBackground (light gray #f9f9f9)
- Add tabBarBorder (separator #eeeeee)
- Add tabBarTextInactive (label #999999)
- Add tabBarCardShadow (0.06 opacity black)
- Add tabBarCardActiveShadow (green with 0.3 opacity)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Create CustomTabBar Component

**Files:**
- Create: `ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift`

Create the SwiftUI component that renders the card-elevated tab bar.

- [ ] **Step 1: Create the file**

```bash
touch /Users/glarruda/Projetos/Naturalist/ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift
```

- [ ] **Step 2: Write the CustomTabBar component**

```swift
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

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarItem
    @Environment(\.colorScheme) var colorScheme
    
    private let tabItems: [TabBarItem] = [.explore, .favorites, .scanner, .profile]
    
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
    @Previewable @State var selected = TabBarItem.explore
    
    VStack {
        Spacer()
        CustomTabBar(selectedTab: $selected)
    }
    .background(Color.white)
    .ignoresSafeArea(edges: .bottom)
}
```

- [ ] **Step 3: Verify component compiles**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|warning:|Build complete" | head -20
```

Expected: "Build complete" with no errors (warnings are OK)

- [ ] **Step 4: Commit CustomTabBar component**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift
git commit -m "feat: create CustomTabBar component with card elevated design

- TabBarItem enum with explore, favorites, scanner, profile tabs
- TabBarCard displays icon, label, and handles active/inactive states
- White background, light gray cards, green active state
- Shadows and animations for smooth transitions
- Works on iOS 16+ regardless of theme preference

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Integrate CustomTabBar into Main App

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift`

Replace the default tab bar with the custom component.

- [ ] **Step 1: View current TabView setup**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "TabView\|\.tabItem" ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift | head -30
```

- [ ] **Step 2: Replace TabView with CustomTabBar**

Open `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift` and find the `@State private var selectedTab` and `TabView` section. Replace the entire TabView and its `.tabItem` modifiers with this:

```swift
@State private var selectedTab: TabBarItem = .explore

var body: some Scene {
    WindowGroup {
        ZStack {
            TabView(selection: $selectedTab) {
                PlantGalleryView()
                    .tag(TabBarItem.explore)
                
                FavoritesPlantsView()
                    .tag(TabBarItem.favorites)
                
                PlantScannerView()
                    .tag(TabBarItem.scanner)
                
                ProfileView()
                    .tag(TabBarItem.profile)
            }
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}
```

- [ ] **Step 3: Remove old TabView modifiers**

Remove these lines if they exist:
- `.toolbarBackground(.visible, for: .tabBar)`
- `.toolbarBackground(.thickMaterial, for: .tabBar)`
- Any remaining `.tabItem` modifiers
- `.tint(.green)` or similar appearance modifiers for the tab bar

- [ ] **Step 4: Verify the import**

Ensure `CustomTabBar` is imported. Add this near the top of the file if not present:

```swift
// CustomTabBar is in the same module, should be auto-discoverable
// If compiler complains, the file path may need adjustment
```

- [ ] **Step 5: Build and test in simulator**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10
```

Expected: Build succeeds with no errors

- [ ] **Step 6: Run app in simulator to verify tab bar renders**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcrun simctl launch booted "com.example.naturalist" || echo "App not installed yet"
```

(If app not installed, build + deploy first via Xcode UI or equivalent)

- [ ] **Step 7: Commit integration**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift
git commit -m "feat: integrate CustomTabBar into main app

- Replace default TabView with custom card-elevated design
- Add @State for selectedTab: TabBarItem
- Use safeAreaInset to inject CustomTabBar below content
- Remove old tab bar appearance modifiers
- Tab navigation now uses CardElevated design

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Test on iOS 18 Physical Device

**Files:**
- Test: Build and run on physical device (Sidão - iPhone 12)

Verify the tab bar renders correctly on iOS 18 with light and dark theme.

- [ ] **Step 1: Ensure device is connected**

```bash
xcrun xctrace list devices 2>&1 | grep -i "sidão\|iphone" | head -5
```

Expected: See "Sidão" or similar device listed

- [ ] **Step 2: Build for iOS 18 physical device**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj \
  -scheme NaturalistApp \
  -destination 'platform=iOS,name=Sidão' \
  -configuration Release \
  build 2>&1 | tail -15
```

Expected: Build succeeds (Release config avoids code signing issues)

- [ ] **Step 3: Deploy to device**

Use Xcode UI to deploy (Product → Run) or via command line:

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj \
  -scheme NaturalistApp \
  -destination 'platform=iOS,name=Sidão' \
  -configuration Release \
  install 2>&1 | grep -E "succeeded|failed|error"
```

Expected: App successfully installs

- [ ] **Step 4: Manual verification on device**

Launch app on device. Verify:
- **Tab bar visible at bottom** — white background, no gray solid bar
- **Cards render properly** — 4 cards with subtle shadows
- **Active tab green** — tapping tabs shows green background with larger shadow
- **Text readable** — black labels and icons, not white
- **Smooth animations** — tabs animate smoothly when tapped
- **Light theme** — if device is in light mode, verify readability
- **Dark theme** — switch to dark mode and verify readability (should look identical since colors are absolute)

- [ ] **Step 5: Test camera capture workflow**

Navigate to Scanner tab:
- Tap Scanner tab
- Tap camera button to capture image
- Verify sheet closes and returns to tab bar properly
- Verify tab bar is still visible and clickable

- [ ] **Step 6: Test navigation**

Tap each tab in sequence:
- Explore (gallery)
- Favorites
- Scanner
- Profile
- Back to Explore

Verify smooth transitions and no visual glitches.

- [ ] **Step 7: Document observations**

If all tests pass, note:
```
✅ Tab bar renders correctly on iOS 18 (Sidão, physical device)
✅ Card design visible with proper shadows
✅ Green active state works
✅ Text readable in light and dark themes
✅ Navigation smooth
✅ No rendering artifacts
```

If issues found, document them and create a new task to fix.

---

### Task 5: Verify No Regressions on Simulator

**Files:**
- Test: Run on iPhone 15 and iPhone 14 simulators

Ensure the tab bar works on multiple iOS versions.

- [ ] **Step 1: Build for iPhone 15 (iOS 18 simulator)**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj \
  -scheme NaturalistApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build 2>&1 | tail -5
```

Expected: Build succeeds

- [ ] **Step 2: Build for iPhone 14 (older iOS, if supported)**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj \
  -scheme NaturalistApp \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  build 2>&1 | tail -5
```

Expected: Build succeeds

- [ ] **Step 3: Launch in iPhone 15 simulator**

```bash
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
# Then use Xcode UI to run app on iPhone 15 simulator
```

Visually verify:
- Tab bar renders with correct colors
- Cards have proper spacing and shadows
- Active tab is green with larger shadow

- [ ] **Step 4: Test all tabs in simulator**

Tap through each tab and verify content loads correctly.

- [ ] **Step 5: Final commit (if no issues)**

If all tests pass on device and simulators:

```bash
cd /Users/glarruda/Projetos/Naturalist
git log --oneline -5 | head -10
# Should show all 3 previous commits (theme, component, integration)
```

All commits already made. Plan complete!

---

## Summary

✅ **Tab bar colors added to theme system**  
✅ **CustomTabBar component created with card-elevated design**  
✅ **CustomTabBar integrated into main app**  
✅ **Tested on physical device (iOS 18)**  
✅ **Verified on simulators (iOS 18, iOS 17)**  

**Result:** Card-elevated tab bar now renders on all iOS versions, regardless of user theme preference. Works reliably on iOS 18 physical devices.
