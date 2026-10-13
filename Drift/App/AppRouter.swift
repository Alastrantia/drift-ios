import SwiftUI

enum AppTab: Hashable {
    case listen, breathe, insights, search
}

/// A navigation destination that remembers which card it was opened from,
/// so the zoom transition can grow out of (and shrink back into) that exact view.
struct SoundscapeRoute: Hashable {
    let soundscape: Soundscape
    let sourceID: String
}

@Observable
final class AppRouter {
    var tab: AppTab = .listen
    var listenPath: [SoundscapeRoute] = []
    var showSettings = false
    var listenScroll = ScrollPosition(edge: .top)

    // Hooks used by the scripted demo / screenshot mode.
    var demoExpandTimer = false
    var demoStartBreathing = false
    var demoSearchText: String? = nil
}
