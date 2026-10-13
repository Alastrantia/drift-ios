import SwiftUI

struct RootView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(AppRouter.self) private var router
    @Namespace private var playerNamespace

    var body: some View {
        @Bindable var router = router
        @Bindable var player = player

        TabView(selection: $router.tab) {
            Tab("Listen", systemImage: "waveform", value: AppTab.listen) {
                ListenView()
            }
            Tab("Breathe", systemImage: "wind", value: AppTab.breathe) {
                BreatheView()
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: AppTab.insights) {
                InsightsView()
            }
            Tab(value: AppTab.search, role: .search) {
                SearchView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            MiniPlayer(namespace: playerNamespace)
        }
        .fullScreenCover(isPresented: $player.showNowPlaying) {
            NowPlayingView()
                .navigationTransition(.zoom(sourceID: "mini-player", in: playerNamespace))
        }
        .sensoryFeedback(.selection, trigger: router.tab)
    }
}
