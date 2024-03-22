import SwiftUI

@main
struct MySpatialTimerApp: App {

    @State private var appState = AppState()
    @State private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(appState: appState, timerManager: timerManager)
        }
    }
}
