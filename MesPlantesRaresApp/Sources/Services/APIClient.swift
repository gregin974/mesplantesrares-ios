import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int)
    case decodingError
    case networkError(Error)
    case offline

    var errorDescription: String? {
        switch self {
        case .unauthorized: "Session expirée"
        case .offline: "Mode hors-ligne"
        case .serverError(let code): "Erreur serveur \(code)"
        case .networkError(let e): e.localizedDescription
        case .decodingError: "Erreur de lecture des données"
        case .invalidURL: "URL invalide"
        }
    }
}

@Observable
final class APIClient {
    private let baseURL: String
    private let session: URLSession
    private var token: String?
    private var userId: Int?

    init(baseURL: String = Config.apiBase) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        loadToken()
    }

    // MARK: - Token management

    func setToken(_ token: String?, userId: Int?) {
        self.token = token
        self.userId = userId
        if let t = token {
            KeychainHelper.save(key: "jwt_token", data: Data(t.utf8))
        } else {
            KeychainHelper.delete(key: "jwt_token")
        }
        if let uid = userId {
            KeychainHelper.save(key: "user_id", data: Data(String(uid).utf8))
        } else {
            KeychainHelper.delete(key: "user_id")
        }
    }

    private func loadToken() {
        if let data = KeychainHelper.load(key: "jwt_token") {
            self.token = String(data: data, encoding: .utf8)
        }
        if let data = KeychainHelper.load(key: "user_id"),
           let uid = Int(String(data: data, encoding: .utf8) ?? "") {
            self.userId = uid
        }
    }

    var isLoggedIn: Bool { token != nil }

    // MARK: - HTTP methods

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request("GET", path)
    }

    func post<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("POST", path, body: body)
    }

    func put<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("PUT", path, body: body)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        try await request("DELETE", path)
    }

    // MARK: - Core request

    private func request<T: Decodable>(_ method: String, _ path: String, body: Encodable? = nil) async throws -> T {
        guard let components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        // Ensure proper URL encoding for query params already in path
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let userId {
            request.setValue(String(userId), forHTTPHeaderField: "x-user-id")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError(0)
            }

            if httpResponse.statusCode == 401 {
                setToken(nil, userId: nil)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .authExpired, object: nil)
                }
                throw APIError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - API Endpoints (identiques à la PWA)

    // Public
    func publicConfig() async throws -> [String: String] { try await get("/public/config") }
    func publicStats() async throws -> PublicStats { try await get("/public/stats") }
    func publicGenera() async throws -> [String] { try await get("/public/genera") }
    func publicPlants(limit: Int = 20) async throws -> [PlantDTO] { try await get("/user/public-plants?limit=\(limit)") }

    // Auth
    func login(username: String, password: String) async throws -> AuthResponse { try await post("/auth/login", body: ["username": username, "password": password]) }
    func register(username: String, email: String, password: String) async throws -> AuthResponse { try await post("/auth/register", body: ["username": username, "email": email, "password": password]) }

    // Plants
    func plants(userId: Int) async throws -> [PlantDTO] { try await get("/users/\(userId)/plants") }
    func plant(userId: Int, plantId: Int) async throws -> PlantDTO { try await get("/users/\(userId)/plants/\(plantId)") }
    func plantCareLogs(userId: Int, plantId: Int) async throws -> [CareLogDTO] { try await get("/users/\(userId)/plants/\(plantId)/carelog") }
    func logCare(userId: Int, data: CareLogRequest) async throws -> CareLogDTO { try await post("/users/\(userId)/plants/\(data.plantId)/carelog", body: data) }
    func plantNotes(userId: Int, plantId: Int) async throws -> [NoteDTO] { try await get("/users/\(userId)/plants/\(plantId)/notes") }
    func addNote(userId: Int, plantId: Int, content: String) async throws -> NoteDTO { try await post("/users/\(userId)/plants/\(plantId)/note", body: ["content": content]) }

    // Status
    func plantStatus(userId: Int) async throws -> [PlantStatusDTO] { try await get("/plants-status/\(userId)") }

    // QR
    func qrToken(_ token: String) async throws -> QRResponse { try await get("/qr-codes/token/\(token)") }

    // Profile
    func userProfile() async throws -> UserDTO { try await get("/user/profile") }
    func updateProfile(data: [String: String]) async throws -> UserDTO { try await put("/user/profile", body: data) }

    // Care logs global
    func careLogs(userId: Int) async throws -> [CareLogDTO] { try await get("/care-logs/\(userId)") }
}

// MARK: - Helper types

struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}


struct PublicStats: Codable {
    let totalUsers: Int?
    let totalPlants: Int?
    let totalEvents: Int?
    let uniqueSpecies: Int?
}

struct AuthResponse: Codable {
    let token: String?
    let accessToken: String?
    let user: UserDTO?
    let userId: Int?
    let username: String?
    let error: String?

    var jwt: String? { token ?? accessToken }
}

struct NoteDTO: Codable {
    let id: Int?
    let content: String?
    let createdAt: String?
}

struct PlantStatusDTO: Codable {
    let plantId: Int
    let status: String?
    let lastCare: String?
}

struct QRResponse: Codable {
    let data: QRData?
    let plant: PlantDTO?
    let error: String?

    struct QRData: Codable {
        let plant: PlantDTO?
    }
}

extension Notification.Name {
    static let authExpired = Notification.Name("mpr:auth-expired")
    static let userLoggedIn = Notification.Name("mpr:login")
    static let userLoggedOut = Notification.Name("mpr:logout")
    static let offlineStatusChanged = Notification.Name("mpr:offline-changed")
}
