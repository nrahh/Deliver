import Foundation
import CommonCrypto
import Security
import CryptoKit
import MongoSwift
import SwiftBSON

struct PasswordHasher {
    static func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    static func hashPassword(_ password: String, salt: Data) -> Data? {
        let keyLength = 32
        var derivedKey = [UInt8](repeating: 0, count: keyLength)

        let status = salt.withUnsafeBytes { saltBytes in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                password,
                password.utf8.count,
                saltBytes.bindMemory(to: UInt8.self).baseAddress,
                salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                100_000,
                &derivedKey,
                keyLength
            )
        }

        guard status == kCCSuccess else {
            return nil
        }

        return Data(derivedKey)
    }

    static func verify(password: String, storedHashBase64: String, storedSaltBase64: String) -> Bool {
        guard
            let saltData = Data(base64Encoded: storedSaltBase64),
            let storedHash = Data(base64Encoded: storedHashBase64),
            let candidateHash = hashPassword(password, salt: saltData)
        else {
            return false
        }
        return candidateHash == storedHash
    }
}

func createUser(
    username: String,
    email: String,
    password: String,
    pfp: String = "",
    isAdmin: Bool = false
) async throws {
    let salt = PasswordHasher.generateSalt()

    guard let hashedPassword = PasswordHasher.hashPassword(
        password,
        salt: salt
    ) else {
        throw NSError(
            domain: "PasswordHashing",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to hash password"
            ]
        )
    }

    let userID = UUID().uuidString
    let keyPair = CryptoManager.generateKeyPair()
    CryptoManager.savePrivateKey(keyPair.privateKey, forUser: userID)
    let publicKeyString = keyPair.publicKey.rawRepresentation.base64EncodedString()

    let user = User(
        id: userID,
        username: username,
        email: email,
        password: hashedPassword.base64EncodedString(),
        salt: salt.base64EncodedString(),
        pfp: pfp,
        isAdmin: isAdmin,
        creationDate: Date(),
        publicKey: publicKeyString
    )

    try await users.insertOne(user)
}
