import SwiftUI

struct MiniPlayer: View {
    let namespace: Namespace.ID
    @Environment(PlayerModel.self) private var player
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        let scape = player.current

        HStack(spacing: 12) {
            SoundscapeArtwork(scape: scape, cornerRadius: 9, symbolSize: 13, animated: player.isPlaying)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 0) {
                Text(scape.name)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.interpolate)
                if placement != .inline {
                    Text(player.isPlaying ? statusLine : "Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .lineLimit(1)

            Spacer(minLength: 0)

            Button {
                withAnimation(.bouncy) { player.toggle() }
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .font(.title3)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            if placement != .inline {
                Button {
                    withAnimation(.smooth) { player.step(1) }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.body)
                        .frame(width: 32, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .contentShape(.rect)
        .onTapGesture { player.showNowPlaying = true }
        .matchedTransitionSource(id: "mini-player", in: namespace)
        .animation(.smooth, value: scape)
    }

    private var statusLine: String {
        if player.timerMinutes != nil { return "Sleep in \(player.remaining.clock)" }
        return player.current.subtitle
    }
}
