import SwiftUI

struct ContentView: View {

    @State private var loggedIn: Bool = restoreSession()
    @State private var currentScreen: Screen = .login

    enum Screen {
        case login
        case signup
        case forgotPassword
    }

    var body: some View {
        Group {
            if loggedIn {
                MainScreen {
                    loggedIn = false
                }
            } else {
                switch currentScreen {
                case .login:
                    LoginScreen(
                        onLoginSuccess: {
                            sessionLoginStatus(status: true)
                            loggedIn = true
                        },
                        onForgotPassword: {
                            currentScreen = .forgotPassword
                        },
                        onSignUp: {
                            currentScreen = .signup
                        }
                    )

                case .signup:
                    SignupScreen {
                        currentScreen = .login
                    }

                case .forgotPassword:
                    ForgotPasswordVerification()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
