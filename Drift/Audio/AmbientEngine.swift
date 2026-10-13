import AVFoundation

/// Values shared with the real-time render thread. Plain Float stores are
/// effectively atomic on arm64; the render loop smooths every change anyway.
final class NoiseParameters: @unchecked Sendable {
    var brown: Float = 0.6
    var pink: Float = 0.3
    var white: Float = 0.05
    var cutoff: Float = 0.2
    var swellRate: Float = 0.08
    var swellDepth: Float = 0.3
    var crackle: Float = 0
    var gain: Float = 0
}

/// Per-voice DSP state, owned exclusively by the render thread.
private final class RenderState {
    var seed: UInt32 = 0x1234_5678
    var brown: [Float] = [0, 0]
    var pink = [Float](repeating: 0, count: 14)
    var lowpass: [Float] = [0, 0]
    var pop: Float = 0
    var phase: Float = 0
    var gain: Float = 0
    var cutoff: Float = 0.2

    @inline(__always) func white() -> Float {
        seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
        return Float(seed) / Float(UInt32.max) * 2 - 1
    }
}

/// Procedural ambient sound: layered brown / pink / white noise through a
/// soft low-pass, with a slow amplitude swell and optional crackle.
final class AmbientEngine {
    let parameters = NoiseParameters()
    private let engine = AVAudioEngine()
    private var configured = false
    private var stopTask: Task<Void, Never>?

    func apply(_ profile: SoundProfile, layers: [Double]) {
        let body = Float(layers[safe: 0] ?? 0.7)
        let air = Float(layers[safe: 1] ?? 0.5)
        let motion = Float(layers[safe: 2] ?? 0.5)
        let p = parameters
        p.brown = profile.brown * body * 1.4
        p.pink = profile.pink * air * 1.6
        p.white = profile.white * air * 1.6
        p.cutoff = min(0.9, profile.cutoff * (0.6 + air))
        p.swellRate = profile.swellRate
        p.swellDepth = min(0.95, profile.swellDepth * motion * 1.6)
        p.crackle = profile.crackle * motion * 1.6
    }

    func start(volume: Float) {
        stopTask?.cancel()
        do {
            try configureIfNeeded()
            if !engine.isRunning { try engine.start() }
        } catch {
            print("Drift audio unavailable: \(error)")
        }
        parameters.gain = volume
    }

    func setVolume(_ volume: Float) {
        parameters.gain = volume
    }

    /// Fades out, then pauses the engine so it doesn't burn battery.
    func stop() {
        parameters.gain = 0
        stopTask?.cancel()
        stopTask = Task { [engine] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            engine.pause()
        }
    }

    private func configureIfNeeded() throws {
        guard !configured else { return }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let p = parameters
        let s = RenderState()
        let sampleRate: Float = 44_100

        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            let targetCutoff = p.cutoff
            let targetGain = p.gain
            for frame in 0..<Int(frameCount) {
                s.gain += (targetGain - s.gain) * 0.00008
                s.cutoff += (targetCutoff - s.cutoff) * 0.0005

                s.phase += p.swellRate / sampleRate
                if s.phase > 1 { s.phase -= 1 }
                let swell = 1 - p.swellDepth * (0.5 + 0.5 * sinf(2 * .pi * s.phase))

                if p.crackle > 0, (s.white() + 1) * 0.5 < p.crackle * 0.00035 {
                    s.pop = 0.25 + (s.white() + 1) * 0.3
                }
                s.pop *= 0.93

                for ch in 0..<min(2, buffers.count) {
                    let w = s.white()
                    s.brown[ch] = (s.brown[ch] + 0.02 * w) / 1.02
                    let o = ch * 7
                    s.pink[o] = 0.99886 * s.pink[o] + w * 0.0555179
                    s.pink[o + 1] = 0.99332 * s.pink[o + 1] + w * 0.0750759
                    s.pink[o + 2] = 0.96900 * s.pink[o + 2] + w * 0.1538520
                    s.pink[o + 3] = 0.86650 * s.pink[o + 3] + w * 0.3104856
                    s.pink[o + 4] = 0.55000 * s.pink[o + 4] + w * 0.5329522
                    s.pink[o + 5] = -0.7616 * s.pink[o + 5] - w * 0.0168980
                    var pink = w * 0.5362
                    for k in 0..<7 { pink += s.pink[o + k] }
                    pink *= 0.11
                    s.pink[o + 6] = w * 0.115926

                    let mix = p.brown * s.brown[ch] * 3.5 + p.pink * pink + p.white * w
                    s.lowpass[ch] += (mix - s.lowpass[ch]) * s.cutoff
                    let out = (s.lowpass[ch] * swell * 0.6 + s.pop * w * 0.5) * s.gain
                    buffers[ch].mData?.assumingMemoryBound(to: Float.self)[frame] = max(-1, min(1, out))
                }
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.prepare()
        configured = true
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
