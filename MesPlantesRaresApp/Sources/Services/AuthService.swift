import Foundation
import SwiftData

@Observable
final class AuthService {
    private let api: APIClient
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false
    var errorMessage: String?

    init(api: APIClient) {
        self.api = api
        loadUser()
    }

    func login(username: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            let res: AuthResponse = try await api.login(username: username, password: password)
            guard let token = res.jwt else {
                errorMessage = res.error ?? "Token manquant"
                return false
            }
            let userDTO = res.user ?? UserDTO(id: res.userId ?? 0, username: res.username ?? username, email: nil, createdAt: nil)
            api.setToken(token, userId: userDTO.id)
            currentUser = userDTO.toModel
            isAuthenticated = true
            saveUser(userDTO.toModel)
            NotificationCenter.default.post(name: .userLoggedIn, object: nil)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func register(username: String, email: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            let res: AuthResponse = try await api.register(username: username, email: email, password: password)
            guard let token = res.jwt else {
                errorMessage = res.error ?? "Inscription échouée"
                return false
            }
            let userDTO = res.user ?? UserDTO(id: res.userId ?? 0, username: username, email: email, createdAt: nil)
            api.setToken(token, userId: userDTO.id)
            currentUser = userDTO.toModel
            isAuthenticated = true
            saveUser(userDTO.toModel)
            NotificationCenter.default.post(name: .userLoggedIn, object: nil)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        api.setToken(nil, userId: nil)
        currentUser = nil
        isAuthenticated = false
        deleteSavedUser()
        NotificationCenter.default.post(name: .userLoggedOut, object: nil)
    }

    private func loadUser() {
        guard let data = KeychainHelper.load(key: "current_user"),
              let user = try? JSONDecoder().decode(User.self, from: data) else { return }
        currentUser = user
        isAuthenticated = api.isLoggedIn
    }

    private func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            KeychainHelper.save(key: "current_user", data: data)
        }
    }

    private func deleteSavedUser() {
        KeychainHelper.delete(key: "current_user")
    }
}

// Make User Codable for Keychain storage
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id, username, email
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
    }
}
