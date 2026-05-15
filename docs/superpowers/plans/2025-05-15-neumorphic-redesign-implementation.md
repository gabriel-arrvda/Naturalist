# Neumorphic Redesign - 2 Tabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Naturalist app with neumorphic system, reduce to 2 tabs (Plants & Scanner), fix modal image overflow, use SF Symbols icons.

**Architecture:** Simplify TabView from 4 to 2 tabs. Update PlantGalleryView with neumorphic cards and fixed image containers. Update PlantScannerView with refined styling. Replace all emojis with SF Symbols. Use absolute colors (no system appearance dependencies) to ensure iOS 18 compatibility.

**Tech Stack:** SwiftUI, SF Symbols, iOS 16+

---

## File Structure

**Modify:**
- `ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift` — Reduce TabBarItem enum to 2 cases
- `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift` — Add neumorphic color system
- `ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryView.swift` — Update styling, fix image overflow
- `ios/NaturalistApp/NaturalistApp/Features/Plants/PlantDetailModalView.swift` — Fix image container sizing
- `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift` — Update to neumorphic design

---

## Tasks

### Task 1: Update CustomTabBar for 2 Tabs

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift`

Reduce TabBarItem enum from 4 cases to 2 (Plants, Scanner) and update icons to SF Symbols.

- [ ] **Step 1: View current CustomTabBar code**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "enum TabBarItem" ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift -A 20
```

- [ ] **Step 2: Update TabBarItem enum to 2 cases**

Replace the `TabBarItem` enum (lines ~5-25) with:

```swift
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
```

- [ ] **Step 3: Verify CustomTabBar renders 2 tabs**

The CustomTabBar struct uses `private let tabItems: [TabBarItem] = [.explore, .favorites, .scanner, .profile]`. Update to:

```swift
private let tabItems: [TabBarItem] = [.plants, .scanner]
```

- [ ] **Step 4: Build to verify no compilation errors**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|Build complete"
```

Expected: "Build complete" with no errors

- [ ] **Step 5: Commit**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/UI/Components/CustomTabBar.swift
git commit -m "feat: reduce tab bar to 2 tabs (plants, scanner)

- Update TabBarItem enum: remove favorites and profile
- Add SF Symbols: leaf.fill for plants, camera.fill for scanner
- Update tabItems array to only include plants and scanner tabs

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Add Neumorphic Colors to Theme

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift`

Add neumorphic color system to ensure consistent styling across all screens.

- [ ] **Step 1: View current Theme colors**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "primaryGreen\|surface\|premiumSurface" ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift | head -20
```

- [ ] **Step 2: Add neumorphic colors to ColorScheme struct**

Add these properties alongside existing colors (find the `struct` or `enum` that holds colors):

```swift
// Neumorphic Design System
let neuWhite = Color.white
let neuCardBackground = Color(red: 0.976, green: 0.976, blue: 0.976) // #f9f9f9
let neuCardBorder = Color(red: 0.941, green: 0.941, blue: 0.941) // #f0f0f0
let neuShadow = Color.black.opacity(0.08)
let neuShadowElevated = Color.black.opacity(0.12)
let neuTextPrimary = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
let neuTextSecondary = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
let neuTextTertiary = Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
let neuTextDisabled = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
let neuGreen = Color(red: 0.176, green: 0.618, blue: 0.247) // #2d9e3f
let neuGreenShadow = Color(red: 0.176, green: 0.618, blue: 0.247, opacity: 0.3)
```

- [ ] **Step 3: Verify colors compile**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|Build complete"
```

Expected: "Build complete"

- [ ] **Step 4: Commit**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/UI/Theme/Theme.swift
git commit -m "feat: add neumorphic color system to theme

- Add neuWhite, neuCardBackground, neuCardBorder
- Add neuShadow (0.08) and neuShadowElevated (0.12)
- Add text colors: neuTextPrimary (#000), Secondary (#333), Tertiary (#666), Disabled (#999)
- Add neuGreen (#2d9e3f) and neuGreenShadow for accents

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Update NaturalistApp to Use 2 Tabs

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift`

Update the main app TabView to use only 2 tabs (Plants and Scanner).

- [ ] **Step 1: View current TabView setup**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "selectedTab\|TabView\|tag(TabBarItem" ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift | head -20
```

- [ ] **Step 2: Update selectedTab default value**

Find the line `@State private var selectedTab: TabBarItem = .explore` and change to:

```swift
@State private var selectedTab: TabBarItem = .plants
```

- [ ] **Step 3: Update TabView to 2 tabs**

In the TabView, keep only Plants and Scanner tabs. Replace the TabView content (inside the `ZStack`) with:

```swift
TabView(selection: $selectedTab) {
    PlantGalleryView()
        .tag(TabBarItem.plants)
    
    PlantScannerView()
        .tag(TabBarItem.scanner)
}
.ignoresSafeArea(edges: .bottom)
.safeAreaInset(edge: .bottom) {
    CustomTabBar(selectedTab: $selectedTab)
}
```

Remove the Favorites and Profile tab blocks entirely.

- [ ] **Step 4: Build and verify**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|Build complete"
```

Expected: "Build complete"

- [ ] **Step 5: Commit**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/App/NaturalistApp.swift
git commit -m "feat: reduce app to 2 tabs (plants, scanner)

- Update selectedTab default to .plants
- Replace TabView with only Plants and Scanner tabs
- Remove Favorites and Profile tab views
- CustomTabBar now shows 2 tabs instead of 4

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Fix PlantDetailModalView Image Overflow Bug

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/Features/Plants/PlantDetailModalView.swift`

Fix the modal image container to use proper sizing (max-height 180px, aspect ratio) to prevent overflow and text wrapping issues.

- [ ] **Step 1: View PlantDetailModalView structure**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "class PlantDetailModalView\|Image\|VStack\|ScrollView" ios/NaturalistApp/NaturalistApp/Features/Plants/PlantDetailModalView.swift | head -30
```

- [ ] **Step 2: Find image rendering code**

Look for lines where image is displayed. Typically around `Image(uiImage:)` or `AsyncImage`.

- [ ] **Step 3: Update image container with fixed sizing**

Update the image rendering to:

```swift
Image(uiImage: plant.image)
    .resizable()
    .scaledToFit()
    .frame(maxHeight: 180)
    .clipped()
```

Or if using AsyncImage, wrap it similarly:

```swift
AsyncImage(url: URL(string: plant.imageURL)) { image in
    image
        .resizable()
        .scaledToFit()
        .frame(maxHeight: 180)
        .clipped()
} placeholder: {
    Color.gray.opacity(0.3)
        .frame(maxHeight: 180)
}
```

- [ ] **Step 4: Ensure content is scrollable**

Wrap the detail content (title, description, etc.) in a ScrollView:

```swift
VStack(spacing: 0) {
    // Image container at top
    Image(...)
        .frame(maxHeight: 180)
    
    // Scrollable content below
    ScrollView {
        VStack(spacing: 12) {
            // Title
            Text(plant.name)
                .font(.largeTitle.bold())
                .foregroundStyle(Color.black)
            
            // Other details...
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 5: Add proper frame constraints**

Ensure modal VStack has explicit frame:

```swift
.frame(maxWidth: .infinity, maxHeight: .infinity)
.background(Color.white)
```

- [ ] **Step 6: Build and verify**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|Build complete"
```

- [ ] **Step 7: Commit**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/Features/Plants/PlantDetailModalView.swift
git commit -m "fix: prevent image overflow in plant detail modal

- Add maxHeight: 180 constraint to image
- Use scaledToFit() for proper aspect ratio
- Wrap detail content in ScrollView for long text
- Add clipped() to ensure no overflow
- Prevent horizontal text wrapping

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: Redesign PlantGalleryView with Neumorphic Style

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryView.swift`

Update PlantGalleryView to use neumorphic card design with SF Symbols and proper image sizing.

- [ ] **Step 1: View current gallery structure**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "VStack\|HStack\|Image\|Text" ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryView.swift | head -40
```

- [ ] **Step 2: Update header styling**

Find the header section and update to:

```swift
private var header: some View {
    VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Meus Plantas")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.black)
                Text("Últimas buscas com foto, nome e resumo.")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            Spacer()
            Text("\(viewModel.plants.count)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.black)
                .frame(width: 40, height: 40)
                .background(Color(red: 0.976, green: 0.976, blue: 0.976))
                .overlay(Circle().stroke(Color(red: 0.941, green: 0.941, blue: 0.941), lineWidth: 1))
                .clipShape(Circle())
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 3: Update plant card styling**

Create or update a plant card view with neumorphic design:

```swift
private func plantCard(for plant: PlantGalleryItem) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        // Image container - fixed height with aspect ratio
        if let imageData = plant.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
        } else {
            Color(red: 0.976, green: 0.976, blue: 0.976)
                .frame(height: 140)
        }
        
        // Info section
        VStack(alignment: .leading, spacing: 8) {
            Text(plant.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black)
            
            Text(plant.summary)
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                .lineLimit(2)
            
            Button {
                selectedPlant = plant
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Detalhes")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(red: 0.176, green: 0.618, blue: 0.247))
                .cornerRadius(8)
            }
        }
        .padding(12)
    }
    .background(Color.white)
    .border(Color(red: 0.941, green: 0.941, blue: 0.941), width: 1)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
}
```

- [ ] **Step 4: Update plant list layout**

In the `stateContent` or similar section, replace the plant list rendering with:

```swift
ForEach(viewModel.plants, id: \.id) { plant in
    plantCard(for: plant)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .onTapGesture {
            selectedPlant = plant
        }
}
```

- [ ] **Step 5: Update search box styling**

If there's a search box, update to neumorphic style:

```swift
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
    TextField("Search plants...", text: $searchText)
}
.padding(12)
.background(Color(red: 0.976, green: 0.976, blue: 0.976))
.cornerRadius(12)
.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.933, green: 0.933, blue: 0.933), lineWidth: 1))
.shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 0.5)
```

- [ ] **Step 6: Build and verify**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|Build complete"
```

- [ ] **Step 7: Commit**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/Features/Plants/PlantGalleryView.swift
git commit -m "feat: redesign plant gallery with neumorphic style

- Update header with black text and proper sizing
- Create plantCard() with neumorphic design:
  - Fixed image height (140px) with clipped()
  - White card background with light border
  - Subtle shadows (0 2px 8px)
  - Green 'Detalhes' button with SF Symbol
- Update plant count badge with neumorphic style
- Add search box with neumorphic styling

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 6: Redesign PlantScannerView with Neumorphic Style

**Files:**
- Modify: `ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift`

Update PlantScannerView to match neumorphic design system with SF Symbols.

- [ ] **Step 1: View current scanner structure**

```bash
cd /Users/glarruda/Projetos/Naturalist
grep -n "heroCard\|actionsCard\|Image\|Text" ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift | head -30
```

- [ ] **Step 2: Update hero card styling**

Update the `heroCard` to use neumorphic colors:

```swift
private var heroCard: some View {
    VStack(alignment: .leading, spacing: 10) {
        Text("IDENTIFY PLANTS")
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(Color(red: 0.176, green: 0.618, blue: 0.247))
        Text("Scan any plant to identify")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(Color.black)
        Text("Point camera at plant, capture, and get instant identification.")
            .font(.subheadline)
            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
}
```

- [ ] **Step 3: Update camera preview card**

Update the camera preview area (if exists) or previewCard:

```swift
private var previewCard: some View {
    VStack(spacing: 12) {
        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
        } else {
            VStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.white)
                Text("Point camera at plant")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
        
        Text("Select image or capture with camera")
            .font(.caption)
            .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
    }
    .frame(maxWidth: .infinity)
    .padding(12)
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
}
```

- [ ] **Step 4: Update action buttons**

Update camera and gallery buttons with SF Symbols:

```swift
private var actionsCard: some View {
    HStack(spacing: 12) {
        Button {
            showCamera = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                Text("Câmera")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.176, green: 0.618, blue: 0.247))
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        
        Button {
            // Show photo picker
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                Text("Galeria")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.976, green: 0.976, blue: 0.976))
            .foregroundStyle(Color.black)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.933, green: 0.933, blue: 0.933), lineWidth: 1))
        }
    }
}
```

- [ ] **Step 5: Update analyze button**

Update the analyze button to green neumorphic style:

```swift
private var analyzeButton: some View {
    Button {
        Task { await viewModel.analyze() }
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("Analisar")
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(red: 0.176, green: 0.618, blue: 0.247))
        .foregroundStyle(.white)
        .cornerRadius(8)
        .shadow(color: Color(red: 0.176, green: 0.618, blue: 0.247, opacity: 0.3), radius: 4, x: 0, y: 2)
    }
}
```

- [ ] **Step 6: Build and verify**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -E "error:|Build complete"
```

- [ ] **Step 7: Commit**

```bash
cd /Users/glarruda/Projetos/Naturalist
git add ios/NaturalistApp/NaturalistApp/Features/Scanner/PlantScannerView.swift
git commit -m "feat: redesign scanner with neumorphic style

- Update hero card with black text and subtle shadow
- Update preview card with fixed 180px height, clipped image
- Replace emoji icons with SF Symbols (camera.fill, photo.fill, sparkles)
- Green buttons for primary actions (Câmera, Analisar)
- Gray buttons for secondary actions (Galeria)
- Consistent neumorphic styling across all elements

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 7: Test Redesign on Device and Simulator

**Files:**
- Test: Build and run on iOS 18 physical device and simulators

Verify the neumorphic redesign works correctly on iOS 18 and all screens display properly.

- [ ] **Step 1: Build for iPhone 15 simulator**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj -scheme NaturalistApp -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -5
```

Expected: Build succeeds

- [ ] **Step 2: Test on simulator**

Launch app in simulator and verify:
- Tab bar shows only 2 tabs (🌿 Plants | 📷 Scanner)
- Plants tab: Gallery with cards, search box, proper image sizing
- Scanner tab: Camera area, buttons, hero card
- No image overflow in plant cards or modal
- Text readable (black on white)
- SF Symbols render correctly
- All shadows visible and subtle

- [ ] **Step 3: Build Release for physical device**

```bash
cd /Users/glarruda/Projetos/Naturalist
xcodebuild -project ios/NaturalistApp/NaturalistApp.xcodeproj \
  -scheme NaturalistApp \
  -destination 'platform=iOS,name=Sidão' \
  -configuration Release \
  build 2>&1 | tail -10
```

Expected: Build succeeds

- [ ] **Step 4: Deploy to physical device**

Use Xcode UI (Product → Run) or command line to install on Sidão.

- [ ] **Step 5: Test on iOS 18 device**

On Sidão, verify:
- **Tab bar:** 2 tabs visible, card-elevated design
- **Plants tab:** Gallery loads, cards display properly, no image overflow
- **Plant detail modal:** Image doesn't expand, text doesn't wrap oddly
- **Scanner tab:** All controls visible, camera button works
- **Light/Dark theme:** Identical appearance (colors are absolute)
- **Navigation:** Smooth transitions between tabs
- **Text readability:** Black text on white, clear and legible
- **Animations:** Smooth tab transitions

- [ ] **Step 6: Test camera workflow**

- Tap Scanner tab
- Tap Camera button
- Capture image (or select from photos)
- Verify image displays in preview
- Tap Analyze
- Verify result appears

- [ ] **Step 7: Document observations**

If all tests pass:
```
✅ 2 tabs only - Plants and Scanner visible
✅ Neumorphic design - White background, subtle shadows, green accents
✅ No image overflow - Plant cards and modal images properly sized
✅ SF Symbols - All icons render correctly
✅ Text readable - Black text on white, proper contrast
✅ iOS 18 compatible - Works on physical device
✅ Theme agnostic - Identical in light and dark mode
```

If issues found, document for fixing.

---

## Summary

✅ **Reduced to 2 tabs** - Plants and Scanner only  
✅ **Neumorphic design** - Consistent colors, shadows, spacing  
✅ **Fixed image overflow** - Plant detail modal images properly sized  
✅ **SF Symbols icons** - Modern, native iOS icons  
✅ **iOS 18 compatible** - Absolute colors, no theme dependencies  

**Result:** Naturalist app now has a clean, elegant neumorphic design with 2 focused tabs and no visual glitches.
