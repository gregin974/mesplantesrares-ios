import Foundation
import SwiftData

@Model
final class Plant {
    @Attribute(.unique) var id: Int
    var name: String?
    var species: String?
    var genus: String?
    var botanicalFamily: String?
    var scientificName: String?
    var originCountry: String?
    var location: String?
    var mainPhotoUrl: String?
    var photoUrl: String?
    var owner: String?
    var createdAt: Date?
    var lastCare: Date?
    var status: String? // "ok", "warning", "urgent"

    init(id: Int, name: String? = nil, species: String? = nil, genus: String? = nil,
         botanicalFamily: String? = nil, scientificName: String? = nil, originCountry: String? = nil,
         location: String? = nil, mainPhotoUrl: String? = nil, photoUrl: String? = nil,
         owner: String? = nil, lastCare: Date? = nil, status: String? = nil) {
        self.id = id
        self.name = name
        self.species = species
        self.genus = genus
        self.botanicalFamily = botanicalFamily
        self.scientificName = scientificName
        self.originCountry = originCountry
        self.location = location
        self.mainPhotoUrl = mainPhotoUrl
        self.photoUrl = photoUrl
        self.owner = owner
        self.lastCare = lastCare
        self.status = status
    }

    var displayName: String { name ?? "Sans nom" }

    var subtitle: String {
        [species, botanicalFamily, originCountry].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var photoURL: URL? {
        let path = mainPhotoUrl ?? photoUrl ?? ""
        guard !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        if path.hasPrefix("/") { return URL(string: "https://mesplantesrares.fr\(path)") }
        return URL(string: "https://mesplantesrares.fr/uploads/\(path)")
    }

    var statusBadge: (String, String)? {
        switch status {
        case "urgent": return ("⚠️ Urgent", "badge-danger")
        case "warning": return ("💧 À arroser", "badge-warning")
        default: return nil
        }
    }
}

struct PlantDTO: Codable {
    let id: Int
    let name: String?
    let species: String?
    let genus: String?
    let botanicalFamily: String?
    let scientificName: String?
    let originCountry: String?
    let location: String?
    let mainPhotoUrl: String?
    let photoUrl: String?
    let owner: String?
    let lastCare: String?
    let status: String?

    var toModel: Plant {
        let lastCareDate: Date? = {
            guard let d = lastCare else { return nil }
            return ISO8601DateFormatter().date(from: d)
        }()
        return Plant(id: id, name: name, species: species, genus: genus,
                     botanicalFamily: botanicalFamily, scientificName: scientificName,
                     originCountry: originCountry, location: location,
                     mainPhotoUrl: mainPhotoUrl, photoUrl: photoUrl,
                     owner: owner, lastCare: lastCareDate, status: status)
    }
}
