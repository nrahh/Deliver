import SwiftUI
import MongoSwift
import SwiftBSON

struct ForgotPasswordVerification: View {
    @State private var email = ""
    @State private var enteredCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false
    @State private var codeSent = false

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                Text("Reset Your Password")
                    .font(.largeTitle)

                TextField("Enter Email...", text: $email)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        await sendCode()
                    }
                } label: {
                    if isLoading && !codeSent {
                        ProgressView()
                    } else {
                        Text("Send Code")
                    }
                }
                .disabled(email.isEmpty || isLoading)

                if codeSent {
                    TextField("Enter Verification Code...", text: $enteredCode)
                        .textFieldStyle(.roundedBorder)

                    SecureField("New Password", text: $newPassword)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Change Password")
                        }
                    }
                    .disabled(
                        enteredCode.isEmpty ||
                        newPassword.isEmpty ||
                        confirmPassword.isEmpty ||
                        isLoading
                    )
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            .padding(30)
            .frame(width: 350)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .frame(width: 800, height: 600)
    }

    private func sendCode() async {
        errorMessage = ""
        successMessage = ""

        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        isLoading = true

        do {
            let cursor = try await users.find([
                "email": BSON.string(normalizedEmail)
            ])

            var accountExists = false

            for try await _ in cursor {
                accountExists = true
                break
            }

            guard accountExists else {
                errorMessage = "No account exists with this email"
                isLoading = false
                return
            }

            try await sendVerificationEmail(to: normalizedEmail)

            email = normalizedEmail
            codeSent = true
            successMessage = "Verification code sent to your email"
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func changePassword() async {
        errorMessage = ""
        successMessage = ""

        guard enteredCode == verificationCode else {
            errorMessage = "Invalid verification code"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        isLoading = true

        do {
            try await resetPassword(
                email: email,
                newPassword: newPassword
            )

            successMessage = "Password changed successfully"

            email = ""
            enteredCode = ""
            newPassword = ""
            confirmPassword = ""
            codeSent = false
            verificationCode = ""
            verificationEmail = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ForgotPasswordVerification()
}
