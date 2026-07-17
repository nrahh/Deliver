import SwiftUI

struct MainScreen: View {
    @State private var selectedPage: Page = .chats

    var onLogout: () -> Void

    enum Page: Hashable {
        case chats
        case settings
        case profile
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPage) {
                Label("Chats", systemImage: "message")
                    .tag(Page.chats)

                Label("Profile", systemImage: "person")
                    .tag(Page.profile)

                Label("Settings", systemImage: "gear")
                    .tag(Page.settings)
            }
            .navigationTitle("Deliver")
        } detail: {
            switch selectedPage {
            case .chats:
                Chats()

            case .profile:
                Profile(onLogout: onLogout)

            case .settings:
                Text("Settings")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    MainScreen(onLogout: {})
}
