import SwiftUI

struct Profile: View {
    var onLogout: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Profile")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Text(currentUsername)
                .font(.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button {
                logout()
            } label: {
                Text("Log Out")
                    .frame(maxWidth: .infinity)
                    .padding(10)
            }
            .buttonStyle(.plain)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(20)
        .frame(width: 300, height: 400)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }

    private func logout() {
        currentUserID = ""
        currentUsername = ""
        sessionLoginStatus(status: false)
        onLogout()
    }
}

#Preview {
    Profile(onLogout: {})
}
