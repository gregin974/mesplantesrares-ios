import SwiftUI

struct GalleryView: View {
    @Environment(APIClient.self) private var api

    @State private var genera: [String] = []
    @State private var plants: [PlantDTO] = []
    @State private var selectedGenus: String?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Genus chips
                if !genera.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Chip(text: "Tous", isSelected: selectedGenus == nil) {
                                selectedGenus = nil
                                Task { await loadPlants() }
                            }
                            ForEach(genera, id: \.self) { genus in
                                Chip(text: genus, isSelected: selectedGenus == genus) {
                                    selectedGenus = genus
                                    Task { await loadPlants() }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if isLoading {
                    ProgressView()
                        .padding()
                } else if plants.isEmpty {
                    VStack(spacing: 8) {
                        Text("🌿")
                            .font(.system(size: 48))
                        Text("Aucune plante trouvée")
                            .font(.subheadline)
                            .foregroundColor(.gray500)
                    }
                    .padding(.vertical, 32)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(plants, id: \.id) { plant in
                            NavigationLink(destination: PlantDetailView(plantId: plant.id, userId: nil)) {
                                GalleryItemView(plant: plant.toModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Galerie")
        .task {
            await loadInitial()
        }
    }

    private func loadInitial() async {
        isLoading = true
        do {
            genera = try await api.publicGenera()
            await loadPlants()
        } catch {
            genera = []
        }
        isLoading = false
    }

    private func loadPlants() async {
        isLoading = true
        do {
            // For now load public plants; genus filtering would need a specific endpoint
            plants = try await api.publicPlants(limit: 50)
        } catch {
            plants = []
        }
        isLoading = false
    }
}

struct Chip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green600 : Color.white)
                .foregroundColor(isSelected ? .white : .gray600)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.green600 : Color.gray300, lineWidth: 1)
                )
        }
    }
}

struct GalleryItemView: View {
    let plant: Plant

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: plant.photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Color.green100
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green600)
                        )
                @unknown default:
                    Color.green100
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(plant.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
