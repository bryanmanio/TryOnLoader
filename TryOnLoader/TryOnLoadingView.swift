import SwiftUI

private let tau = 2 * Double.pi

struct TryOnLoadingView: View {
    @State private var settings = ParticleSettings.mockup
    @State private var store = PresetStore()
    @State private var showTuner = false

    // One clock drives the particles, the orbit and the step copy, so everything
    // stays in phase and nothing resets when a control moves.
    @State private var start = Date()
    @State private var isPaused = false
    @State private var frozenTime: Double = 0
    @State private var stepIndex = 0
    @State private var ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private let steps = ["Analyzing your photo", "Adding outfit", "Finishing details"]

    private var active: ParticleSettings {
        reduceMotion ? settings.motionReduced() : settings
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                stage
                Spacer(minLength: 0)
                caption
            }

            topBar
        }
        .onAppear {
            if let restored = store.lastUsedSettings { settings = restored }
        }
        .onChange(of: showTuner) { _, isOpen in
            // Persist when the sheet closes rather than on every slider tick.
            if !isOpen { store.rememberWorkingSettings(settings) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.rememberWorkingSettings(settings) }
        }
        .sheet(isPresented: $showTuner) {
            TunerPanel(
                settings: $settings,
                store: store,
                isPaused: isPaused,
                onTogglePause: { setPaused(!isPaused) },
                onRestart: restart
            )
            .presentationDetents([.height(280), .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .height(280)))
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: Stage

    private var stage: some View {
        TimelineView(.animation(minimumInterval: nil, paused: isPaused)) { timeline in
            let time = isPaused ? frozenTime : timeline.date.timeIntervalSince(start)
            let s = active

            ZStack {
                ParticleField(settings: s, time: time)

                subject(time: time, settings: s)
                ForEach(garments(at: time)) { garment($0, settings: s) }
            }
        }
        .frame(height: 420)
        .offset(y: settings.stageOffset)
    }

    private func subject(time: Double, settings s: ParticleSettings) -> some View {
        let breath = 1 + sin(time * 0.6) * s.haloBreath

        return ZStack {
            halo(time: time, settings: s)
                .scaleEffect(breath)

            subjectArtwork(settings: s)
        }
        .frame(width: s.haloSize, height: s.haloSize)
    }

    private func halo(time: Double, settings s: ParticleSettings) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(white: 0.925), Color(white: 0.955)],
                    center: .center,
                    startRadius: 0,
                    endRadius: s.haloSize / 2
                ))

            if s.sweepStrength > 0.001 {
                Circle()
                    .fill(AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(white: 0.84).opacity(s.sweepStrength), location: 0.16),
                            .init(color: .clear, location: 0.40),
                            .init(color: .clear, location: 1)
                        ]),
                        center: .center
                    ))
                    .rotationEffect(.radians(time * s.sweepSpeed * tau))
            }
        }
        .frame(width: s.haloSize, height: s.haloSize)
    }

    @ViewBuilder
    private func subjectArtwork(settings s: ParticleSettings) -> some View {
        let art = Group {
            if let cutout = UIImage(named: Artwork.subject) {
                Image(uiImage: cutout).resizable().scaledToFit()
            } else {
                SubjectPlaceholder()
            }
        }
        .frame(height: s.haloSize * s.subjectScale)

        if s.clipSubjectToHalo {
            // The circle is fixed to the halo, so it has to crop after the offset.
            art
                .offset(y: s.haloSize * s.subjectOffset)
                .frame(width: s.haloSize, height: s.haloSize)
                .clipShape(Circle())
        } else {
            // The fade is measured in the subject's own height, so it has to
            // mask before the offset moves the drawing away from its layout frame.
            art
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: s.subjectFadeStart),
                            .init(color: .clear, location: min(1, s.subjectFadeStart + max(0.001, s.subjectFadeLength)))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .offset(y: s.haloSize * s.subjectOffset)
        }
    }

    // MARK: Orbiting garments

    private struct GarmentPlacement: Identifiable {
        let id: Int
        let offset: CGSize
        let scale: Double
        let rotation: Double
        let depth: Double
    }

    private func garments(at time: Double) -> [GarmentPlacement] {
        let s = active
        // Start opposed: top piece up-left, bottom piece down-right, as in the mockup.
        let startAngles = [200.0, 20.0].map { $0 * .pi / 180 }

        return startAngles.enumerated().map { index, startAngle in
            let theta = startAngle + time * s.garmentSpeed * tau
            // Always drawn over the subject; depth only drives scale and shadow.
            let depth = sin(theta)                       // +1 nearest the viewer
            let bob = sin(time * 0.9 + Double(index) * 1.7) * s.garmentBob

            return GarmentPlacement(
                id: index,
                offset: CGSize(
                    width: cos(theta) * s.garmentRadius * s.orbitWidth,
                    height: depth * s.garmentRadius + bob
                ),
                scale: 1 + s.garmentDepth * depth,
                rotation: sin(time * 0.7 + Double(index) * 2.1) * s.garmentSway,
                depth: depth
            )
        }
    }

    private func garment(_ placement: GarmentPlacement, settings s: ParticleSettings) -> some View {
        let radius = s.garmentSize * 0.21
        let lift = (placement.depth + 1) / 2   // 0 at the back, 1 at the front

        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color(white: 0.945))
            .overlay {
                Group {
                    if placement.id == 0 {
                        ArtworkImage(name: Artwork.top) { TeeShape().fill(Color(white: 0.40)) }
                    } else {
                        ArtworkImage(name: Artwork.bottom) { LeggingsShape().fill(Color(white: 0.20)) }
                    }
                }
                .padding(s.garmentSize * s.garmentInset)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .frame(width: s.garmentSize, height: s.garmentSize)
            .shadow(
                color: .black.opacity(0.04 + 0.06 * lift),
                radius: 6 + 9 * lift,
                x: 0,
                y: 2 + 5 * lift
            )
            .scaleEffect(placement.scale)
            .rotationEffect(.degrees(placement.rotation))
            .offset(placement.offset)
    }

    // MARK: Caption

    private var caption: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Step \(stepIndex + 1)")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.46))
                    Text(steps[stepIndex])
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(white: 0.11))
                }
                .id(stepIndex)
                .transition(.asymmetric(
                    insertion: .offset(y: 14).combined(with: .opacity),
                    removal: .offset(y: -14).combined(with: .opacity)
                ))
            }
            .frame(height: 48, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onReceive(ticker) { _ in advanceStep() }

            Text("AI images may include mistakes. Fit and appearance won't be exact.")
                .font(.footnote)
                .foregroundStyle(Color(white: 0.52))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
    }

    // MARK: Chrome

    private var topBar: some View {
        VStack {
            HStack {
                circleButton("slider.horizontal.3") { showTuner = true }
                Spacer()
                circleButton("xmark") {}
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            Spacer()
        }
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(white: 0.15))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color(white: 0.96)))
        }
        .buttonStyle(.plain)
    }

    // MARK: Clock

    private func setPaused(_ paused: Bool) {
        if paused {
            frozenTime = Date().timeIntervalSince(start)
        } else {
            start = Date().addingTimeInterval(-frozenTime)
        }
        isPaused = paused
    }

    private func restart() {
        start = Date()
        frozenTime = 0
        isPaused = false
        withAnimation(.smooth(duration: 0.45)) { stepIndex = 0 }
    }

    private func advanceStep() {
        guard !isPaused else { return }
        let cycle = max(3, settings.cycleDuration)
        let elapsed = Date().timeIntervalSince(start).truncatingRemainder(dividingBy: cycle)
        let next = min(steps.count - 1, Int(elapsed / cycle * Double(steps.count)))
        guard next != stepIndex else { return }
        withAnimation(.smooth(duration: 0.45)) { stepIndex = next }
    }
}

extension ParticleSettings {
    /// Softened variant used when the system asks for reduced motion.
    func motionReduced() -> ParticleSettings {
        var s = self
        s.orbitSpeed *= 0.25
        s.garmentSpeed *= 0.25
        s.swirl *= 0.4
        s.jitter = 0
        s.driftAmount *= 0.3
        s.twinkle *= 0.4
        s.pulseEnabled = false
        s.haloBreath = 0
        s.garmentBob = 0
        s.garmentSway = 0
        return s
    }
}

#Preview {
    TryOnLoadingView()
}
