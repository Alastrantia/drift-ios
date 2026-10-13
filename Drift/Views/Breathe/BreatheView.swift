import SwiftUI

struct BreathPattern: Identifiable, Hashable {
    struct Phase: Hashable {
        let name: String
        let seconds: Int
        let scale: CGFloat?   // nil = hold the current size
    }
    let id: String
    let name: String
    let detail: String
    let phases: [Phase]

    static let all: [BreathPattern] = [
        .init(id: "box", name: "Box", detail: "Steady focus · 4-4-4-4", phases: [
            .init(name: "Breathe in", seconds: 4, scale: 1),
            .init(name: "Hold", seconds: 4, scale: nil),
            .init(name: "Breathe out", seconds: 4, scale: 0.55),
            .init(name: "Hold", seconds: 4, scale: nil),
        ]),
        .init(id: "478", name: "4·7·8", detail: "Wind down for sleep", phases: [
            .init(name: "Breathe in", seconds: 4, scale: 1),
            .init(name: "Hold", seconds: 7, scale: nil),
            .init(name: "Breathe out", seconds: 8, scale: 0.55),
        ]),
        .init(id: "coherent", name: "Coherent", detail: "Balance · 5.5 breaths/min", phases: [
            .init(name: "Breathe in", seconds: 5, scale: 1),
            .init(name: "Breathe out", seconds: 5, scale: 0.55),
        ]),
    ]
}

struct BreatheView: View {
    @Environment(AppRouter.self) private var router
    @State private var pattern = BreathPattern.all[0]
    @State private var running = false
    @State private var phaseIndex = 0
    @State private var count = 0
    @State private var scale: CGFloat = 0.55
    @State private var ring: CGFloat = 0
    @State private var cycles = 0
    @State private var loop: Task<Void, Never>?

    private let palette: [Color] = [
        Color(hex: 0x081A26), Color(hex: 0x0E2C3D), Color(hex: 0x0A1F2E),
        Color(hex: 0x1E5A6E), Color(hex: 0x4FA3A5), Color(hex: 0x2B5F7C),
        Color(hex: 0x0B2030), Color(hex: 0x2F7D86), Color(hex: 0x123247),
    ]

    private var phase: BreathPattern.Phase { pattern.phases[phaseIndex] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Picker("Pattern", selection: $pattern) {
                    ForEach(BreathPattern.all) { Text($0.name).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .disabled(running)

                Text(pattern.detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .contentTransition(.opacity)
                    .animation(.smooth, value: pattern)

                Spacer(minLength: 0)

                breathingCircle

                VStack(spacing: 6) {
                    Text(running ? phase.name : "Ready when you are")
                        .font(.title2.weight(.semibold))
                        .contentTransition(.interpolate)
                    Text(running ? "Cycle \(cycles + 1)" : "Find a comfortable position")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .contentTransition(.numericText())
                }
                .animation(.smooth(duration: 0.6), value: phaseIndex)
                .animation(.smooth, value: running)

                Spacer(minLength: 0)

                Button {
                    running ? stop() : start()
                } label: {
                    Label(running ? "End session" : "Begin", systemImage: running ? "stop.fill" : "play.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.headline)
                        .frame(width: 200, height: 34)
                }
                .buttonStyle(.glassProminent)
                .tint(running ? Color.white.opacity(0.18) : Color(hex: 0x4FA3A5))
                .padding(.bottom, 84) // clear the mini player accessory
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                MeshBackdrop(palette: palette, speed: 0.5, amplitude: 0.1)
                    .ignoresSafeArea()
            }
            .padding(.top, 12)
            .navigationTitle("Breathe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("History", systemImage: "clock.arrow.circlepath") {}
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: phaseIndex)
        .onDisappear { stop() }
        .onChange(of: router.demoStartBreathing) { _, go in if go { start() } }
    }

    private var breathingCircle: some View {
        ZStack {
            // Petals: overlapping translucent circles that bloom outwards.
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(hex: 0x7FD6CF).opacity(0.55), Color(hex: 0x3A7BD5).opacity(0.25)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 150, height: 150)
                    .offset(y: -60 * (scale - 0.4))
                    .rotationEffect(.degrees(Double(i) * 60 + Double(scale) * 45))
                    .blendMode(.plusLighter)
            }
            .scaleEffect(scale)

            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 4)
                .frame(width: 300, height: 300)
            Circle()
                .trim(from: 0, to: ring)
                .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 300, height: 300)

            Text(running ? "\(count)" : "")
                .font(.system(size: 56, weight: .semibold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(countsDown: true))
                .frame(width: 110, height: 110)
                .glassEffect(.clear, in: .circle)
        }
        .frame(width: 320, height: 320)
    }

    private func start() {
        running = true
        cycles = 0
        loop?.cancel()
        loop = Task { await run() }
    }

    private func stop() {
        loop?.cancel()
        loop = nil
        running = false
        withAnimation(.smooth(duration: 1.2)) {
            scale = 0.55
            ring = 0
            phaseIndex = 0
        }
    }

    @MainActor
    private func run() async {
        while !Task.isCancelled {
            for (i, p) in pattern.phases.enumerated() {
                phaseIndex = i
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { ring = 0 }
                try? await Task.sleep(for: .milliseconds(30))

                withAnimation(.linear(duration: Double(p.seconds) - 0.03)) { ring = 1 }
                if let target = p.scale {
                    withAnimation(.easeInOut(duration: Double(p.seconds))) { scale = target }
                }
                for c in stride(from: p.seconds, to: 0, by: -1) {
                    withAnimation(.snappy) { count = c }
                    try? await Task.sleep(for: .seconds(1))
                    if Task.isCancelled { return }
                }
            }
            withAnimation { cycles += 1 }
        }
    }
}
