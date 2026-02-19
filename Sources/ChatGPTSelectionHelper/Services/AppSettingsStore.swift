import Foundation

final class AppSettingsStore {
    private let defaults: UserDefaults
    private let key = "app_settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }

    func save(_ settings: AppSettings) {
        guard let encoded = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(encoded, forKey: key)
    }
}
