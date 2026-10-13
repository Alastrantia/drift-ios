import SwiftUI

struct SearchView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(AppRouter.self) private var router
    @State private var query = ""
    @State private var selectedTags: Set<String> = []
    @State private var path: [SoundscapeRoute] = []
    @Namespace private var zoom
    @Namespace private var chips

    private var results: [Soundscape] {
        Soundscape.all.filter { s in
            (query.isEmpty || s.name.localizedCaseInsensitiveContains(query) || s.subtitle.localizedCaseInsensitiveContains(query)
             || s.tags.contains { $0.localizedCaseInsensitiveContains(query) })
            && (selectedTags.isEmpty || !selectedTags.isDisjoint(with: s.tags))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tagBar

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(results) { scape in
                            SearchTile(scape: scape)
                                .matchedTransitionSource(id: scape.id, in: zoom)
                                .onTapGesture { path.append(.init(soundscape: scape, sourceID: scape.id)) }
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .animation(.spring(duration: 0.45, bounce: 0.25), value: results.map(\.id))

                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .padding(.top, 40)
                    }
                }
                .padding(.bottom, 40)
            }
            .background { AmbientPageBackground(scape: player.current) }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Rain, ocean, sleep…")
            .navigationDestination(for: SoundscapeRoute.self) { route in
                SoundscapeDetailView(scape: route.soundscape)
                    .navigationTransition(.zoom(sourceID: route.sourceID, in: zoom))
            }
        }
        .onAppear { if let text = router.demoSearchText { query = text } }
    }

    private var tagBar: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(Soundscape.allTags, id: \.self) { tag in
                        let on = selectedTags.contains(tag)
                        Button {
                            withAnimation(.bouncy(duration: 0.4)) {
                                if on { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if on { Image(systemName: "checkmark").transition(.scale.combined(with: .opacity)) }
                                Text(tag)
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(on ? .regular.tint(.teal.opacity(0.6)).interactive() : .regular.interactive(), in: .capsule)
                        .glassEffectID(tag, in: chips)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selectedTags)
    }
}

private struct SearchTile: View {
    let scape: Soundscape

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MeshBackdrop(palette: scape.palette, speed: 0.9)
            Image(systemName: scape.symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(scape.name).font(.headline)
                Text("\(scape.minutes) min").font(.caption).foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .padding(8)
        }
        .frame(height: 190)
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .contentShape(.rect(cornerRadius: 26))
    }
}
