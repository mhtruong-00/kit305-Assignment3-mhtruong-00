// With support from GitHub Copilot
import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Houses

    func listenToHouses(completion: @escaping ([House]) -> Void) -> ListenerRegistration {
        return db.collection("houses")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let houses = documents.compactMap { self?.houseFrom(doc: $0) }
                completion(houses)
            }
    }

    func addHouse(_ house: House, completion: @escaping (Error?) -> Void) {
        db.collection("houses").addDocument(data: houseData(from: house), completion: completion)
    }

    func updateHouse(_ house: House, completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(house.id).updateData(houseData(from: house), completion: completion)
    }

    func deleteHouse(_ houseId: String, completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId).delete(completion: completion)
    }

    private func houseFrom(doc: DocumentSnapshot) -> House? {
        guard let data = doc.data() else { return nil }
        return House(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            address: data["address"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    // MARK: - Rooms

    func listenToRooms(houseId: String, completion: @escaping ([Room]) -> Void) -> ListenerRegistration {
        return db.collection("houses").document(houseId).collection("rooms")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let rooms = documents.compactMap { self?.roomFrom(doc: $0, houseId: houseId) }
                completion(rooms)
            }
    }

    func addRoom(_ room: Room, houseId: String, completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId).collection("rooms")
            .addDocument(data: roomData(from: room), completion: completion)
    }

    func updateRoom(_ room: Room, houseId: String, completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId).collection("rooms")
            .document(room.id).updateData(roomData(from: room), completion: completion)
    }

    func deleteRoom(_ roomId: String, houseId: String, completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId).collection("rooms")
            .document(roomId).delete(completion: completion)
    }

    private func roomFrom(doc: DocumentSnapshot, houseId: String) -> Room? {
        guard let data = doc.data() else { return nil }
        return Room(
            id: doc.documentID,
            houseId: houseId,
            name: data["name"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    // MARK: - Windows

    func listenToWindows(houseId: String, roomId: String,
                         completion: @escaping ([WindowItem]) -> Void) -> ListenerRegistration {
        return db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("windows")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let items = documents.compactMap { self?.windowFrom(doc: $0, roomId: roomId) }
                completion(items)
            }
    }

    func addWindow(_ window: WindowItem, houseId: String, roomId: String,
                   completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("windows")
            .addDocument(data: windowData(from: window), completion: completion)
    }

    func updateWindow(_ window: WindowItem, houseId: String, roomId: String,
                      completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("windows").document(window.id)
            .updateData(windowData(from: window), completion: completion)
    }

    func deleteWindow(_ windowId: String, houseId: String, roomId: String,
                      completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("windows").document(windowId)
            .delete(completion: completion)
    }

    private func windowFrom(doc: DocumentSnapshot, roomId: String) -> WindowItem? {
        guard let data = doc.data() else { return nil }
        return WindowItem(
            id: doc.documentID,
            roomId: roomId,
            widthCm: data["widthCm"] as? Double ?? 0,
            heightCm: data["heightCm"] as? Double ?? 0,
            productId: data["productId"] as? String ?? "",
            variantId: data["variantId"] as? String ?? "",
            productName: data["productName"] as? String ?? "",
            variantName: data["variantName"] as? String ?? "",
            pricePerSqm: data["pricePerSqm"] as? Double ?? 0,
            photoBase64: data["photoBase64"] as? String
        )
    }

    private func windowData(from window: WindowItem) -> [String: Any] {
        var data: [String: Any] = [
            "widthCm": window.widthCm,
            "heightCm": window.heightCm,
            "productId": window.productId,
            "variantId": window.variantId,
            "productName": window.productName,
            "variantName": window.variantName,
            "pricePerSqm": window.pricePerSqm
        ]
    // MARK: - Floor Spaces

    func listenToFloorSpaces(houseId: String, roomId: String,
                              completion: @escaping ([FloorSpace]) -> Void) -> ListenerRegistration {
        return db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("floors")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let items = documents.compactMap { self?.floorFrom(doc: $0, roomId: roomId) }
                completion(items)
            }
    }

    func addFloorSpace(_ floor: FloorSpace, houseId: String, roomId: String,
                       completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("floors")
            .addDocument(data: floorData(from: floor), completion: completion)
    }

    func updateFloorSpace(_ floor: FloorSpace, houseId: String, roomId: String,
                          completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("floors").document(floor.id)
            .updateData(floorData(from: floor), completion: completion)
    }

    func deleteFloorSpace(_ floorId: String, houseId: String, roomId: String,
                          completion: @escaping (Error?) -> Void) {
        db.collection("houses").document(houseId)
            .collection("rooms").document(roomId)
            .collection("floors").document(floorId)
            .delete(completion: completion)
    }

    private func floorFrom(doc: DocumentSnapshot, roomId: String) -> FloorSpace? {
        guard let data = doc.data() else { return nil }
        return FloorSpace(
            id: doc.documentID,
            roomId: roomId,
            widthCm: data["widthCm"] as? Double ?? 0,
            lengthCm: data["lengthCm"] as? Double ?? 0,
            productId: data["productId"] as? String ?? "",
            variantId: data["variantId"] as? String ?? "",
            productName: data["productName"] as? String ?? "",
            variantName: data["variantName"] as? String ?? "",
            pricePerSqm: data["pricePerSqm"] as? Double ?? 0,
            photoBase64: data["photoBase64"] as? String
        )
    }

    private func floorData(from floor: FloorSpace) -> [String: Any] {
        var data: [String: Any] = [
            "widthCm": floor.widthCm,
            "lengthCm": floor.lengthCm,
            "productId": floor.productId,
            "variantId": floor.variantId,
            "productName": floor.productName,
            "variantName": floor.variantName,
            "pricePerSqm": floor.pricePerSqm
        ]
        if let photo = floor.photoBase64 {
            data["photoBase64"] = photo
        }
        return data
    }

    // MARK: - Quote Data Loader

    func loadQuoteData(houseId: String,
                       completion: @escaping ([Room], [String: [WindowItem]], [String: [FloorSpace]]) -> Void) {
        db.collection("houses").document(houseId).collection("rooms")
            .order(by: "createdAt", descending: false)
            .getDocuments { [weak self] snapshot, error in
                guard let roomDocs = snapshot?.documents, let self = self else {
                    completion([], [:], [:])
                    return
                }
                let rooms = roomDocs.compactMap { self.roomFrom(doc: $0, houseId: houseId) }
                var allWindows: [String: [WindowItem]] = [:]
                var allFloors: [String: [FloorSpace]] = [:]
                let group = DispatchGroup()

                for room in rooms {
                    group.enter()
                    self.db.collection("houses").document(houseId)
                        .collection("rooms").document(room.id)
                        .collection("windows").getDocuments { snap, _ in
                            allWindows[room.id] = snap?.documents.compactMap {
                                self.windowFrom(doc: $0, roomId: room.id)
                            } ?? []
                            group.leave()
                        }

                    group.enter()
                    self.db.collection("houses").document(houseId)
                        .collection("rooms").document(room.id)
                        .collection("floors").getDocuments { snap, _ in
                            allFloors[room.id] = snap?.documents.compactMap {
                                self.floorFrom(doc: $0, roomId: room.id)
                            } ?? []
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    completion(rooms, allWindows, allFloors)
                }
            }
    }
}
