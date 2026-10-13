import SwiftUI

@Observable
final class PlayerModel {
    private(set) var current: Soundscape = .featured
    private(set) var isPlaying = false
    var showNowPlaying = false
    var favorites: Set<String> = ["aurora", "rain"]

    var volume: Double = 0.7 {
        didSet { if isPlaying { engine.setVolume(Float(volume)) } }
    }

    /// Mixer levels for each soundscape's three layers.
    private(set) var levels: [String: [Double]] = [:]

    /// Sleep timer.
    private(set) var timerMinutes: Int? = nil
    private(set) var remaining: TimeInterval = 0
    private var ticker: Task<Void, Never>?

    @ObservationIgnored private let engine = AmbientEngine()

    func levels(for scape: Soundscape) -> [Double] {
        levels[scape.id] ?? [0.7, 0.5, 0.5]
    }

    func setLevel(_ value: Double, layer: Int, for scape: Soundscape) {
        var l = levels(for: scape)
        l[layer] = value
        levels[scape.id] = l
        if scape == current { engine.apply(scape.profile, layers: l) }
    }

    func play(_ scape: Soundscape) {
        current = scape
        engine.apply(scape.profile, layers: levels(for: scape))
        engine.start(volume: Float(volume))
        isPlaying = true
        if let m = timerMinutes, remaining <= 0 { remaining = TimeInterval(m * 60) }
    }

    func toggle() {
        isPlaying ? pause() : play(current)
    }

    func pause() {
        engine.stop()
        isPlaying = false
    }

    func step(_ delta: Int) {
        let all = Soundscape.all
        let i = all.firstIndex(of: current) ?? 0
        let next = all[(i + delta + all.count) % all.count]
        if isPlaying { play(next) } else { current = next }
    }

    func setTimer(_ minutes: Int?) {
        timerMinutes = minutes
        ticker?.cancel()
        guard let minutes else { remaining = 0; return }
        remaining = TimeInterval(minutes * 60)
        ticker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.isPlaying else { continue }
                self.remaining = max(0, self.remaining - 1)
                if self.remaining == 0 {
                    self.pause()
                    self.timerMinutes = nil
                    return
                }
            }
        }
    }

    var timerProgress: Double {
        guard let m = timerMinutes, m > 0 else { return 0 }
        return 1 - remaining / Double(m * 60)
    }
}

extension TimeInterval {
    var clock: String {
        let s = Int(self)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
