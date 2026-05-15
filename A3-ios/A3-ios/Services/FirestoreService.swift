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

    private func roomData(from room: Room) -> [String: Any] {
        return [
            "name": room.name,
            "createdAt": Timestamp(date: room.createdAt)
        ]
    }
}
