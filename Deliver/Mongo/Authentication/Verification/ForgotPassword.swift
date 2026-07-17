import Foundation
import MongoSwift
import SwiftBSON

let resendAPIKey = "re_R8x2zQii_7DkzPa35DE7TdBCqthjmfYXm"

var verificationCode = ""
var verificationEmail = ""

func generateVerificationCode() {
    verificationCode = String(Int.random(in: 100000...999999))
}

func sendVerificationEmail(to email: String) async throws {
    generateVerificationCode()
    verificationEmail = email

    let url = URL(string: "https://api.resend.com/emails")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(resendAPIKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "from": "Deliver <onboarding@resend.dev>",
        "to": [email],
        "subject": "Your Deliver Password Reset Code",
        "html": """
        <h2>Password Reset</h2>
        <p>Your verification code is:</p>
        <h1>\(verificationCode)</h1>
        <p>If this email was send to you randomly please ignore it or delete it. In addition, please do not share this email with others.</p>
        """
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(
            domain: "Resend",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid response from Resend"
            ]
        )
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        let responseText = String(data: data, encoding: .utf8) ?? "Unknown error"

        throw NSError(
            domain: "Resend",
            code: httpResponse.statusCode,
            userInfo: [
                NSLocalizedDescriptionKey: responseText
            ]
        )
    }
}

func resetPassword(
    email: String,
    newPassword: String
) async throws {
    let cursor = try await users.find([
        "email": BSON.string(email)
    ])

    var matchedUser: User?

    for try await user in cursor {
        matchedUser = user
        break
    }

    guard let user = matchedUser else {
        throw NSError(
            domain: "PasswordReset",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "Account not found"
            ]
        )
    }

    let salt = PasswordHasher.generateSalt()

    guard let hashedPassword = PasswordHasher.hashPassword(
        newPassword,
        salt: salt
    ) else {
        throw NSError(
            domain: "PasswordReset",
            code: 2,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to hash password"
            ]
        )
    }

    try await users.updateOne(
        filter: [
            "id": BSON.string(user.id)
        ],
        update: [
            "$set": [
                "password": BSON.string(hashedPassword.base64EncodedString()),
                "salt": BSON.string(salt.base64EncodedString())
            ]
        ]
    )
}
