// With support from GitHub Copilot
// Top-level Firestore collections (houses, rooms, windows, floorspaces) to
// match the Android app's schema so both clients share the same database.
import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    let db = Firestore.firestore()
    private init() {}

    // MARK: - Houses

    func listenToHouses(completion: @escaping ([House]) -> Void) -> ListenerRegistration {
        return db.collection("houses")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else {
                    completion([]); return
                }
                completion(docs.map { self.houseFrom(doc: $0) })
            }
    }

    func addHouse(_ house: House, completion: @escaping (Error?) -> Void) {
        db.collection("houses").addDocument(data: houseData(from: house), completion: completion)
    }

    func updateHouse(_ house: House, completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(house.id)
            .updateData(houseData(from: house), completion: completion)
    }

    /// Deletes the house and all of its rooms (and their items) — matches
    /// the Android cascade behaviour, just with serial sub-queries.
    func deleteHouse(_ houseId: String, completion: @escaping (Error?) -> Void) {
        let roomsQuery = db.collection("rooms").whereField("houseId", isEqualTo: houseId)
        roomsQuery.getDocuments { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err { completion(err); return }
            let batch = self.db.batch()
            let roomIds = snap?.documents.map { $0.documentID } ?? []
            for roomId in roomIds {
                batch.deleteDocument(self.db.collection("rooms").document(roomId))
            }
            batch.deleteDocument(self.db.collection("houses").document(houseId))
            batch.commit { batchErr in
                if let batchErr = batchErr { completion(batchErr); return }
                // Best-effort cleanup of nested windows/floorspaces.
                let group = DispatchGroup()
                for rid in roomIds {
                    for coll in ["windows", "floorspaces"] {
                        group.enter()
                        self.db.collection(coll).whereField("roomId", isEqualTo: rid)
                            .getDocuments { itemsSnap, _ in
                                let inner = self.db.batch()
                                itemsSnap?.documents.forEach { inner.deleteDocument($0.reference) }
                                inner.commit { _ in group.leave() }
                            }
                    }
                }
                group.notify(queue: .main) { completion(nil) }
            }
        }
    }

    private func houseFrom(doc: QueryDocumentSnapshot) -> House {
        let data = doc.data()
        return House(
            id: doc.documentID,
            name: data["customerName"] as? String ?? "",
            address: data["address"] as? String ?? "",
            notes: data["notes"] as? String ?? ""
        )
    }

    private func houseData(from house: House) -> [String: Any] {
        return [
            "customerName": house.name,
            "address": house.address,
            "notes": house.notes
        ]
    }

    // MARK: - Rooms

    func listenToRooms(houseId: String, completion: @escaping ([Room]) -> Void) -> ListenerRegistration {
        return db.collection("rooms")
            .whereField("houseId", isEqualTo: houseId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else {
                    completion([]); return
                }
                completion(docs.map { self.roomFrom(doc: $0) })
            }
    }

    func addRoom(_ room: Room, completion: @escaping (Error?) -> Void) {
        db.collection("rooms").addDocument(data: roomData(from: room), completion: completion)
    }

    func updateRoom(_ room: Room, completion: @escaping (Error?) -> Void) {
        db.collection("rooms").document(room.id)
            .updateData(roomData(from: room), completion: completion)
    }

    func updateRoomFields(_ roomId: String, fields: [String: Any],
                          completion: @escaping (Error?) -> Void) {
        db.collection("rooms").document(roomId).updateData(fields, completion: completion)
    }

    func deleteRoom(_ roomId: String, completion: @escaping (Error?) -> Void) {
        // Cascade-delete the room's windows/floorspaces too.
        let group = DispatchGroup()
        for coll in ["windows", "floorspaces"] {
            group.enter()
            db.collection(coll).whereField("roomId", isEqualTo: roomId)
                .getDocuments { [weak self] snap, _ in
                    guard let self = self else { group.leave(); return }
                    let batch = self.db.batch()
                    snap?.documents.forEach { batch.deleteDocument($0.reference) }
                    batch.commit { _ in group.leave() }
                }
        }
        group.notify(queue: .main) { [weak self] in
            self?.db.collection("rooms").document(roomId).delete(completion: completion)
        }
    }

    /// Duplicate a room (and all of its windows + floor spaces) into a new
    /// "<name> (Copy)" room. Used by the room-list swipe action — saves users
    /// having to retype every measurement when a layout repeats (e.g. multiple
    /// identical bedrooms).
    func duplicateRoom(_ room: Room, completion: @escaping (Error?) -> Void) {
        var copy = room
        copy.id = ""
        copy.name = "\(room.name) (Copy)"
        let newRef = db.collection("rooms").document()
        newRef.setData(roomData(from: copy)) { [weak self] err in
            guard let self = self else { return }
            if let err = err { completion(err); return }
            let newRoomId = newRef.documentID
            let group = DispatchGroup()
            var firstError: Error?

            group.enter()
            self.db.collection("windows").whereField("roomId", isEqualTo: room.id)
                .getDocuments { snap, e in
                    if let e = e { firstError = e }
                    let batch = self.db.batch()
                    for doc in snap?.documents ?? [] {
                        var data = doc.data()
                        data["roomId"] = newRoomId
                        let ref = self.db.collection("windows").document()
                        batch.setData(data, forDocument: ref)
                    }
                    batch.commit { be in
                        if let be = be { firstError = be }
                        group.leave()
                    }
                }
            group.enter()
            self.db.collection("floorspaces").whereField("roomId", isEqualTo: room.id)
                .getDocuments { snap, e in
                    if let e = e { firstError = e }
                    let batch = self.db.batch()
                    for doc in snap?.documents ?? [] {
                        var data = doc.data()
                        data["roomId"] = newRoomId
                        let ref = self.db.collection("floorspaces").document()
                        batch.setData(data, forDocument: ref)
                    }
                    batch.commit { be in
                        if let be = be { firstError = be }
                        group.leave()
                    }
                }
            group.notify(queue: .main) { completion(firstError) }
        }
    }

    private func roomFrom(doc: QueryDocumentSnapshot) -> Room {
        let data = doc.data()
        return Room(
            id: doc.documentID,
            houseId: data["houseId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            photoBase64: (data["photoBase64"] as? String)?.nilIfEmpty,
            photoUrl: (data["photoUrl"] as? String)?.nilIfEmpty
        )
    }

    private func roomData(from room: Room) -> [String: Any] {
        return [
            "houseId": room.houseId,
            "name": room.name,
            "photoBase64": room.photoBase64 ?? "",
            "photoUrl": room.photoUrl ?? ""
        ]
    }

    // MARK: - Windows

    func listenToWindows(roomId: String,
                         completion: @escaping ([WindowItem]) -> Void) -> ListenerRegistration {
        return db.collection("windows")
            .whereField("roomId", isEqualTo: roomId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else {
                    completion([]); return
                }
                completion(docs.map { self.windowFrom(doc: $0) })
            }
    }

    func addWindow(_ window: WindowItem, completion: @escaping (Error?) -> Void) {
        db.collection("windows").addDocument(data: windowData(from: window), completion: completion)
    }

    func updateWindow(_ window: WindowItem, completion: @escaping (Error?) -> Void) {
        db.collection("windows").document(window.id)
            .updateData(windowData(from: window), completion: completion)
    }

    func deleteWindow(_ windowId: String, completion: @escaping (Error?) -> Void) {
        db.collection("windows").document(windowId).delete(completion: completion)
    }

    private func windowFrom(doc: QueryDocumentSnapshot) -> WindowItem {
        let data = doc.data()
        return WindowItem(
            id: doc.documentID,
            roomId: data["roomId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            widthMm: Self.intValue(data["widthMm"]),
            heightMm: Self.intValue(data["heightMm"]),
            selectedProductId: data["selectedProductId"] as? String ?? "",
            selectedProductName: data["selectedProductName"] as? String ?? "",
            selectedProductVariant: data["selectedProductVariant"] as? String ?? "",
            panelCount: Self.intValue(data["panelCount"], default: 1),
            photoBase64: (data["photoBase64"] as? String)?.nilIfEmpty
        )
    }

    private func windowData(from w: WindowItem) -> [String: Any] {
        return [
            "roomId": w.roomId,
            "name": w.name,
            "widthMm": w.widthMm,
            "heightMm": w.heightMm,
            "selectedProductId": w.selectedProductId,
            "selectedProductName": w.selectedProductName,
            "selectedProductVariant": w.selectedProductVariant,
            "panelCount": w.panelCount,
            "photoBase64": w.photoBase64 ?? ""
        ]
    }

    // MARK: - Floor Spaces

    func listenToFloorSpaces(roomId: String,
                             completion: @escaping ([FloorSpace]) -> Void) -> ListenerRegistration {
        return db.collection("floorspaces")
            .whereField("roomId", isEqualTo: roomId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let docs = snapshot?.documents else {
                    completion([]); return
                }
                completion(docs.map { self.floorFrom(doc: $0) })
            }
    }

    func addFloorSpace(_ floor: FloorSpace, completion: @escaping (Error?) -> Void) {
        db.collection("floorspaces").addDocument(data: floorData(from: floor), completion: completion)
    }

    func updateFloorSpace(_ floor: FloorSpace, completion: @escaping (Error?) -> Void) {
        db.collection("floorspaces").document(floor.id)
            .updateData(floorData(from: floor), completion: completion)
    }

    func deleteFloorSpace(_ floorId: String, completion: @escaping (Error?) -> Void) {
        db.collection("floorspaces").document(floorId).delete(completion: completion)
    }

    private func floorFrom(doc: QueryDocumentSnapshot) -> FloorSpace {
        let data = doc.data()
        return FloorSpace(
            id: doc.documentID,
            roomId: data["roomId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            widthMm: Self.intValue(data["widthMm"]),
            depthMm: Self.intValue(data["depthMm"]),
            selectedProductId: data["selectedProductId"] as? String ?? "",
            selectedProductName: data["selectedProductName"] as? String ?? "",
            selectedProductVariant: data["selectedProductVariant"] as? String ?? "",
            photoBase64: (data["photoBase64"] as? String)?.nilIfEmpty
        )
    }

    private func floorData(from f: FloorSpace) -> [String: Any] {
        return [
            "roomId": f.roomId,
            "name": f.name,
            "widthMm": f.widthMm,
            "depthMm": f.depthMm,
            "selectedProductId": f.selectedProductId,
            "selectedProductName": f.selectedProductName,
            "selectedProductVariant": f.selectedProductVariant,
            "photoBase64": f.photoBase64 ?? ""
        ]
    }

    // MARK: - Quote loader

    /// Loads the rooms, windows and floor spaces for a house in a single
    /// composite operation, used by the Quote screen.
    func loadQuoteData(houseId: String,
                       completion: @escaping ([Room], [String: [WindowItem]], [String: [FloorSpace]]) -> Void) {
        db.collection("rooms").whereField("houseId", isEqualTo: houseId)
            .getDocuments { [weak self] roomSnap, _ in
                guard let self = self else { completion([], [:], [:]); return }
                let rooms = (roomSnap?.documents ?? []).map { self.roomFrom(doc: $0) }
                    .sorted { $0.name.lowercased() < $1.name.lowercased() }
                if rooms.isEmpty { completion([], [:], [:]); return }

                var windowsByRoom: [String: [WindowItem]] = [:]
                var floorsByRoom: [String: [FloorSpace]] = [:]
                let group = DispatchGroup()
                for r in rooms {
                    group.enter()
                    self.db.collection("windows").whereField("roomId", isEqualTo: r.id)
                        .getDocuments { snap, _ in
                            windowsByRoom[r.id] = (snap?.documents ?? []).map { self.windowFrom(doc: $0) }
                            group.leave()
                        }
                    group.enter()
                    self.db.collection("floorspaces").whereField("roomId", isEqualTo: r.id)
                        .getDocuments { snap, _ in
                            floorsByRoom[r.id] = (snap?.documents ?? []).map { self.floorFrom(doc: $0) }
                            group.leave()
                        }
                }
                group.notify(queue: .main) {
                    completion(rooms, windowsByRoom, floorsByRoom)
                }
            }
    }

    // MARK: - Helpers

    private static func intValue(_ any: Any?, default def: Int = 0) -> Int {
        if let i = any as? Int { return i }
        if let l = any as? Int64 { return Int(l) }
        if let d = any as? Double { return Int(d) }
        if let n = any as? NSNumber { return n.intValue }
        if let s = any as? String, let i = Int(s) { return i }
        return def
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
