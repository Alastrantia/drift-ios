import SwiftUI
import AVKit

struct NowPlayingView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(\.dismiss) private var dismiss
    @Namespace private var glass
    @State private var showMixer = false

    var body: some View {
        @Bindable var player = player
        let scape = player.current

        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Spacer(minLength: 12)

            Orb(scape: scape, isPlaying: player.isPlaying)
                .frame(width: 290, height: 290)

            Spacer(minLength: 12)

            VStack(spacing: 6) {
                Text(scape.name)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.opacity)
                Text(scape.subtitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .id(scape.id)
            .transition(.blurReplace)

            timerBar
                .padding(.horizontal, 28)
                .padding(.top, 28)

            transport
                .padding(.top, 26)

            volume
                .padding(.horizontal, 28)
                .padding(.top, 28)

            bottomBar
                .padding(.top, 26)
                .padding(.bottom, 10)
        }
        .foregroundStyle(.white)
        .background {
            ZStack {
                MeshBackdrop(palette: scape.palette, speed: player.isPlaying ? 1.4 : 0.4)
                LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .animation(.smooth(duration: 1), value: scape)
        }
        .animation(.smooth(duration: 0.6), value: scape)
        .sheet(isPresented: $showMixer) {
            NavigationStack {
                MixerSheet(scape: scape)
            }
            .presentationDetents([.height(340), .large])
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: player.isPlaying)
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)

            Spacer()
            VStack(spacing: 1) {
                Text("NOW PLAYING").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.6))
                Text("Drift Soundscapes").font(.footnote.weight(.semibold))
            }
            Spacer()

            Menu {
                Section("Sleep timer") {
                    ForEach([10, 20, 30, 45, 60], id: \.self) { m in
                        Button("\(m) minutes", systemImage: "moon.zzz") { player.setTimer(m) }
                    }
                    Button("Off", systemImage: "xmark", role: .destructive) { player.setTimer(nil) }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    private var timerBar: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                Capsule()
                    .fill(.white.opacity(0.18))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white)
                            .frame(width: max(6, proxy.size.width * player.timerProgress))
                            .animation(.linear(duration: 1), value: player.timerProgress)
                    }
            }
            .frame(height: 6)

            HStack {
                Text(player.timerMinutes == nil ? "∞" : TimeInterval(player.timerMinutes! * 60 - Int(player.remaining)).clock)
                Spacer()
                Text(player.timerMinutes == nil ? "No sleep timer" : "-" + player.remaining.clock)
            }
            .font(.caption.monospacedDigit())
            .contentTransition(.numericText(countsDown: true))
            .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var transport: some View {
        GlassEffectContainer(spacing: 24) {
            HStack(spacing: 22) {
                transportButton("backward.fill", size: 64) { player.step(-1) }
                    .glassEffectID("back", in: glass)

                Button {
                    withAnimation(.bouncy) { player.toggle() }
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.system(size: 36, weight: .semibold))
                        .frame(width: 96, height: 96)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(player.current.accent.opacity(0.45)).interactive(), in: .circle)
                .glassEffectID("play", in: glass)

                transportButton("forward.fill", size: 64) { player.step(1) }
                    .glassEffectID("forward", in: glass)
            }
        }
    }

    private func transportButton(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.smooth) { action() }
        } label: {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .sensoryFeedback(.selection, trigger: player.current)
    }

    private var volume: some View {
        @Bindable var player = player
        return HStack(spacing: 14) {
            Image(systemName: "speaker.fill").foregroundStyle(.white.opacity(0.7))
            Slider(value: $player.volume, in: 0...1)
                .tint(.white)
            Image(systemName: "speaker.wave.3.fill")
                .symbolEffect(.variableColor.iterative, options: .repeat(.continuous), isActive: player.isPlaying)
                .foregroundStyle(.white.opacity(0.7))
        }
        .font(.footnote)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button { showMixer = true } label: {
                Image(systemName: "slider.horizontal.3").frame(maxWidth: .infinity, minHeight: 44)
            }
            AirPlayButton()
                .frame(maxWidth: .infinity, maxHeight: 44)
            Button {
                withAnimation(.bouncy) {
                    let id = player.current.id
                    if player.favorites.contains(id) { player.favorites.remove(id) } else { player.favorites.insert(id) }
                }
            } label: {
                Image(systemName: player.favorites.contains(player.current.id) ? "heart.fill" : "heart")
                    .contentTransition(.symbolEffect(.replace))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .buttonStyle(.plain)
        .font(.title3)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 40)
    }
}

/// Soft concentric halos that breathe with the sound.
struct Orb: View {
    let scape: Soundscape
    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isPlaying)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    let phase = sin(t * 0.6 - Double(i) * 0.8)
                    Circle()
                        .fill(scape.accent.opacity(0.10 + 0.05 * Double(3 - i)))
                        .scaleEffect(0.55 + Double(i) * 0.15 + (isPlaying ? phase * 0.035 : 0))
                        .blur(radius: CGFloat(4 + i * 6))
                }
                Image(systemName: scape.symbol)
                    .font(.system(size: 78, weight: .light))
                    .frame(width: 170, height: 170)
                    .glassEffect(.clear, in: .circle)
                    .scaleEffect(isPlaying ? 1 + sin(t * 0.6) * 0.025 : 0.94)
            }
        }
        .animation(.spring(duration: 0.8, bounce: 0.3), value: isPlaying)
    }
}

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = .white
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

struct MixerSheet: View {
    let scape: Soundscape
    @Environment(PlayerModel.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                ForEach(Array(scape.layers.enumerated()), id: \.offset) { index, name in
                    VStack(alignment: .leading) {
                        Text(name)
                        Slider(value: Binding(
                            get: { player.levels(for: scape)[index] },
                            set: { player.setLevel($0, layer: index, for: scape) }
                        ))
                        .tint(scape.accent)
                    }
                }
            } footer: {
                Text("Every layer is synthesised in real time.")
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Mix · \(scape.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { dismiss() }
            }
        }
    }
}
