import SwiftUI
import SwiftData

@main
struct MesPlantesRaresApp: App {
    @State private var api: APIClient
    @State private var auth: AuthService
    @State private var networkMonitor = NetworkMonitor()

    init() {
        let api = APIClient()
        self._api = State(initialValue: api)
        self._auth = State(initialValue: AuthService(api: api))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(api)
                .environment(auth)
                .environment(networkMonitor)
                .tint(.green800)
        }
        .modelContainer(for: [Plant.self, CareLog.self, User.self]) { result in
            if case .failure(let error) = result {
                print("SwiftData error: \(error)")
            }
        }
    }
}

struct ContentView: View {
    @Environment(APIClient.self) private var api
    @Environment(AuthService.self) private var auth
    @Environment(NetworkMonitor.self) private var networkMonitor

    @State private var selectedTab = 0
    @State private var authExpired = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(0)

                NavigationStack {
                    GalleryView()
                }
                .tabItem { Label("Galerie", systemImage: "photo.on.rectangle") }
                .tag(1)

                if auth.isAuthenticated {
                    NavigationStack {
                        CollectionView()
                    }
                    .tabItem { Label("Collection", systemImage: "leaf.fill") }
                    .tag(2)

                    NavigationStack {
                        CalendarView()
                    }
                    .tabItem { Label("Calendrier", systemImage: "calendar") }
                    .tag(3)

                    NavigationStack {
                        ProfileView()
                    }
                    .tabItem { Label("Profil", systemImage: "person.fill") }
                    .tag(4)
                } else {
                    NavigationStack {
                        PricingView()
                    }
                    .tabItem { Label("Tarifs", systemImage: "eurosign") }
                    .tag(2)

                    NavigationStack {
                        AboutView()
                    }
                    .tabItem { Label("À propos", systemImage: "person.2.fill") }
                    .tag(3)

                    NavigationStack {
                        LoginView()
                    }
                    .tabItem { Label("Connexion", systemImage: "key.fill") }
                    .tag(4)
                }
            }
            .onChange(of: auth.isAuthenticated) { _, _ in
                selectedTab = 0
            }
            .onReceive(NotificationCenter.default.publisher(for: .authExpired)) { _ in
                authExpired = true
            }
            .alert("Session expirée", isPresented: $authExpired) {
                Button("OK") { selectedTab = 4 }
            } message: {
                Text("Veuillez vous reconnecter.")
            }

            // Offline banner
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

// MARK: - Network Monitor

@Observable
final class NetworkMonitor {
    var isConnected = true

    init() {
        // Simplified — in production, use NWPathMonitor
        // For now, assume connected until a request fails
        NotificationCenter.default.addObserver(
            forName: .offlineStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isConnected = false
        }
    }
}
