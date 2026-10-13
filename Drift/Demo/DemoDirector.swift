import SwiftUI

/// Drives the UI from launch arguments so CI can capture screenshots and a
/// screen recording without UI tests. Usage: `-DemoScreen <name>`.
enum DemoDirector {
    @MainActor
    static func run(router: AppRouter, player: PlayerModel) async {
        guard let screen = UserDefaults.standard.string(forKey: "DemoScreen") else { return }
        let aurora = Soundscape.all[0]

        func wait(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
        func push(_ s: Soundscape, from source: String) {
            router.listenPath.append(.init(soundscape: s, sourceID: source))
        }

        await wait(0.8)
        switch screen {
        case "listen":
            player.play(Soundscape.all[1]); player.pause()
        case "detail":
            push(aurora, from: "hero")
            await wait(0.8); player.play(aurora)
        case "morph":
            push(aurora, from: "hero")
            await wait(1.0); router.demoExpandTimer = true
        case "nowplaying":
            player.setTimer(30); player.play(Soundscape.all[2])
            await wait(0.6); player.showNowPlaying = true
        case "breathe":
            router.tab = .breathe
            await wait(0.6); router.demoStartBreathing = true
        case "insights":
            router.tab = .insights
        case "search":
            router.demoSearchText = nil
            router.tab = .search
        case "settings":
            router.showSettings = true
        case "tour":
            await tour(router: router, player: player)
        default:
            break
        }
    }

    @MainActor
    private static func tour(router: AppRouter, player: PlayerModel) async {
        func wait(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
        let aurora = Soundscape.all[0]

        await wait(1.5)
        withAnimation(.smooth(duration: 1.6)) { router.listenScroll.scrollTo(y: 520) }
        await wait(2.2)
        withAnimation(.smooth(duration: 1.4)) { router.listenScroll.scrollTo(edge: .top) }
        await wait(1.8)

        router.listenPath.append(.init(soundscape: aurora, sourceID: "hero"))
        await wait(1.6)
        withAnimation(.bouncy) { player.play(aurora) }
        await wait(1.6)
        router.demoExpandTimer = true
        await wait(1.8)
        router.demoExpandTimer = false
        await wait(1.4)
        router.listenPath.removeAll()
        await wait(1.6)

        player.showNowPlaying = true
        await wait(2.5)
        withAnimation(.smooth) { player.step(1) }
        await wait(2.5)
        withAnimation(.smooth) { player.step(1) }
        await wait(2.5)
        player.showNowPlaying = false
        await wait(1.6)

        router.tab = .breathe
        await wait(1.0)
        router.demoStartBreathing = true
        await wait(9)

        router.tab = .insights
        await wait(4)
        router.tab = .search
        await wait(3)
        router.tab = .listen
        await wait(1.0)
        router.showSettings = true
        await wait(3)
        router.showSettings = false
    }
}
