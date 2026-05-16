import SwiftUI

struct CollectionView: View {
    @Environment(APIClient.self) private var api
    @Environment(AuthService.self) private var auth

    @State private var plants: [PlantDTO] = []
    @State private var statusData: [PlantStatusDTO] = []
    @State private var searchQuery = ""
    @State private var selectedGenus: String?
    @State private var isLoading = true
    @State private var viewMode: ViewMode = .cards

    enum ViewMode: String, CaseIterable {
        case cards, list
    }

    var filteredPlants: [PlantDTO] {
        plants.filter { plant in
            if let genus = selectedGenus, plant.genus != genus { return false }
            if !searchQuery.isEmpty {
                let q = searchQuery.lowercased()
                let name = (plant.name ?? "").lowercased()
                let species = (plant.species ?? "").lowercased()
                let genus = (plant.genus ?? "").lowercased()
                guard name.contains(q) || species.contains(q) || genus.contains(q) else { return false }
            }
            return true
        }
    }

    var uniqueGenera: [String] {
        Array(Set(plants.compactMap(\.genus))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray400)
                TextField("Rechercher une plante...", text: $searchQuery)
                    .font(.subheadline)
            }
            .padding(10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Genus filters
            if !uniqueGenera.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Chip(text: "Tous", isSelected: selectedGenus == nil) {
                            selectedGenus = nil
                        }
                        ForEach(uniqueGenera, id: \.self) { genus in
                            Chip(text: genus, isSelected: selectedGenus == genus) {
                                selectedGenus = genus
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }

            // View mode toggle
            HStack(spacing: 8) {
                Button { viewMode = .cards } label: {
                    Label("Cartes", systemImage: "square.grid.2x2")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewMode == .cards ? Color.green600 : Color.white)
                        .foregroundColor(viewMode == .cards ? .white : .green600)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green600, lineWidth: viewMode == .cards ? 0 : 2)
                        )
                }
                Button { viewMode = .list } label: {
                    Label("Liste", systemImage: "list.bullet")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewMode == .list ? Color.green600 : Color.white)
                        .foregroundColor(viewMode == .list ? .white : .green600)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green600, lineWidth: viewMode == .list ? 0 : 2)
                        )
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Plant list
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredPlants.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text("🔍")
                        .font(.system(size: 48))
                    Text("Aucune plante trouvée")
                        .font(.subheadline)
                        .foregroundColor(.gray500)
                }
                Spacer()
            } else {
                ScrollView {
                    if viewMode == .cards {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredPlants, id: \.id) { plant in
                                NavigationLink(destination: PlantDetailView(plantId: plant.id, userId: auth.currentUser?.id)) {
                                    CollectionPlantCard(plant: plant.toModel, status: statusForPlant(plant.id))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 16)
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(filteredPlants, id: \.id) { plant in
                                NavigationLink(destination: PlantDetailView(plantId: plant.id, userId: auth.currentUser?.id)) {
                                    ListPlantRow(plant: plant.toModel, status: statusForPlant(plant.id))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .navigationTitle("Ma Collection")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Ma Collection")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green800)
                    Text("\(plants.count) plantes")
                        .font(.caption)
                        .foregroundColor(.gray400)
                }
            }
        }
        .task {
            await loadPlants()
        }
    }

    private func statusForPlant(_ plantId: Int) -> PlantStatusDTO? {
        statusData.first { $0.plantId == plantId }
    }

    private func loadPlants() async {
        guard let user = auth.currentUser else { return }
        isLoading = true
        do {
            async let p = api.plants(userId: user.id)
            async let s = api.plantStatus(userId: user.id)
            (plants, statusData) = try await (p, s)
        } catch {
            plants = []
        }
        isLoading = false
    }
}

struct CollectionPlantCard: View {
    let plant: Plant
    let status: PlantStatusDTO?

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: plant.photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green600)
                }
            }
            .frame(width: 64, height: 64)
            .background(Color.green100)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray700)
                Text(plant.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray400)
                    .lineLimit(1)
                if let loc = plant.location, !loc.isEmpty {
                    Text("📍 \(loc)")
                        .font(.caption2)
                        .foregroundColor(.gray500)
                }
                if let status {
                    StatusBadge(status: status)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct ListPlantRow: View {
    let plant: Plant
    let status: PlantStatusDTO?

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: plant.photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green600)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color.green100)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(plant.species ?? "")
                    .font(.caption)
                    .foregroundColor(.gray400)
            }

            Spacer()

            if let status {
                StatusBadge(status: status)
            }
        }
        .padding(.vertical, 6)
    }
}

struct StatusBadge: View {
    let status: PlantStatusDTO

    var body: some View {
        if status.status == "urgent" {
            Text("⚠️ Urgent")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.red100)
                .foregroundColor(.red700)
                .clipShape(Capsule())
        } else if status.status == "warning" {
            Text("💧 À arroser")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.yellow100)
                .foregroundColor(.yellow700)
                .clipShape(Capsule())
        } else if status.lastCare != nil {
            Text("✓ OK")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.green100)
                .foregroundColor(.green700)
                .clipShape(Capsule())
        }
    }
}
