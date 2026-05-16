import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: Int
    var username: String
    var email: String?
    var createdAt: Date?

    init(id: Int, username: String, email: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = createdAt
    }
}

struct UserDTO: Codable {
    let id: Int
    let username: String
    let email: String?
    let createdAt: String?

    var toModel: User {
        User(id: id, username: username, email: email)
    }
}
