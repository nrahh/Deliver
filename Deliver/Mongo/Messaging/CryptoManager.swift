//
//  CryptoManager.swift
//  Deliver
//
//  Created by asd on 7/17/26.
//

import Foundation
import CryptoKit
import Security

struct CryptoManager {
    static func generateKeyPair() -> (privateKey: Curve25519.KeyAgreement.PrivateKey, publicKey: Curve25519.KeyAgreement.PublicKey) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }

    static func savePrivateKey(_ key: Curve25519.KeyAgreement.PrivateKey, forUser userID: String) {
        let data = key.rawRepresentation
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "privatekey_\(userID)",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadPrivateKey(forUser userID: String) -> Curve25519.KeyAgreement.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "privatekey_\(userID)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }

    static func sharedKey(
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        publicKeyData: Data
    ) -> SymmetricKey? {
        guard let publicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKeyData) else {
            return nil
        }
        guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: publicKey) else {
            return nil
        }
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "DeliverMessagingSalt".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }

    static func encrypt(text: String, key: SymmetricKey) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard let sealedBox = try? AES.GCM.seal(data, using: key) else { return nil }
        guard let combined = sealedBox.combined else { return nil }
        return combined.base64EncodedString()
    }

    static func decrypt(base64: String, key: SymmetricKey) -> String? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        guard let sealedBox = try? AES.GCM.SealedBox(combined: data) else { return nil }
        guard let decrypted = try? AES.GCM.open(sealedBox, using: key) else { return nil }
        return String(data: decrypted, encoding: .utf8)
    }
}
