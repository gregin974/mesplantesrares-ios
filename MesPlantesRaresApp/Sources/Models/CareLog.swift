import Foundation
import SwiftData

@Model
final class CareLog {
    @Attribute(.unique) var id: Int?
    var localId: String? // Pour la file d'attente offline
    var plantId: Int
    var actionType: String
    var actionDate: Date
    var notes: String?
    var synced: Bool

    init(id: Int? = nil, localId: String? = nil, plantId: Int, actionType: String, actionDate: Date, notes: String? = nil, synced: Bool = true) {
        self.id = id
        self.localId = localId
        self.plantId = plantId
        self.actionType = actionType
        self.actionDate = actionDate
        self.notes = notes
        self.synced = synced
    }
}

struct CareLogDTO: Codable {
    let id: Int?
    let plantId: Int
    let actionType: String?
    let actionDate: String?
    let notes: String?
    let createdAt: String?

    var toModel: CareLog {
        let date: Date = {
            if let d = actionDate ?? createdAt { return ISO8601DateFormatter().date(from: d) ?? Date() }
            return Date()
        }()
        return CareLog(id: id, plantId: plantId, actionType: actionType ?? "other", actionDate: date, notes: notes)
    }
}

struct CareLogRequest: Codable {
    let plantId: Int
    let actionType: String
    let actionDate: String
    let notes: String?

    init(plantId: Int, actionType: String, actionDate: Date, notes: String?) {
        self.plantId = plantId
        self.actionType = actionType
        self.actionDate = ISO8601DateFormatter().string(from: actionDate)
        self.notes = notes
    }
}
