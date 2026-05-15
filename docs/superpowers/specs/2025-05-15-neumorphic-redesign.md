# Neumorphic Redesign - 2 Tabs Implementation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Naturalist iOS app with neumorphic system, reduce to 2 tabs (Plants & Scanner), fix modal image overflow bug, use SF Symbols for icons.

**Architecture:** Simplify TabView to 2 tabs (Plants, Scanner). Update PlantGalleryView with neumorphic card layout and fix image container sizing to prevent overflow. Update PlantScannerView with refined neumorphic styling. Replace all emojis with SF Symbols icons. Use absolute colors (white, grays, green) with no system appearance dependencies.

**Tech Stack:** SwiftUI, SF Symbols, iOS 16+

---

## Design System

### Color Palette
- **Background:** #ffffff (white)
- **Card Background:** #f9f9f9 (light gray - secondary surfaces)
- **Card Border:** #f0f0f0 (light border)
- **Primary Green:** #2d9e3f (actions, active state, accents)
- **Text Primary:** #000000 (titles, headings)
- **Text Secondary:** #333333 (body text)
- **Text Tertiary:** #666666 (supporting text)
- **Text Disabled:** #999999 (labels, secondary info)
- **Border Light:** #eeeeee (separators)

### Spacing & Sizing
- **Card Corner Radius:** 16px
- **Button Corner Radius:** 8px
- **Card Shadow:** 0 2px 8px rgba(0, 0, 0, 0.08)
- **Elevated Shadow:** 0 4px 12px rgba(0, 0, 0, 0.12)
- **Padding Standard:** 16px
- **Padding Compact:** 12px
- **Gap Standard:** 12px
- **Gap Compact:** 8px

### Typography
- **Title (Large):** system font, 28px, bold
- **Heading 1:** system font, 18px, bold
- **Heading 2:** system font, 14px, semibold
- **Body:** system font, 14px, regular
- **Caption:** system font, 12px, regular
- **Label:** system font, 11px, semibold

### SF Symbols Used
- **Plants Tab Icon:** `leaf.fill`
- **Scanner Tab Icon:** `camera.fill`
- **View Details:** `info.circle`
- **Camera:** `camera`
- **Capture:** `circle.inset.filled`
- **Search:** `magnifyingglass`

---

## Implementation Requirements

### Tab Bar Changes
- **Reduce from 4 tabs to 2:** Only "Plants" and "Scanner" tabs
- **Update CustomTabBar enum:** Remove Favorites and Profile cases
- **Update theme:** Ensure tab bar colors align with neumorphic system

### Plants Screen (PlantGalleryView)
**Fixed Issues:**
- Modal image overflow: Use `aspectRatio(contentMode: .fit)` with `frame(maxHeight: 180)`
- Prevent container expansion: Add explicit frame constraints
- Text wrapping: Ensure text doesn't overflow modal width

**Styling:**
- Replace all emojis with SF Symbols or proper images
- Header with title "Meus Plantas" and plant count
- Each plant card:
  - Neumorphic card with white background
  - Proporcional image (max 180px height)
  - Padding: 12px top/bottom inside card, 16px left/right
  - Title (14px, bold, #000)
  - Species (12px, #999)
  - "Detalhes" button (green, SF Symbol: info.circle)
- Card styling:
  - Border: 1px #f0f0f0
  - Shadow: 0 2px 8px rgba(0, 0, 0, 0.08)
  - Corner radius: 16px

**Modal (PlantDetailModalView):**
- Fixed height image container with aspect ratio
- Scrollable content below image
- No horizontal overflow
- Padding: 16px
- Clean, simple layout

### Scanner Screen (PlantScannerView)
**Styling Updates:**
- Hero card: White background, subtle shadow
- Replace emoji icons with SF Symbols
- Buttons: Green (#2d9e3f) with proper sizing
- Loading indicator: Keep existing, ensure visibility
- Result card: Clean presentation with neumorphic styling

### Components to Create/Update
1. **CustomTabBar.swift** - Update TabBarItem enum (only 2 cases)
2. **PlantGalleryView.swift** - Update styling, fix image overflow
3. **PlantDetailModalView.swift** - Fix image container, add scroll handling
4. **PlantScannerView.swift** - Update styling with neumorphic design
5. **Theme.swift** - Verify neumorphic colors are defined

---

## Key Bug Fixes

### Image Container Overflow Fix
**Current Problem:** When modal opens with image, container expands horizontally, causing text to overflow.

**Solution:**
```swift
Image(uiImage: image)
    .resizable()
    .scaledToFit()  // Or aspectRatio(contentMode: .fit)
    .frame(maxHeight: 180)
    .clipped()  // Ensure no overflow
```

**Apply to:**
- Plant detail modal image
- Scanner preview image
- Plant gallery card images

### Modal Layout Fix
**Use ScrollView for content:**
```swift
VStack(spacing: 0) {
    // Image at top
    Image(...)
        .frame(maxHeight: 180)
    
    // Scrollable content
    ScrollView {
        VStack(spacing: 12) {
            // Details...
        }
        .padding(16)
    }
}
```

---

## Success Criteria

✅ **2 tabs only** - Plants and Scanner visible, Favorites/Profile removed  
✅ **SF Symbols** - All emojis replaced with proper icons  
✅ **No image overflow** - Modal images stay within bounds  
✅ **Neumorphic styling** - Consistent white/gray/green across all screens  
✅ **Text readable** - Black text on white, proper contrast  
✅ **Responsive layout** - Works on iPhone 12, 14, 15  
✅ **iOS 18 compatible** - Tested on physical device and simulators  
✅ **No visual glitches** - Smooth scrolling, animations, interactions
