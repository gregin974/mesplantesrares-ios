import Foundation

enum Config {
    static let apiBase = "https://mesplantesrares.fr/api"
    static let appName = "Mes Plantes Rares"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}
