import Foundation
import SwiftData

@Observable
final class OfflineQueue {
    private let modelContext: ModelContext
    private let api: APIClient
    private(set) var pendingCount = 0

    init(modelContext: ModelContext, api: APIClient) {
        self.modelContext = modelContext
        self.api = api
        updateCount()
    }

    func enqueue(plantId: Int, actionType: String, notes: String?) {
        let localId = "local_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6))"
        let log = CareLog(localId: localId, plantId: plantId, actionType: actionType, actionDate: Date(), notes: notes, synced: false)
        modelContext.insert(log)
        try? modelContext.save()
        updateCount()
    }

    func syncPending(userId: Int) async {
        let descriptor = FetchDescriptor<CareLog>(predicate: #Predicate { !$0.synced })
        guard let pending = try? modelContext.fetch(descriptor), !pending.isEmpty else { return }

        for log in pending {
            let request = CareLogRequest(plantId: log.plantId, actionType: log.actionType, actionDate: log.actionDate, notes: log.notes)
            do {
                let _: CareLogDTO = try await api.logCare(userId: userId, data: request)
                modelContext.delete(log)
                try? modelContext.save()
            } catch {
                break // Stop syncing on failure, retry later
            }
        }
        updateCount()
    }

    private func updateCount() {
        let descriptor = FetchDescriptor<CareLog>(predicate: #Predicate { !$0.synced })
        pendingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
