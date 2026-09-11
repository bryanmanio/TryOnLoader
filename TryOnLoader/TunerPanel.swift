import SwiftUI
import UIKit

/// Live controls for the loading stage. The sheet allows background interaction
/// at its small detent, so the animation keeps running while a slider is dragged.
struct TunerPanel: View {
    @Binding var settings: ParticleSettings
    var store: PresetStore
    var isPaused: Bool
    var onTogglePause: () -> Void
    var onRestart: () -> Void

    @State private var didCopy = false
    @State private var isNamingPreset = false
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section { transportRow }

                presetsSection

                Section("Field") {
                    Picker("Distribution", selection: $settings.distribution) {
                        ForEach(ParticleSettings.Distribution.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    tuner("Count", $settings.count, 20...900, "%.0f")
                    tuner("Inner radius", $settings.innerRadius, 60...240, "%.0f")
                    tuner("Band width", $settings.bandWidth, 10...260, "%.0f")
                    tuner("Clumping", $settings.clumping, 0...1)
                }

                Section("Motion") {
                    tuner("Orbit speed", $settings.orbitSpeed, 0...0.5, "%.3f")
                    tuner("Swirl", $settings.swirl, 0...2)
                    tuner("Speed variance", $settings.speedVariance, 0...1)
                    tuner("Drift amount", $settings.driftAmount, 0...40, "%.1f")
                    tuner("Drift speed", $settings.driftSpeed, 0...2, "%.2f")
                    tuner("Jitter", $settings.jitter, 0...12, "%.1f")
                }

                Section("Dots") {
                    tuner("Min size", $settings.minSize, 0.5...10, "%.1f")
                    tuner("Max size", $settings.maxSize, 0.5...20, "%.1f")
                    tuner("Size falloff", $settings.sizeFalloff, 0...1)
                    tuner("Opacity", $settings.opacity, 0...1)
                    tuner("Twinkle", $settings.twinkle, 0...1)
                    tuner("Twinkle speed", $settings.twinkleSpeed, 0...3, "%.2f")
                    tuner("Outer fade", $settings.outerFade, 0...1)
                    ColorPicker("Dot color", selection: $settings.color, supportsOpacity: false)
                }

                Section("Pulse") {
                    Toggle("Radial pulse", isOn: $settings.pulseEnabled)
                    tuner("Interval", $settings.pulseInterval, 0.5...8, "%.2fs")
                    tuner("Travel speed", $settings.pulseSpeed, 40...500, "%.0f")
                    tuner("Width", $settings.pulseWidth, 10...160, "%.0f")
                    tuner("Strength", $settings.pulseStrength, 0...2)
                }

                Section("Subject") {
                    tuner("Halo size", $settings.haloSize, 120...320, "%.0f")
                    tuner("Subject scale", $settings.subjectScale, 0.8...3, "%.2f")
                    tuner("Subject offset", $settings.subjectOffset, -0.5...0.9, "%.3f")
                    Toggle("Crop subject to circle", isOn: $settings.clipSubjectToHalo)
                    if !settings.clipSubjectToHalo {
                        tuner("Fade start", $settings.subjectFadeStart, 0.2...1, "%.2f")
                        tuner("Fade length", $settings.subjectFadeLength, 0...0.5, "%.2f")
                    }
                    tuner("Breath", $settings.haloBreath, 0...0.08, "%.3f")
                    tuner("Sweep strength", $settings.sweepStrength, 0...1)
                    tuner("Sweep speed", $settings.sweepSpeed, 0...1, "%.2f")
                }

                Section("Orbiting garments") {
                    tuner("Tile size", $settings.garmentSize, 40...140, "%.0f")
                    tuner("Tile inset", $settings.garmentInset, 0...0.3, "%.2f")
                    tuner("Orbit radius", $settings.garmentRadius, 80...260, "%.0f")
                    tuner("Orbit width", $settings.orbitWidth, 0.3...1.2, "%.2f")
                    tuner("Orbit speed", $settings.garmentSpeed, 0...0.4, "%.3f")
                    tuner("Depth scale", $settings.garmentDepth, 0...0.6, "%.2f")
                    tuner("Bob", $settings.garmentBob, 0...20, "%.1f")
                    tuner("Sway", $settings.garmentSway, 0...15, "%.1f°")
                }

                Section("Stage") {
                    tuner("Vertical offset", $settings.stageOffset, -120...120, "%.0f")
                    tuner("Loop duration", $settings.cycleDuration, 6...30, "%.1fs")
                }

                Section {
                    Button("Copy settings as Swift") { copyConfiguration() }
                    if didCopy {
                        Text("Copied to clipboard")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Particles")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Save preset", isPresented: $isNamingPreset) {
                TextField("Name", text: $draftName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { store.save(name: draftName, settings: settings) }
            } message: {
                Text("Reusing an existing name overwrites that preset.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Presets") {
                        Button("Save current…") { beginNamingPreset() }
                        if !store.presets.isEmpty {
                            Section("Saved") {
                                ForEach(store.presets) { preset in
                                    Button(preset.name) { settings = preset.settings }
                                }
                            }
                        }
                        Section("Built in") {
                            ForEach(ParticleSettings.builtIns, id: \.name) { builtIn in
                                Button(builtIn.name) { applyBuiltIn(builtIn.settings) }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var presetsSection: some View {
        Section("Presets") {
            Button {
                beginNamingPreset()
            } label: {
                Label("Save current settings", systemImage: "square.and.arrow.down")
            }

            if store.presets.isEmpty {
                Text("Saved presets appear here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.presets) { preset in
                    Button {
                        settings = preset.settings
                    } label: {
                        HStack {
                            Text(preset.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if preset.settings == settings {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
                .onDelete { store.delete(at: $0) }
            }
        }
    }

    private func beginNamingPreset() {
        draftName = ""
        isNamingPreset = true
    }

    private var transportRow: some View {
        HStack(spacing: 12) {
            Button(action: onTogglePause) {
                Label(isPaused ? "Play" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            Button(action: onRestart) {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .labelStyle(.titleAndIcon)
    }

    private func tuner(
        _ title: String,
        _ value: Binding<Double>,
        _ range: ClosedRange<Double>,
        _ format: String = "%.2f"
    ) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            Slider(value: value, in: range)
        }
    }

    /// Built-ins tune the particles only; a saved preset is applied wholesale.
    private func applyBuiltIn(_ preset: ParticleSettings) {
        var next = preset
        next.haloSize = settings.haloSize
        next.subjectScale = settings.subjectScale
        next.subjectOffset = settings.subjectOffset
        next.clipSubjectToHalo = settings.clipSubjectToHalo
        next.stageOffset = settings.stageOffset
        next.cycleDuration = settings.cycleDuration
        settings = next
    }

    private func copyConfiguration() {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(settings.color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let s = settings
        let lines = [
            "var settings = ParticleSettings()",
            "settings.count = \(round(s.count))",
            "settings.distribution = .\(s.distribution.rawValue)",
            "settings.innerRadius = \(r(s.innerRadius))",
            "settings.bandWidth = \(r(s.bandWidth))",
            "settings.clumping = \(r(s.clumping))",
            "settings.orbitSpeed = \(r(s.orbitSpeed))",
            "settings.swirl = \(r(s.swirl))",
            "settings.speedVariance = \(r(s.speedVariance))",
            "settings.driftAmount = \(r(s.driftAmount))",
            "settings.driftSpeed = \(r(s.driftSpeed))",
            "settings.jitter = \(r(s.jitter))",
            "settings.minSize = \(r(s.minSize))",
            "settings.maxSize = \(r(s.maxSize))",
            "settings.sizeFalloff = \(r(s.sizeFalloff))",
            "settings.opacity = \(r(s.opacity))",
            "settings.twinkle = \(r(s.twinkle))",
            "settings.twinkleSpeed = \(r(s.twinkleSpeed))",
            "settings.outerFade = \(r(s.outerFade))",
            "settings.color = Color(red: \(r(Double(red))), green: \(r(Double(green))), blue: \(r(Double(blue))))",
            "settings.pulseEnabled = \(s.pulseEnabled)",
            "settings.pulseInterval = \(r(s.pulseInterval))",
            "settings.pulseWidth = \(r(s.pulseWidth))",
            "settings.pulseStrength = \(r(s.pulseStrength))",
            "settings.pulseSpeed = \(r(s.pulseSpeed))",
            "settings.haloSize = \(r(s.haloSize))",
            "settings.haloBreath = \(r(s.haloBreath, 4))",
            "settings.subjectScale = \(r(s.subjectScale))",
            "settings.subjectOffset = \(r(s.subjectOffset, 4))",
            "settings.clipSubjectToHalo = \(s.clipSubjectToHalo)",
            "settings.subjectFadeStart = \(r(s.subjectFadeStart))",
            "settings.subjectFadeLength = \(r(s.subjectFadeLength))",
            "settings.sweepStrength = \(r(s.sweepStrength))",
            "settings.sweepSpeed = \(r(s.sweepSpeed))",
            "settings.garmentSize = \(r(s.garmentSize))",
            "settings.garmentInset = \(r(s.garmentInset))",
            "settings.garmentRadius = \(r(s.garmentRadius))",
            "settings.garmentSpeed = \(r(s.garmentSpeed, 4))",
            "settings.orbitWidth = \(r(s.orbitWidth))",
            "settings.garmentDepth = \(r(s.garmentDepth))",
            "settings.garmentBob = \(r(s.garmentBob))",
            "settings.garmentSway = \(r(s.garmentSway))",
            "settings.stageOffset = \(r(s.stageOffset))",
            "settings.cycleDuration = \(r(s.cycleDuration))"
        ]
        UIPasteboard.general.string = lines.joined(separator: "\n")

        withAnimation { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { didCopy = false }
        }
    }

    private func r(_ value: Double, _ places: Int = 3) -> String {
        String(format: "%.\(places)f", value)
    }
}
