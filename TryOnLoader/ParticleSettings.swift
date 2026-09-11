import SwiftUI
import UIKit

/// A `Color` that survives a round trip through JSON, so presets can be saved.
struct RGBColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(white: Double) {
        self.init(red: white, green: white, blue: white)
    }

    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: Double(r), green: Double(g), blue: Double(b))
    }

    var color: Color { Color(red: red, green: green, blue: blue) }
}

/// Every knob the loading stage exposes. Value type on purpose: the whole thing
/// is handed to `Canvas` each frame, so SwiftUI can diff it cheaply and a slider
/// drag shows up on the very next frame.
struct ParticleSettings: Equatable, Codable {

    enum Distribution: String, CaseIterable, Identifiable, Codable {
        case spiral, ring, scatter
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    // MARK: Field
    var count: Double = 260
    var distribution: Distribution = .spiral
    var innerRadius: Double = 116
    var bandWidth: Double = 76
    var clumping: Double = 0.30          // 0 = spread evenly, 1 = hugs the subject

    // MARK: Motion
    var orbitSpeed: Double = 0.055       // revolutions per second
    var swirl: Double = 0.60             // inner dots outrun outer dots
    var speedVariance: Double = 0.35
    var driftAmount: Double = 9          // radial breathing, points
    var driftSpeed: Double = 0.22
    var jitter: Double = 2.0             // tangential wobble, points

    // MARK: Appearance
    var minSize: Double = 1.5
    var maxSize: Double = 7.5
    var sizeFalloff: Double = 0.55       // shrink toward the outer edge
    var opacity: Double = 0.60
    var twinkle: Double = 0.45
    var twinkleSpeed: Double = 0.55
    var outerFade: Double = 0.75
    var dotColor = RGBColor(white: 0.60)

    /// Bridges the stored components to the `ColorPicker`.
    var color: Color {
        get { dotColor.color }
        set { dotColor = RGBColor(newValue) }
    }

    // MARK: Pulse — a wave that rolls outward from the subject
    var pulseEnabled: Bool = true
    var pulseInterval: Double = 3.2
    var pulseWidth: Double = 58
    var pulseStrength: Double = 0.85
    var pulseSpeed: Double = 185         // points per second

    // MARK: Subject
    var haloSize: Double = 236
    var haloBreath: Double = 0.014
    var subjectScale: Double = 1.62      // subject height as a multiple of the halo
    var subjectOffset: Double = 0.336    // slide the subject down relative to the halo
    var clipSubjectToHalo: Bool = false  // on: hard-crop the subject to the circle
    var subjectFadeStart: Double = 0.58  // where the subject starts dissolving, as a
    var subjectFadeLength: Double = 0.16 // fraction of its own height
    var sweepStrength: Double = 0.35     // conic shimmer over the halo
    var sweepSpeed: Double = 0.18

    // MARK: Orbiting garments
    var garmentSize: Double = 74
    var garmentInset: Double = 0.10      // padding around the garment inside its tile
    var garmentRadius: Double = 172      // vertical radius of the orbit
    var garmentSpeed: Double = 0.045
    var orbitWidth: Double = 0.76        // horizontal radius as a fraction of the
                                         // vertical one: keeps a full revolution on
                                         // screen beside a halo this wide
    var garmentDepth: Double = 0.17      // scale delta between front and back
    var garmentBob: Double = 5
    var garmentSway: Double = 3          // degrees

    // MARK: Stage
    var stageOffset: Double = -28        // nudge the whole composition vertically
    var cycleDuration: Double = 15

    static let mockup = ParticleSettings()

    static let dust: ParticleSettings = {
        var s = ParticleSettings()
        s.count = 520
        s.distribution = .scatter
        s.innerRadius = 110
        s.bandWidth = 110
        s.minSize = 1.0
        s.maxSize = 3.6
        s.opacity = 0.5
        s.twinkle = 0.7
        s.swirl = 0.25
        s.orbitSpeed = 0.03
        s.driftAmount = 16
        return s
    }()

    static let calm: ParticleSettings = {
        var s = ParticleSettings()
        s.count = 160
        s.distribution = .ring
        s.bandWidth = 56
        s.clumping = 0.55
        s.orbitSpeed = 0.03
        s.swirl = 0.2
        s.twinkle = 0.25
        s.twinkleSpeed = 0.35
        s.pulseStrength = 0.4
        s.pulseInterval = 4.5
        s.maxSize = 6.0
        return s
    }()

    static let energetic: ParticleSettings = {
        var s = ParticleSettings()
        s.count = 340
        s.orbitSpeed = 0.14
        s.swirl = 1.1
        s.speedVariance = 0.6
        s.jitter = 4.5
        s.twinkle = 0.65
        s.twinkleSpeed = 1.4
        s.pulseInterval = 1.8
        s.pulseSpeed = 260
        s.garmentSpeed = 0.11
        return s
    }()

    static let builtIns: [(name: String, settings: ParticleSettings)] = [
        ("Mockup", .mockup),
        ("Dust", .dust),
        ("Calm", .calm),
        ("Energetic", .energetic)
    ]
}
