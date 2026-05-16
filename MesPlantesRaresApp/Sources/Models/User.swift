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

// Codable for Keychain serialization
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id, username, email
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(Int.self, forKey: .id),
            username: try container.decode(String.self, forKey: .username),
            email: try container.decodeIfPresent(String.self, forKey: .email)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
    }
}
