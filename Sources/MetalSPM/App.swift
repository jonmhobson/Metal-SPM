import SwiftUI

@main
struct MetalSPMApp: App {
    init() {
        Task { @MainActor in
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
