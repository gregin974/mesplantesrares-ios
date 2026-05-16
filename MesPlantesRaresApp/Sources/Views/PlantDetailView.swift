import SwiftUI

struct PlantDetailView: View {
    @Environment(APIClient.self) private var api
    @Environment(AuthService.self) private var auth

    let plantId: Int
    let userId: Int?

    @State private var plant: PlantDTO?
    @State private var careLogs: [CareLogDTO] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else if let plant {
                VStack(spacing: 0) {
                    // Photo
                    if let photo = plant.toModel.photoURL {
                        AsyncImage(url: photo) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Color.green100
                                    .overlay(
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.green600)
                                    )
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plant.name ?? "Sans nom")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green800)

                        let speciesLine = [plant.scientificName, plant.species, plant.genus]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                            .joined(separator: " · ")
                        if !speciesLine.isEmpty {
                            Text(speciesLine)
                                .font(.subheadline)
                                .foregroundColor(.gray500)
                                .italic()
                        }

                        if let location = plant.location, !location.isEmpty {
                            Text("📍 \(location)")
                                .font(.subheadline)
                                .foregroundColor(.gray600)
                        }

                        // Details
                        VStack(spacing: 4) {
                            DetailRow(label: "Famille", value: plant.botanicalFamily ?? "-")
                            DetailRow(label: "Origine", value: plant.originCountry ?? "-")
                            if let owner = plant.owner {
                                DetailRow(label: "Propriétaire", value: owner)
                            }
                        }
                        .padding(.vertical, 8)

                        // Care logs timeline
                        if !careLogs.isEmpty {
                            Text("📋 Soins récents")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray500)
                                .textCase(.uppercase)
                                .padding(.top, 8)

                            ForEach(careLogs.prefix(10), id: \.id) { log in
                                CareLogRow(log: log)
                            }
                        }
                    }
                    .padding(16)
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.gray500)
                    .padding(.top, 100)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        let uid = userId ?? auth.currentUser?.id ?? 0
        do {
            let plantRes: PlantDTO = try await api.plant(userId: uid, plantId: plantId)
            plant = plantRes
            if uid > 0 {
                let logs: [CareLogDTO] = try await api.plantCareLogs(userId: uid, plantId: plantId)
                careLogs = logs
            }
        } catch {
            errorMessage = "Impossible de charger la plante"
        }
        isLoading = false
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray500)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray700)
        }
        .padding(.vertical, 2)
    }
}

struct CareLogRow: View {
    let log: CareLogDTO

    var actionType: CareActionType {
        CareActionType(rawValue: log.actionType ?? "other") ?? .other
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(actionType.emoji)
                .font(.system(size: 20))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(actionType.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray700)

                if let date = log.actionDate ?? log.createdAt {
                    Text(dateTimeAgo(date))
                        .font(.caption2)
                        .foregroundColor(.gray400)
                }

                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.gray500)
                }
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func dateTimeAgo(_ dateStr: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateStr) else { return dateStr }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
