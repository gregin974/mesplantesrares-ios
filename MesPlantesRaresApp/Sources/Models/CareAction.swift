import Foundation

enum CareActionType: String, Codable, CaseIterable {
    case watering = "watering"
    case fertilizing = "fertilizing"
    case pruning = "pruning"
    case repotting = "repotting"
    case treatment = "treatment"
    case observation = "observation"
    case other = "other"

    var label: String {
        switch self {
        case .watering: "Arrosage"
        case .fertilizing: "Fertilisation"
        case .pruning: "Taille"
        case .repotting: "Rempotage"
        case .treatment: "Traitement"
        case .observation: "Observation"
        case .other: "Soin"
        }
    }

    var emoji: String {
        switch self {
        case .watering: "💧"
        case .fertilizing: "🌱"
        case .pruning: "✂️"
        case .repotting: "🪴"
        case .treatment: "💊"
        case .observation: "📝"
        case .other: "🔧"
        }
    }
}
