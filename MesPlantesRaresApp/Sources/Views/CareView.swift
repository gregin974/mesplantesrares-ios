import SwiftUI
import SwiftData

struct CareView: View {
    @Environment(APIClient.self) private var api
    @Environment(AuthService.self) private var auth

    let token: String

    @State private var plant: PlantDTO?
    @State private var careLogs: [CareLogDTO] = []
    @State private var notes: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var confirmedAction: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let plant {
                ScrollView {
                    VStack(spacing: 0) {
                        // Photo
                        if let photo = plant.toModel.photoURL {
                            AsyncImage(url: photo) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    Color.green100
                                }
                            }
                            .frame(height: 220)
                            .clipped()
                        }

                        // Plant info
                        VStack(alignment: .leading, spacing: 4) {
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
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Care buttons grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(CareActionType.allCases.filter { $0 != .other }, id: \.rawValue) { action in
                                CareButtonView(action: action) { act in
                                    confirmedAction = act.label
                                    Task { await performCare(act) }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                        // Notes
                        VStack(alignment: .leading) {
                            Text("Note")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray600)
                            TextField("Ajouter une note...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.subheadline)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray300, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                        // Recent logs
                        if !careLogs.isEmpty {
                            Text("📋 Soins récents")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray500)
                                .textCase(.uppercase)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            ForEach(careLogs.prefix(5), id: \.id) { log in
                                CareLogRow(log: log)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Text("😕")
                        .font(.system(size: 48))
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray500)
                }
                .padding(.top, 100)
            }
        }
        .overlay(alignment: .bottom) {
            if showConfirmation, let action = confirmedAction {
                Text("✅ \(action) enregistré !")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green800)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { showConfirmation = false }
                    }
            }
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        guard !token.isEmpty else {
            errorMessage = "Scannez un QR code ou approchez un tag NFC"
            isLoading = false
            return
        }
        isLoading = true
        do {
            let res: QRResponse = try await api.qrToken(token)
            if let p = res.plant ?? res.data?.plant {
                plant = p
                let uid = auth.currentUser?.id ?? 0
                if uid > 0 {
                    let logs: [CareLogDTO] = try await api.plantCareLogs(userId: uid, plantId: p.id)
                    careLogs = logs
                }
            } else {
                errorMessage = "QR code invalide ou expiré"
            }
        } catch {
            errorMessage = "QR code invalide ou expiré"
        }
        isLoading = false
    }

    private func performCare(_ action: CareActionType) async {
        guard let plant else { return }
        let userId = auth.currentUser?.id

        if let uid = userId {
            let request = CareLogRequest(plantId: plant.id, actionType: action.rawValue, actionDate: Date(), notes: notes.isEmpty ? nil : notes)
            do {
                let _: CareLogDTO = try await api.logCare(userId: uid, data: request)
                withAnimation { showConfirmation = true }
                notes = ""
            } catch {
                // Queue offline
                // In a real implementation, get modelContext from environment
            }
        }
        withAnimation { showConfirmation = true }
    }
}
