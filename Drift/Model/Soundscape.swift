import SwiftUI

/// Parameters for the procedural noise synthesiser.
struct SoundProfile: Hashable {
    var brown: Float      // deep rumble
    var pink: Float       // balanced hiss
    var white: Float      // bright air
    var cutoff: Float     // one-pole low-pass coefficient (0...1)
    var swellRate: Float  // Hz of the slow amplitude "breathing"
    var swellDepth: Float // 0...1
    var crackle: Float    // density of little pops (fire, rain drops)
}

struct Soundscape: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let blurb: String
    let symbol: String
    let tags: [String]
    let palette: [Color]   // 9 colours for a 3x3 mesh gradient
    let accent: Color
    let layers: [String]   // three mixer layers
    let profile: SoundProfile
    let minutes: Int

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (a: Soundscape, b: Soundscape) -> Bool { a.id == b.id }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

private func mesh(_ hexes: UInt32...) -> [Color] { hexes.map(Color.init(hex:)) }

extension Soundscape {
    static let all: [Soundscape] = [
        Soundscape(
            id: "aurora", name: "Aurora", subtitle: "Arctic night, slow light",
            blurb: "A low polar wind beneath ribbons of green and violet. Long, unhurried swells that settle the mind before sleep.",
            symbol: "sparkles", tags: ["Sleep", "Night", "Wind"],
            palette: mesh(0x050B2A, 0x0B1E4A, 0x1B0F3F,
                          0x0F6E6A, 0x2BC59A, 0x5B3FB5,
                          0x07142E, 0x1A8C7A, 0x2A1458),
            accent: Color(hex: 0x3DDBA8),
            layers: ["Polar wind", "Shimmer", "Swell"],
            profile: .init(brown: 0.8, pink: 0.25, white: 0.02, cutoff: 0.12, swellRate: 0.06, swellDepth: 0.45, crackle: 0),
            minutes: 45),
        Soundscape(
            id: "tide", name: "Tide", subtitle: "Waves on a pebble shore",
            blurb: "Breakers roll in, draw back over the stones, and roll in again. Steady as breathing.",
            symbol: "water.waves", tags: ["Focus", "Ocean", "Sleep"],
            palette: mesh(0x021A3A, 0x05345F, 0x0A2350,
                          0x0F6FA8, 0x45C1E0, 0x1C5E9C,
                          0x04274A, 0x2A9BC4, 0x0B3A66),
            accent: Color(hex: 0x5AD2F4),
            layers: ["Deep water", "Foam", "Waves"],
            profile: .init(brown: 0.6, pink: 0.55, white: 0.06, cutoff: 0.22, swellRate: 0.09, swellDepth: 0.8, crackle: 0),
            minutes: 30),
        Soundscape(
            id: "ember", name: "Ember", subtitle: "A fire burning low",
            blurb: "Glowing logs, a soft roar and the occasional crackle. Warmth you can hear.",
            symbol: "flame", tags: ["Cozy", "Night"],
            palette: mesh(0x1A0503, 0x3D0C06, 0x220604,
                          0x8A2410, 0xF07A2A, 0xB33A12,
                          0x2B0805, 0xC9531B, 0x4A1006),
            accent: Color(hex: 0xFF8A3D),
            layers: ["Roar", "Hiss", "Crackle"],
            profile: .init(brown: 0.7, pink: 0.2, white: 0.03, cutoff: 0.1, swellRate: 0.15, swellDepth: 0.2, crackle: 0.6),
            minutes: 60),
        Soundscape(
            id: "rain", name: "Rainfall", subtitle: "Rain on a tin roof",
            blurb: "A dense, even rain with drops tapping overhead. The classic way to quiet a busy room.",
            symbol: "cloud.rain", tags: ["Focus", "Rain", "Sleep"],
            palette: mesh(0x0C1220, 0x1B2540, 0x101828,
                          0x2E3F66, 0x6A82B5, 0x34466F,
                          0x111A2C, 0x45598A, 0x1A2338),
            accent: Color(hex: 0x8FA8E0),
            layers: ["Downpour", "Mist", "Drops"],
            profile: .init(brown: 0.3, pink: 0.7, white: 0.25, cutoff: 0.45, swellRate: 0.05, swellDepth: 0.1, crackle: 0.9),
            minutes: 45),
        Soundscape(
            id: "canopy", name: "Canopy", subtitle: "Leaves in a summer breeze",
            blurb: "Wind moving through tall beech trees, rising and falling in gentle gusts.",
            symbol: "leaf", tags: ["Focus", "Nature", "Wind"],
            palette: mesh(0x06170C, 0x0F3318, 0x0A2010,
                          0x2C6B2F, 0x8BCB5A, 0x3E8A3A,
                          0x0B2412, 0x5DA544, 0x143A1A),
            accent: Color(hex: 0x9BE06A),
            layers: ["Trunk", "Leaves", "Gusts"],
            profile: .init(brown: 0.45, pink: 0.6, white: 0.08, cutoff: 0.3, swellRate: 0.11, swellDepth: 0.55, crackle: 0.05),
            minutes: 30),
        Soundscape(
            id: "dune", name: "Dune", subtitle: "Desert wind at dusk",
            blurb: "Warm air sliding over sand ridges as the sky turns rose and lilac.",
            symbol: "sun.horizon", tags: ["Calm", "Wind"],
            palette: mesh(0x2A1030, 0x5A2350, 0x3A1440,
                          0xC2577A, 0xF6B08A, 0xA0508E,
                          0x40163E, 0xE08A86, 0x6A2A5E),
            accent: Color(hex: 0xFFB59A),
            layers: ["Ground", "Sand", "Gusts"],
            profile: .init(brown: 0.5, pink: 0.45, white: 0.1, cutoff: 0.2, swellRate: 0.07, swellDepth: 0.6, crackle: 0.02),
            minutes: 20),
        Soundscape(
            id: "nebula", name: "Nebula", subtitle: "Deep-space drone",
            blurb: "A vast, slowly shifting hum. No events, no surprises — just space.",
            symbol: "moon.stars", tags: ["Sleep", "Calm", "Night"],
            palette: mesh(0x0A0420, 0x1E0B45, 0x120630,
                          0x5A1E8C, 0xD0509E, 0x3A1A7A,
                          0x0E0628, 0x8A2F9A, 0x1A0A40),
            accent: Color(hex: 0xE06FC0),
            layers: ["Hum", "Dust", "Drift"],
            profile: .init(brown: 1.0, pink: 0.1, white: 0.0, cutoff: 0.06, swellRate: 0.03, swellDepth: 0.35, crackle: 0),
            minutes: 90),
        Soundscape(
            id: "snow", name: "First Snow", subtitle: "Hush of a winter forest",
            blurb: "The muffled stillness after snowfall, with a faint wind high in the pines.",
            symbol: "snowflake", tags: ["Calm", "Nature", "Sleep"],
            palette: mesh(0x1A2433, 0x3A4C66, 0x223044,
                          0x7F9BBF, 0xDCE8F5, 0x8AA6C8,
                          0x26354A, 0xB4C8E0, 0x3E5270),
            accent: Color(hex: 0xCFE3FA),
            layers: ["Stillness", "Air", "Pines"],
            profile: .init(brown: 0.55, pink: 0.35, white: 0.04, cutoff: 0.15, swellRate: 0.04, swellDepth: 0.3, crackle: 0),
            minutes: 40),
    ]

    static let featured = all[0]
    static let allTags = ["Sleep", "Focus", "Calm", "Night", "Nature", "Wind", "Rain", "Ocean", "Cozy"]
}
