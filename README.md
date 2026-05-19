# KIT305 Assignment 3 – iOS Interior Design Quoting App

## Recommended Simulator

**iPhone 15, iOS 17, Portrait orientation**

> ⚠️ **Marker Note:** Before running the app, replace `A3-ios/A3-ios/GoogleService-Info.plist` with your real `GoogleService-Info.plist` downloaded from the Firebase Console for your Firestore project. The placeholder file in this repo will cause Firebase to fail to initialise.

### Bundle Identifier (after cloning)

All targets ship with the bundle id prefix **`au.edu.utas.kit305.A3`** (app = `au.edu.utas.kit305.A3`, tests = `au.edu.utas.kit305.A3.A3-iosTests`, UI tests = `au.edu.utas.kit305.A3.A3-iosUITests`). This matches the included `GoogleService-Info.plist`.

If Xcode rewrites the bundle id automatically when you open the project with your own Apple ID (because the id is already registered to another developer account on App Store Connect), set it back manually:

1. Select the project in the Project Navigator → **A3-ios** target → **Signing & Capabilities**.
2. Change **Bundle Identifier** back to `au.edu.utas.kit305.A3`.
3. Select **Team = None** (the simulator does not need signing) — or, if you must sign for a real device, leave your team selected but **uncheck "Automatically manage signing"** to stop Xcode from rewriting the id.
4. Repeat for the `A3-iosTests` and `A3-iosUITests` targets if needed.

---

## App Overview

This is a native iOS application written in Swift using the UIKit Storyboard approach. It is a port of the KIT305 Assignment 2 Android app (interior design quoting tool for salespeople).

The app allows salespeople to:
- Manage **houses** (customer job sites)
- Manage **rooms** within each house
- Record **windows** and **floor spaces** within each room, with product/variant selection and photo attachment
- Generate an itemised **quote** per house with discount and CSV export

---

## View Controllers and Interrelation

| View Controller | Purpose | Navigates To |
|---|---|---|
| `HouseListViewController` | Shows all houses in a table view. Supports search, add, edit (swipe), delete (swipe). Initial VC embedded in UINavigationController. | `HouseEditViewController` (add/edit), `RoomListViewController` (tap row), `QuoteViewController` (Quote button) |
| `HouseEditViewController` | Form to create or update a house (customer name, address, and a free-form **Notes** field). Validates non-empty name + address. | Pops back on save |
| `RoomListViewController` | Shows all rooms for a house with thumbnail photos. Supports search, add room (alert), rename, **duplicate** (leading swipe — copies all windows + floors), delete (swipe). | `RoomDetailViewController` (tap row), `QuoteViewController` (Quote button) |
| `RoomDetailViewController` | Two-section view for a room: Windows (§0) and Floor Spaces (§1). Top header shows the room cover photo (gallery or camera). Footer buttons add items. Swipe to delete. | `WindowEditViewController`, `FloorSpaceEditViewController` |
| `WindowEditViewController` | Form to add/edit a window. Width × Height (mm, integer), product selection, variant, **camera + gallery** photo, live price preview. Validates 1–20 000 mm dimensions. | `ProductListViewController` (select product), pops on save |
| `FloorSpaceEditViewController` | Form to add/edit a floor space. Width × Depth (mm, integer), product selection, variant, **camera + gallery** photo, live price preview. Validates dimensions. | `ProductListViewController` (select product), pops on save |
| `ProductListViewController` | Loads products from KIT305 API filtered by category (window/floor). Supports search. | `ProductVariantViewController` (if product has variants), or fires `onProductSelected` callback and pops |
| `ProductVariantViewController` | Shows variants for a selected product. Fires `onVariantSelected` callback on selection. | Pops via callback |
| `QuoteViewController` | Polished per-room sectioned quote with include/exclude switches per room **and** per item. Shows a colored notes banner if the house has notes. Bottom card shows Subtotal / Discount / FINAL TOTAL (monospaced, large purple). Share button exports CSV. | UIActivityViewController (share sheet) |
| `PhotoPickerCoordinator` | Coordinator class (not a VC). Presents an action sheet with **Take Photo** (UIImagePickerController.camera, when available) and **Choose from Library** (PHPickerViewController on iOS 14+, UIImagePickerController fallback). Calls `PhotoPickerDelegate`. | — |

### Navigation Flow

```
UINavigationController
  └── HouseListViewController
        ├── HouseEditViewController       (add / edit)
        ├── RoomListViewController
        │     ├── RoomDetailViewController
        │     │     ├── WindowEditViewController
        │     │     │     └── ProductListViewController
        │     │     │           └── ProductVariantViewController
        │     │     └── FloorSpaceEditViewController
        │     │           └── ProductListViewController
        │     │                 └── ProductVariantViewController
        │     └── QuoteViewController
        └── QuoteViewController           (from house list)
```

---

## Firebase / Firestore Structure

Flat top-level collections (mirrors the Android assignment 2 schema so both
apps can share the same database):

```
houses/{houseId}
  customerName, address

rooms/{roomId}
  houseId, name, photoBase64, photoUrl

windows/{windowId}
  roomId, name, widthMm (Int), heightMm (Int),
  selectedProductId, selectedProductName, selectedProductVariant,
  panelCount (Int), photoBase64

floorspaces/{floorId}
  roomId, name, widthMm (Int), depthMm (Int),
  selectedProductId, selectedProductName, selectedProductVariant,
  photoBase64
```

---

## Custom Feature: Quote Discount Tool

The `QuoteViewController` includes a **discount field** where the salesperson can enter a percentage discount (0–100%). When applied, the total price is recalculated and displayed as:

> Total: $XX.XX  (Y% off)

The discount is also reflected in the exported CSV.

---

## Product API

- All products: `https://utasbot.dev/kit305_2026/product`
- Window products: `https://utasbot.dev/kit305_2026/product?category=window`
- Floor products: `https://utasbot.dev/kit305_2026/product?category=floor`

---

## References

| Resource | URL / Description |
|---|---|
| KIT305 Tutorial material | University of Tasmania KIT305 unit tutorials |
| Firebase iOS SDK (SwiftPM) | https://github.com/firebase/firebase-ios-sdk |
| Firebase Firestore iOS docs | https://firebase.google.com/docs/firestore/quickstart?platform=ios |
| Apple UIKit documentation | https://developer.apple.com/documentation/uikit |
| PHPickerViewController guide | https://developer.apple.com/documentation/photokit/phpickerviewcontroller |
| UIActivityViewController | https://developer.apple.com/documentation/uikit/uiactivityviewcontroller |
| KIT305 Product API | https://utasbot.dev/kit305_2026/product |

---

## Generative AI Acknowledgement

**GitHub Copilot** was used to assist with:
- Porting Kotlin Android code to Swift/UIKit
- Writing Firestore CRUD operations (listenToHouses, addRoom, updateWindow, etc.)
- Implementing PHPickerViewController + UIImagePickerController fallback with base64 encoding
- Implementing UIActivityViewController CSV sharing
- Discount percentage calculation in QuoteCalculator
- Storyboard XML structure for all scenes

Copilot was used as a code assistant; all generated code was reviewed and adapted for correctness.

---

## Submission Notes

- Platform: iOS 16+, tested on iPhone 15 Simulator (iOS 17)
- No SwiftUI, no Objective-C, no third-party libraries (Firebase only)
- Photos: Camera **and** Photo Library via `PhotoPickerCoordinator` (action sheet)
- App icon: programmatically generated purple house glyph (light / dark / tinted variants)
- Git commit history: 150+ small, meaningful commits tracking the Android schema port, UI polish, validation, haptic feedback, keyboard handling, empty states, animations, custom features, and code quality improvements
