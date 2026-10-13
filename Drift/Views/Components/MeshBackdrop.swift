import SwiftUI

/// A slowly drifting 3x3 mesh gradient. The motion is deliberately gentle —
/// the inner control points wander a few percent on incommensurate sine waves.
struct MeshBackdrop: View {
    let palette: [Color]
    var speed: Double = 1
    var amplitude: Float = 0.14
    var animated = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !animated)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * speed
            MeshGradient(width: 3, height: 3, points: points(at: t), colors: palette)
        }
    }

    private func points(at t: Double) -> [SIMD2<Float>] {
        func w(_ phase: Double, _ freq: Double) -> Float {
            Float(sin(t * freq + phase)) * amplitude
        }
        return [
            [0, 0], [0.5 + w(0.0, 0.31), 0], [1, 0],
            [0, 0.5 + w(1.0, 0.27)], [0.5 + w(2.0, 0.23), 0.5 + w(3.0, 0.29)], [1, 0.5 + w(4.0, 0.33)],
            [0, 1], [0.5 + w(5.0, 0.25), 1], [1, 1],
        ]
    }
}

/// Square-ish artwork for a soundscape: mesh + glyph.
struct SoundscapeArtwork: View {
    let scape: Soundscape
    var cornerRadius: CGFloat = 20
    var symbolSize: CGFloat = 22
    var animated = true

    var body: some View {
        MeshBackdrop(palette: scape.palette, animated: animated)
            .overlay {
                Image(systemName: scape.symbol)
                    .font(.system(size: symbolSize, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Small Liquid Glass capsule label.
struct GlassChip: View {
    let title: String
    var symbol: String? = nil
    var tint: Color? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let symbol { Image(systemName: symbol) }
            Text(title)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect(tint.map { Glass.regular.tint($0.opacity(0.35)) } ?? Glass.regular, in: .capsule)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title2.bold())
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}
