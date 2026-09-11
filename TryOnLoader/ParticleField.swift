import SwiftUI

/// Deterministic 0..<1 value from an index and a channel. Particles derive every
/// attribute from this instead of stored state, so the field never needs to be
/// rebuilt when a control changes — and never resets mid-loop.
@inline(__always)
private func hash01(_ index: Int, _ channel: UInt64) -> Double {
    var x = UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15 &+ channel &* 0xBF58_476D_1CE4_E5B9
    x ^= x >> 30
    x = x &* 0xBF58_476D_1CE4_E5B9
    x ^= x >> 27
    x = x &* 0x94D0_49BB_1331_11EB
    x ^= x >> 31
    return Double(x >> 11) * (1.0 / 9_007_199_254_740_992.0)
}

private let tau = 2 * Double.pi
private let goldenAngle = Double.pi * (3 - 5.squareRoot())

/// Ambient dots orbiting the subject. Positions are a pure function of time, so
/// the whole field is redrawn from scratch every frame with no simulation state.
struct ParticleField: View {
    var settings: ParticleSettings
    var time: Double

    /// Per-dot alpha is quantised into buckets so the canvas issues ~16 fills a
    /// frame instead of one per particle.
    private static let alphaBuckets = 16

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let count = max(1, Int(settings.count))
            var buckets = [Path](repeating: Path(), count: Self.alphaBuckets)

            let wavefront = settings.pulseEnabled
                ? time.truncatingRemainder(dividingBy: max(0.2, settings.pulseInterval)) * settings.pulseSpeed
                : -1

            for i in 0..<count {
                let fi = Double(i)

                var angle0: Double
                var radiusFraction: Double
                switch settings.distribution {
                case .spiral:
                    angle0 = fi * goldenAngle
                    radiusFraction = ((fi + 0.5) / Double(count)).squareRoot()
                case .ring:
                    angle0 = hash01(i, 1) * tau
                    radiusFraction = hash01(i, 2)
                case .scatter:
                    angle0 = hash01(i, 1) * tau
                    radiusFraction = hash01(i, 2).squareRoot()
                }
                radiusFraction = pow(radiusFraction, 1 + settings.clumping * 2.5)

                let phase = hash01(i, 3) * tau
                let speedJitter = 1 + (hash01(i, 4) - 0.5) * 2 * settings.speedVariance
                // Inner dots sweep faster than outer ones, the way a galaxy does.
                let differential = 1 + settings.swirl * (1 - radiusFraction)
                let angle = angle0 + time * settings.orbitSpeed * tau * speedJitter * differential

                let drift = sin(time * settings.driftSpeed * tau + phase) * settings.driftAmount
                var radius = settings.innerRadius + radiusFraction * settings.bandWidth + drift

                var alpha = settings.opacity
                var diameter = settings.minSize + hash01(i, 5) * (settings.maxSize - settings.minSize)
                diameter *= 1 - settings.sizeFalloff * radiusFraction

                // Twinkle, then fade toward the outer edge of the band.
                let twinkle = 0.5 + 0.5 * sin(time * settings.twinkleSpeed * tau + phase * 1.7)
                alpha *= (1 - settings.twinkle) + settings.twinkle * twinkle
                alpha *= 1 - settings.outerFade * (radiusFraction * radiusFraction)

                if wavefront >= 0 {
                    let distance = abs(radius - wavefront)
                    if distance < settings.pulseWidth {
                        let influence = 0.5 + 0.5 * cos(.pi * distance / settings.pulseWidth)
                        let boost = influence * settings.pulseStrength
                        alpha *= 1 + boost
                        diameter *= 1 + boost * 0.55
                        radius += boost * 4
                    }
                }

                guard diameter > 0.2, alpha > 0.01 else { continue }

                let wobble = sin(time * 1.7 + phase * 2) * settings.jitter
                let x = center.x + cos(angle) * radius - sin(angle) * wobble
                let y = center.y + sin(angle) * radius + cos(angle) * wobble

                let bucket = min(Self.alphaBuckets - 1, Int(min(alpha, 1) * Double(Self.alphaBuckets)))
                buckets[bucket].addEllipse(in: CGRect(
                    x: x - diameter / 2,
                    y: y - diameter / 2,
                    width: diameter,
                    height: diameter
                ))
            }

            for (index, path) in buckets.enumerated() where !path.isEmpty {
                let alpha = (Double(index) + 0.5) / Double(Self.alphaBuckets)
                context.fill(path, with: .color(settings.color.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}
