import SwiftUI
import MongoSwift
import SwiftBSON

struct LoginScreen: View {

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoggingIn = false
    @State private var errorMessage = ""

    var onLoginSuccess: () -> Void
    var onForgotPassword: () -> Void
    var onSignUp: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text("Log In")
                    .font(.system(size: 20, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(spacing: 10) {
                    Text("Email")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0.7)

                    TextField("example@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                        .autocorrectionDisabled(true)
                }

                VStack(spacing: 10) {
                    Text("Password")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0.7)

                    SecureField("example123", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.system(size: 12))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }

                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if isLoggingIn {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Log In")
                    }
                }
                .padding(10)
                .disabled(
                    email.isEmpty ||
                    password.isEmpty ||
                    isLoggingIn
                )

                Button {
                    onForgotPassword()
                } label: {
                    Text("Forgot Password")
                }

                Button {
                    onSignUp()
                } label: {
                    Text("Create an account")
                }
            }
            .padding(30)
            .frame(width: 350, height: 450, alignment: .topLeading)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .frame(width: 800, height: 600)
    }

    func login() async {
        isLoggingIn = true
        errorMessage = ""

        do {
            let cursor = try await users.find([
                "email": BSON.string(email)
            ])

            var matchedUser: User? = nil

            for try await user in cursor {
                matchedUser = user
                break
            }

            guard let user = matchedUser else {
                errorMessage = "Invalid email or password"
                isLoggingIn = false
                return
            }

            let isValid = PasswordHasher.verify(
                password: password,
                storedHashBase64: user.password,
                storedSaltBase64: user.salt
            )

            if isValid {
                currentUserID = user.id
                currentUsername = user.username

                sessionLoginStatus(status: true)

                email = ""
                password = ""

                onLoginSuccess()
            } else {
                errorMessage = "Invalid email or password"
            }

        } catch {
            print("Login error: \(error)")
            print("Login error debug: \(String(reflecting: error))")
            errorMessage = "\(error)"
        }

        isLoggingIn = false
    }
}

#Preview {
    LoginScreen(
        onLoginSuccess: {},
        onForgotPassword: {},
        onSignUp: {}
    )
}
