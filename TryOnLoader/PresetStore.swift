import Foundation

struct SavedPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var settings: ParticleSettings
}

/// Saved presets and the last settings you were working on, kept in
/// `UserDefaults` so a relaunch doesn't throw away a dial-in session.
@Observable
final class PresetStore {
    private(set) var presets: [SavedPreset] = []

    private let presetsKey = "tryOnLoader.presets"
    private let workingKey = "tryOnLoader.workingSettings"
    private let defaults = UserDefaults.standard

    init() {
        if let data = defaults.data(forKey: presetsKey),
           let decoded = try? JSONDecoder().decode([SavedPreset].self, from: data) {
            presets = decoded
        }
    }

    /// The settings in play when the app last went away, if they still decode.
    var lastUsedSettings: ParticleSettings? {
        guard let data = defaults.data(forKey: workingKey) else { return nil }
        return try? JSONDecoder().decode(ParticleSettings.self, from: data)
    }

    func rememberWorkingSettings(_ settings: ParticleSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: workingKey)
    }

    /// Saving under an existing name overwrites it, which is what you want when
    /// iterating on the same look.
    func save(name: String, settings: ParticleSettings) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = presets.firstIndex(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            presets[index].settings = settings
        } else {
            presets.append(SavedPreset(name: trimmed, settings: settings))
        }
        persistPresets()
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        persistPresets()
    }

    private func persistPresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        defaults.set(data, forKey: presetsKey)
    }
}
