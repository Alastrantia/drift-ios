import SwiftUI

@main
struct DriftApp: App {
    @State private var player = PlayerModel()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(player)
                .environment(router)
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
                .task { await DemoDirector.run(router: router, player: player) }
        }
    }
}
