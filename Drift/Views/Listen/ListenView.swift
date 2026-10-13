import SwiftUI

struct ListenView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(AppRouter.self) private var router
    @Namespace private var zoom

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.listenPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    HeroCard(scape: .featured, zoom: zoom) {
                        router.listenPath.append(.init(soundscape: .featured, sourceID: "hero"))
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Moods", subtitle: "Swipe to find your atmosphere")
                        MoodCarousel(zoom: zoom)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "For tonight")
                        VStack(spacing: 10) {
                            ForEach(Soundscape.all.suffix(5)) { scape in
                                SoundscapeRow(scape: scape, zoom: zoom)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollPosition($router.listenScroll)
            .background { AmbientPageBackground(scape: player.current) }
            .navigationTitle(greeting)
            .navigationSubtitle("Drift")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Favorites", systemImage: "heart") {}
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "person.crop.circle") {
                        router.showSettings = true
                    }
                }
            }
            .navigationDestination(for: SoundscapeRoute.self) { route in
                SoundscapeDetailView(scape: route.soundscape)
                    .navigationTransition(.zoom(sourceID: route.sourceID, in: zoom))
            }
            .sheet(isPresented: $router.showSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

/// Very soft wash of the currently selected soundscape's colours behind the page.
struct AmbientPageBackground: View {
    let scape: Soundscape

    var body: some View {
        ZStack {
            Color.black
            MeshBackdrop(palette: scape.palette, speed: 0.6)
                .opacity(0.35)
                .blur(radius: 60)
                .animation(.smooth(duration: 1.2), value: scape)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hero

struct HeroCard: View {
    let scape: Soundscape
    let zoom: Namespace.ID
    let open: () -> Void
    @Environment(PlayerModel.self) private var player

    var body: some View {
        let isCurrent = player.current == scape && player.isPlaying

        ZStack(alignment: .bottomLeading) {
            // Parallax + stretch: the art moves slower than the scroll and
            // stretches when pulled past the top.
            MeshBackdrop(palette: scape.palette)
                .visualEffect { content, proxy in
                    let minY = proxy.frame(in: .scrollView).minY
                    return content
                        .scaleEffect(minY > 0 ? 1 + minY / 400 : 1, anchor: .bottom)
                        .offset(y: minY > 0 ? 0 : -minY * 0.35)
                }

            Image(systemName: scape.symbol)
                .font(.system(size: 120, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.18))
                .symbolEffect(.breathe.pulse, options: .repeat(.continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(28)

            VStack(alignment: .leading, spacing: 14) {
                GlassChip(title: "Tonight's pick", symbol: "moon.fill")
                Spacer()
                Text(scape.name)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(scape.subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 10) {
                    Button {
                        isCurrent ? player.pause() : player.play(scape)
                    } label: {
                        Label(isCurrent ? "Pause" : "Play", systemImage: isCurrent ? "pause.fill" : "play.fill")
                            .contentTransition(.symbolEffect(.replace))
                            .font(.headline)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(scape.accent.opacity(0.85))

                    GlassChip(title: "\(scape.minutes) min", symbol: "clock")
                    GlassChip(title: scape.tags.first ?? "", symbol: "bed.double")
                }
                .padding(.top, 6)
            }
            .padding(22)
        }
        .frame(height: 460)
        .clipShape(.rect(cornerRadius: 38, style: .continuous))
        .contentShape(.rect(cornerRadius: 38))
        .matchedTransitionSource(id: "hero", in: zoom)
        .onTapGesture(perform: open)
        .shadow(color: scape.accent.opacity(0.25), radius: 30, y: 20)
    }
}

// MARK: - Carousel

struct MoodCarousel: View {
    let zoom: Namespace.ID
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(Soundscape.all) { scape in
                    MoodCard(scape: scape)
                        .matchedTransitionSource(id: "mood-\(scape.id)", in: zoom)
                        .onTapGesture {
                            router.listenPath.append(.init(soundscape: scape, sourceID: "mood-\(scape.id)"))
                        }
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.88)
                                .rotation3DEffect(.degrees(phase.value * -18), axis: (0, 1, 0), perspective: 0.6)
                                .opacity(phase.isIdentity ? 1 : 0.75)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}

struct MoodCard: View {
    let scape: Soundscape

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MeshBackdrop(palette: scape.palette, speed: 1.3)
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: scape.symbol)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular.tint(scape.accent.opacity(0.25)), in: .circle)
                Spacer()
                Text(scape.name).font(.title3.bold())
                Text(scape.subtitle).font(.caption).foregroundStyle(.white.opacity(0.75)).lineLimit(2)
            }
            .foregroundStyle(.white)
            .padding(16)
        }
        .frame(width: 200, height: 260)
        .clipShape(.rect(cornerRadius: 30, style: .continuous))
        .contentShape(.rect(cornerRadius: 30))
    }
}

// MARK: - Row

struct SoundscapeRow: View {
    let scape: Soundscape
    let zoom: Namespace.ID
    @Environment(PlayerModel.self) private var player
    @Environment(AppRouter.self) private var router

    var body: some View {
        let playing = player.current == scape && player.isPlaying

        HStack(spacing: 14) {
            SoundscapeArtwork(scape: scape, cornerRadius: 16, symbolSize: 20)
                .frame(width: 58, height: 58)
                .matchedTransitionSource(id: "row-\(scape.id)", in: zoom)

            VStack(alignment: .leading, spacing: 3) {
                Text(scape.name).font(.headline)
                Text("\(scape.subtitle) · \(scape.minutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            Button {
                withAnimation(.bouncy) { playing ? player.pause() : player.play(scape) }
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(playing ? scape.accent.opacity(0.5) : .clear).interactive(), in: .circle)
            .sensoryFeedback(.impact(weight: .light), trigger: playing)
        }
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .contentShape(.rect(cornerRadius: 24))
        .onTapGesture {
            router.listenPath.append(.init(soundscape: scape, sourceID: "row-\(scape.id)"))
        }
    }
}
