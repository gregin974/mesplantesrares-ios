import SwiftUI

struct HomeView: View {
    @Environment(APIClient.self) private var api

    @State private var stats: PublicStats?
    @State private var plants: [PlantDTO] = []
    @State private var configName: String = Config.appName
    @State private var slogan: String = "Votre collection de plantes rares"
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Hero
                VStack(spacing: 8) {
                    Text(configName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green800)
                    Text(slogan)
                        .font(.subheadline)
                        .foregroundColor(.gray600)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        NavigationLink("Commencer", destination: LoginView())
                            .buttonStyle(.borderedProminent)
                            .tint(.green600)
                    }
                    .padding(.top, 8)

                    Text("Gratuit pour 10 plantes · Sans engagement")
                        .font(.caption)
                        .foregroundColor(.gray500)
                        .padding(.top, 4)
                }
                .padding(.vertical, 24)

                // Stats
                if let s = stats {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        StatCard(number: s.totalUsers?.formatted() ?? "...", label: "Collectionneurs")
                        StatCard(number: s.totalPlants?.formatted() ?? "...", label: "Plantes suivies")
                        StatCard(number: s.totalEvents?.formatted() ?? "...", label: "Soins enregistrés")
                        StatCard(number: s.uniqueSpecies?.formatted() ?? "...", label: "Espèces")
                    }
                    .padding(.horizontal, 16)
                }

                // Public plants
                SectionHeader(title: "🌿 Plantes de la communauté")

                if isLoading {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray500)
                        .padding()
                } else if plants.isEmpty {
                    VStack(spacing: 8) {
                        Text("🌱")
                            .font(.system(size: 48))
                        Text("Soyez le premier à partager vos plantes")
                            .font(.subheadline)
                            .foregroundColor(.gray500)
                    }
                    .padding(.vertical, 24)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(plants, id: \.id) { plant in
                            NavigationLink(destination: PlantDetailView(plantId: plant.id, userId: nil)) {
                                PlantCardView(plant: plant.toModel, showStatusBadge: false)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // Features
                SectionHeader(title: "✨ Fonctionnalités")
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(emoji: "📋", text: "Suivi personnalisé — fiches détaillées pour chaque plante")
                    FeatureRow(emoji: "📅", text: "Calendrier intelligent — rappels arrosage, rempotage")
                    FeatureRow(emoji: "📊", text: "Statistiques — graphiques et analyses de votre collection")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            async let config: [String: String] = api.publicConfig()
            async let statsRes: PublicStats = api.publicStats()
            async let plantsRes: [PlantDTO] = api.publicPlants(limit: 12)

            let (cfg, st, pl) = try await (config, statsRes, plantsRes)
            configName = cfg["app_name"] as? String ?? Config.appName
            slogan = cfg["app_slogan"] as? String ?? slogan
            stats = st
            plants = pl
        } catch {
            errorMessage = "Chargement impossible"
        }
        isLoading = false
    }
}

struct StatCard: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green600)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray500)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct FeatureRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray600)
        }
    }
}
