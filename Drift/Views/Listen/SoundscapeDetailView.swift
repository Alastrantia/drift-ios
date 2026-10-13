import SwiftUI

struct SoundscapeDetailView: View {
    let scape: Soundscape
    @Environment(PlayerModel.self) private var player
    @Environment(AppRouter.self) private var router
    @Namespace private var glass
    @State private var timerExpanded = false
    @State private var appeared = false

    private var isPlaying: Bool { player.current == scape && player.isPlaying }

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                header
                controls
                mixer
                about
            }
            .padding(.horizontal, 20)
            .padding(.top, 120)
            .padding(.bottom, 60)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background {
            MeshBackdrop(palette: scape.palette, speed: isPlaying ? 1.6 : 0.8)
                .overlay(.black.opacity(0.12))
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let fav = player.favorites.contains(scape.id)
                Button("Favorite", systemImage: fav ? "heart.fill" : "heart") {
                    withAnimation(.bouncy) {
                        if fav { player.favorites.remove(scape.id) } else { player.favorites.insert(scape.id) }
                    }
                }
                .symbolEffect(.bounce, value: fav)
                .tint(fav ? .pink : nil)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "Drifting off to \(scape.name) 🌙")
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.8).delay(0.15)) { appeared = true }
        }
        .onChange(of: router.demoExpandTimer) { _, expand in
            withAnimation(.bouncy(duration: 0.55)) { timerExpanded = expand }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isPlaying)
        .sensoryFeedback(.selection, trigger: timerExpanded)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: scape.symbol)
                .font(.system(size: 64, weight: .light))
                .symbolEffect(.breathe, options: .repeat(.continuous), isActive: isPlaying)
                .frame(width: 128, height: 128)
                .glassEffect(.clear.interactive(), in: .circle)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

            Text(scape.name)
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(scape.subtitle)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 8) {
                ForEach(scape.tags, id: \.self) { tag in
                    GlassChip(title: tag)
                }
            }
            .padding(.top, 4)
            .offset(y: appeared ? 0 : 16)
            .opacity(appeared ? 1 : 0)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
    }

    // MARK: Controls — the glass shapes merge and split as the timer opens.

    private var controls: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                Button {
                    withAnimation(.bouncy) { isPlaying ? player.pause() : player.play(scape) }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.title.weight(.semibold))
                        .frame(width: 76, height: 76)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(scape.accent.opacity(0.55)).interactive(), in: .circle)
                .glassEffectID("play", in: glass)

                if timerExpanded {
                    ForEach([15, 30, 60], id: \.self) { minutes in
                        Button {
                            player.setTimer(minutes)
                            withAnimation(.bouncy(duration: 0.5)) { timerExpanded = false }
                        } label: {
                            Text("\(minutes)m")
                                .font(.headline)
                                .frame(width: 56, height: 56)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .circle)
                        .glassEffectID("timer-\(minutes)", in: glass)
                    }
                } else {
                    Button {
                        withAnimation(.bouncy(duration: 0.55)) { timerExpanded = true }
                    } label: {
                        Label(timerLabel, systemImage: "timer")
                            .font(.headline)
                            .contentTransition(.numericText())
                            .padding(.horizontal, 22)
                            .frame(height: 56)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .glassEffectID("timer", in: glass)
                }
            }
            .foregroundStyle(.white)
        }
        .frame(height: 80)
    }

    private var timerLabel: String {
        if let m = player.timerMinutes, player.remaining > 0 { return player.remaining.clock + " · \(m)m" }
        return "Sleep timer"
    }

    // MARK: Mixer

    private var mixer: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Mix", systemImage: "slider.horizontal.3")
                .font(.headline)
            ForEach(Array(scape.layers.enumerated()), id: \.offset) { index, name in
                let level = player.levels(for: scape)[index]
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(name)
                        Spacer()
                        Text(level, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                            .contentTransition(.numericText(value: level))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .font(.subheadline.weight(.medium))
                    Slider(value: Binding(
                        get: { level },
                        set: { player.setLevel($0, layer: index, for: scape) }
                    ))
                    .tint(scape.accent)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("About", systemImage: "text.quote").font(.headline)
            Text(scape.blurb)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Text("Generated live on your iPhone — never loops, never repeats.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
    }
}
