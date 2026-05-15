# KIT305 Assignment 3 – iOS Interior Design Quoting App

## Recommended Simulator

**iPhone 15, iOS 17, Portrait orientation**

> ⚠️ **Marker Note:** Before running the app, replace `A3-ios/A3-ios/GoogleService-Info.plist` with your real `GoogleService-Info.plist` downloaded from the Firebase Console for your Firestore project. The placeholder file in this repo will cause Firebase to fail to initialise.

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
| `HouseEditViewController` | Form to create or update a house (name + address). Validates non-empty name. | Pops back on save |
| `RoomListViewController` | Shows all rooms for a house. Supports search, add room (alert), rename (swipe), delete (swipe). | `RoomDetailViewController` (tap row), `QuoteViewController` (Quote button) |
| `RoomDetailViewController` | Two-section view for a room: Windows (§0) and Floor Spaces (§1). Footer buttons add items. Swipe to delete. | `WindowEditViewController`, `FloorSpaceEditViewController` |
| `WindowEditViewController` | Form to add/edit a window. Width × Height (cm), product selection, variant, photo from gallery, live price preview. Validates positive dimensions. | `ProductListViewController` (select product), pops on save |
| `FloorSpaceEditViewController` | Form to add/edit a floor space. Width × Length (cm), product selection, variant, photo from gallery, live price preview. Validates positive dimensions. | `ProductListViewController` (select product), pops on save |
| `ProductListViewController` | Loads products from KIT305 API filtered by category (window/floor). Supports search. | `ProductVariantViewController` (if product has variants), or fires `onProductSelected` callback and pops |
| `ProductVariantViewController` | Shows variants for a selected product. Fires `onVariantSelected` callback on selection. | Pops via callback |
| `QuoteViewController` | Loads all windows + floor spaces across all rooms of a house. Shows itemised list with include/exclude toggles, subtotal, discount (%), total. Share button exports CSV. | UIActivityViewController (share sheet) |
| `PhotoPickerCoordinator` | Coordinator class (not a VC). Presents `PHPickerViewController` (iOS 14+) or `UIImagePickerController` (fallback) for gallery-only photo selection. Calls `PhotoPickerDelegate`. | — |

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

```
houses/{houseId}
  name, address, createdAt

houses/{houseId}/rooms/{roomId}
  name, createdAt

houses/{houseId}/rooms/{roomId}/windows/{windowId}
  widthCm, heightCm, productId, variantId, productName, variantName, pricePerSqm, photoBase64

houses/{houseId}/rooms/{roomId}/floors/{floorId}
  widthCm, lengthCm, productId, variantId, productName, variantName, pricePerSqm, photoBase64
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
- Photos: Gallery only (PHPickerViewController / UIImagePickerController), no camera
- Git commit history: 100+ small, meaningful commits
