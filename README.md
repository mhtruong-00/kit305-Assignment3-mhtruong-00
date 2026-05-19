# KIT305 Assignment 3 – iOS Interior Design Quoting App

## Recommended Simulator

**iPhone 17 / iPhone 15, latest iOS, Portrait orientation**

> ⚠️ **Marker Note:** Before running the app, replace `A3-ios/A3-ios/GoogleService-Info.plist` with your real `GoogleService-Info.plist` downloaded from the Firebase Console for your Firestore project. The placeholder file in this repo will cause Firebase to fail to initialise.

### Bundle Identifier (after cloning)

All targets ship with the bundle id prefix **`au.edu.utas.kit305.A3`**:

| Target | Bundle Identifier |
|---|---|
| App | `au.edu.utas.kit305.A3` |
| Unit tests | `au.edu.utas.kit305.A3.A3-iosTests` |
| UI tests | `au.edu.utas.kit305.A3.A3-iosUITests` |

This matches the included `GoogleService-Info.plist`. If Xcode rewrites the bundle id automatically when you open the project with your own Apple ID:

1. Select the project → **A3-ios** target → **Signing & Capabilities**.
2. Reset **Bundle Identifier** to `au.edu.utas.kit305.A3`.
3. Set **Team = None** (simulator does not need signing), **or** keep your team but uncheck *Automatically manage signing*.
4. Repeat for the two test targets if needed.

---

## App Overview

A native iOS application written in **Swift / UIKit / Storyboards** (no SwiftUI, no Objective-C, no third-party libs except Firebase via SwiftPM). It is a port of the KIT305 Assignment 2 Android app — an interior-design quoting tool for salespeople.

The app allows salespeople to:

- Manage **houses** (customer job sites) with customer name, address, and free-form notes.
- Manage **rooms** within each house, with cover photos and a swipe-to-duplicate shortcut.
- Record **windows** and **floor spaces** within each room, with per-item product / variant selection, photo attachment, and dimensions in **millimetres**.
- Generate a polished, itemised **quote** per house with per-room totals, labour, discount, and CSV share.

---

## What's New in This Iteration

| Area | Update |
|---|---|
| **Search bars** | Pinned at the top of *Houses*, *Rooms*, and *Products* — no longer hide on scroll (iOS 16+ `preferredSearchBarPlacement = .stacked`). |
| **Pull-to-refresh** | Added to *House list* and *Product list*. |
| **Nav prompts** | *House list* shows `Houses: N`, *Room list* shows `Rooms: N`. |
| **Photo thumbnails** | 48 px rounded thumbnails on *Window*, *Floor*, *Room*, and *House* cells (previously a tiny colour dot). |
| **House notes** (custom feature) | New free-form notes field on house edit; surfaced as a coloured banner on the quote screen, included in CSV export, and shown with a pencil indicator on house cells. |
| **Duplicate Room** (custom feature) | Leading swipe action on a room copies the room and all of its windows / floor spaces (including products and photos). |
| **Discount %** (custom feature) | Inline discount field on the quote; subtracted from the subtotal and reflected in the CSV. |
| **Quote redesign** | Per-room mini-cards with accent bar, item count, include/exclude switches per room **and** per item. Items priced via the fallback rate show a small **default rate** badge. Footer is a shadowed rounded card with **Subtotal / Discount / FINAL TOTAL** (large monospaced purple). |
| **Camera + Library** | `PhotoPickerCoordinator` action sheet offers *Take Photo* (UIImagePickerController.camera) and *Choose from Library* (PHPickerViewController on iOS 14+, UIImagePickerController fallback). `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` added to `Info.plist`. |
| **Image budget** | `ImageStore` compresses JPEGs to stay under ~250 KB so encoded base64 fits inside the Firestore document size cap. |
| **App icon** | Programmatically generated purple-house glyph with light / dark / tinted variants. |
| **Bundle id hygiene** | All targets aligned under `au.edu.utas.kit305.A3` prefix (was mixed `au.edu.utas.mhtruong`). |
| **Compatibility checker** | Fixed integer-division bug; panel-width math now uses `Double` (matches the Android implementation). |

---

## View Controllers and Interrelation

| View Controller | Purpose | Navigates To |
|---|---|---|
| `HouseListViewController` | Lists all houses with thumbnails + notes-indicator. Pinned search bar, pull-to-refresh, swipe-edit, swipe-delete (cascades to rooms / items). Initial VC. | `HouseEditViewController`, `RoomListViewController`, `QuoteViewController` |
| `HouseEditViewController` | Form: customer name, address (must contain a letter), **notes**. Validates non-empty name + address. | Pops on save |
| `RoomListViewController` | Lists rooms for a house. Pinned search, room count prompt, add-room popup, **leading-swipe Duplicate**, swipe-delete (cascades to windows + floor spaces). | `RoomDetailViewController`, `QuoteViewController` |
| `RoomDetailViewController` | Two sections per room: **Windows** (§0) and **Floor Spaces** (§1). Top header shows the room cover photo with **Take Photo / Choose from Library**. Footer buttons add items. | `WindowEditViewController`, `FloorSpaceEditViewController` |
| `WindowEditViewController` | Add/edit window: name, width × height in **mm** (1–20 000), product + variant, camera + library photo, live price preview. | `ProductListViewController`, pops on save |
| `FloorSpaceEditViewController` | Add/edit floor space: name, width × depth in **mm**, product + variant, camera + library photo, live price preview. | `ProductListViewController`, pops on save |
| `ProductListViewController` | Loads products from the KIT305 API filtered by category. Pinned search, pull-to-refresh. Window products show a compatibility status; tapping an incompatible product explains why. | `ProductVariantViewController` (if variants exist), or fires `onProductSelected` callback and pops |
| `ProductVariantViewController` | Lists variants for a selected product; fires `onVariantSelected` callback. | Pops via callback |
| `QuoteViewController` | Per-room sectioned quote with include/exclude switches per room *and* per item. Notes banner if the house has notes. Bottom card: Subtotal / Discount / **FINAL TOTAL**. Share button exports CSV. | `UIActivityViewController` (share sheet) |
| `PhotoPickerCoordinator` | Coordinator (not a VC). Action sheet → camera or library; returns the picked image via `PhotoPickerDelegate`. | — |

### Navigation Flow

```
UINavigationController
  └── HouseListViewController
        ├── HouseEditViewController             (add / edit)
        ├── RoomListViewController
        │     ├── RoomDetailViewController
        │     │     ├── WindowEditViewController
        │     │     │     └── ProductListViewController
        │     │     │           └── ProductVariantViewController
        │     │     └── FloorSpaceEditViewController
        │     │           └── ProductListViewController
        │     │                 └── ProductVariantViewController
        │     └── QuoteViewController
        └── QuoteViewController                 (from house list)
```

---

## Firebase / Firestore Structure

Flat top-level collections (mirrors the Android Assignment 2 schema so both apps can share the same database):

```
houses/{houseId}
  customerName: String
  address:      String
  notes:        String     // custom feature

rooms/{roomId}
  houseId:     String
  name:        String
  photoBase64: String?
  photoUrl:    String?

windows/{windowId}
  roomId:                  String
  name:                    String
  widthMm:                 Int
  heightMm:                Int
  selectedProductId:       String?
  selectedProductName:     String?
  selectedProductVariant:  String?
  panelCount:              Int
  photoBase64:             String?

floorspaces/{floorId}
  roomId:                  String
  name:                    String
  widthMm:                 Int
  depthMm:                 Int
  selectedProductId:       String?
  selectedProductName:     String?
  selectedProductVariant:  String?
  photoBase64:             String?
```

Cascading delete is implemented in `FirestoreService`: deleting a house removes all of its rooms; deleting a room removes all of its windows and floor spaces.

---

## Custom Features

1. **Quote Discount** — percentage discount field on the quote screen; recalculated live and included in the CSV export.
2. **House Notes** — free-form notes per house; surfaced as a coloured banner on the quote screen, included in the CSV export, and shown as a pencil indicator on house cells.
3. **Duplicate Room** — leading swipe on a room in the room list copies the room plus all of its windows and floor spaces (preserves products, variants, dimensions, and photos).

---

## Product API

| Endpoint | URL |
|---|---|
| All products | <https://utasbot.dev/kit305_2026/product> |
| Window products | <https://utasbot.dev/kit305_2026/product?category=window> |
| Floor products | <https://utasbot.dev/kit305_2026/product?category=floor> |

Compatibility constraints (min/max height, min/max width, panel splitting, panel count) are enforced in `CompatibilityChecker` and surfaced as a status pill in the product list and as an alert when tapping an incompatible product.

---

## References

| Resource | URL / Description |
|---|---|
| KIT305 Tutorial material | University of Tasmania KIT305 unit tutorials |
| Firebase iOS SDK (SwiftPM) | <https://github.com/firebase/firebase-ios-sdk> |
| Firebase Firestore iOS docs | <https://firebase.google.com/docs/firestore/quickstart?platform=ios> |
| Apple UIKit documentation | <https://developer.apple.com/documentation/uikit> |
| PHPickerViewController | <https://developer.apple.com/documentation/photokit/phpickerviewcontroller> |
| UIActivityViewController | <https://developer.apple.com/documentation/uikit/uiactivityviewcontroller> |
| KIT305 Product API | <https://utasbot.dev/kit305_2026/product> |

---

## Generative AI Acknowledgement

**GitHub Copilot** was used to assist with:

- Porting the Kotlin / Android codebase to Swift / UIKit (schema, services, view controllers).
- Writing Firestore CRUD operations (`listenToHouses`, `addRoom`, `updateWindow`, cascading delete, room duplication, etc.).
- Implementing `PhotoPickerCoordinator` (camera + PHPicker library) with base64 encoding and the 250 KB size budget in `ImageStore`.
- Implementing `UIActivityViewController` CSV sharing in `CSVExporter`.
- Discount percentage + per-room labour calculation in `QuoteCalculator`.
- Storyboard XML structure for all scenes.
- Quote-screen visual polish (mini-cards, accent bars, monospaced total card).
- Bulk git history rewrite to normalise author identity.

All generated code was reviewed, tested in the simulator, and adapted for correctness.

---

## Submission Notes

- **Platform:** iOS 16+, tested on iPhone 17 Pro Simulator (latest iOS).
- **Tech:** Swift, UIKit, Storyboards. No SwiftUI, no Objective-C, no third-party libraries (Firebase only, via SwiftPM).
- **Photos:** Camera **and** Photo Library via `PhotoPickerCoordinator` (action sheet). Simulator users will only see *Choose from Library* working — Camera triggers a graceful "unavailable" alert.
- **App icon:** Programmatically generated purple-house glyph with light / dark / tinted variants in `Assets.xcassets/AppIcon.appiconset`.
- **Git commit history:** 160+ small, meaningful commits covering the Android-schema port, UI polish, validation, haptic feedback, keyboard handling, empty states, animations, custom features, bundle-id hygiene, and code quality. All commits authored by the submitting student.
