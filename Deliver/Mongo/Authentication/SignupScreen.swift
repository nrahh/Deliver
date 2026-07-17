import SwiftUI

struct SignupScreen: View {
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isCreatingAccount = false
    @State private var errorMessage = ""
    
    var onLogin: () -> Void
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.system(size: 20, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                VStack(spacing: 10) {
                    Text("Username")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0.7)
                    
                    TextField("example", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                        .autocorrectionDisabled(true)
                }
                
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
                        await signup()
                    }
                } label: {
                    if isCreatingAccount {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Sign Up")
                    }
                }
                .padding(10)
                .disabled(
                    username.isEmpty ||
                    email.isEmpty ||
                    password.isEmpty ||
                    isCreatingAccount
                )
                
                Button {
                    onLogin()
                } label: {
                    Text("Already have an account? Log In")
                }
            }
            .padding(30)
            .frame(width: 350, height: 450, alignment: .topLeading)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .frame(width: 800, height: 600)
    }
    
    func signup() async {
        isCreatingAccount = true
        errorMessage = ""
        
        do {
            try await createUser(
                username: username,
                email: email,
                password: password
            )
            
            print("User created successfully")
            
            username = ""
            email = ""
            password = ""
            
        } catch {
            print("Signup error: \(error)")
            print("Signup error debug: \(String(reflecting: error))")
            errorMessage = "\(error)"
        }
        
        isCreatingAccount = false
    }
}

#Preview {
    SignupScreen {
        print("Login")
    }
}
