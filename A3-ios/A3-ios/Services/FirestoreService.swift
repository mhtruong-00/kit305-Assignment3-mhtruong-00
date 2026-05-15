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

    private func houseData(from house: House) -> [String: Any] {
        return [
            "name": house.name,
            "address": house.address,
            "createdAt": Timestamp(date: house.createdAt)
        ]
    }
}
