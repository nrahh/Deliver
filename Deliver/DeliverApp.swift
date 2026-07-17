import SwiftUI
import FirebaseCore

@main
struct DeliverApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
